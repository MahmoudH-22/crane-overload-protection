/**
 * @file crane_nodemcu.ino
 * @brief Crane overload protection: NodeMCU ESP8266 Wi-Fi + MQTT bridge.
 *
 * The NodeMCU makes no safety decisions. It:
 *   - forwards Uno telemetry lines (D,...) to MQTT topic crane/live as JSON (retained),
 *   - publishes alarms and rejected commands to crane/events,
 *   - forwards app commands from crane/cmd to the Uno as C,... lines,
 *   - sends a heartbeat H to the Uno every second while MQTT is connected,
 *   - keeps crane/status = "online" / "offline" (Last Will, retained).
 *
 * Board: "NodeMCU 1.0 (ESP-12E Module)" (esp8266 core 3.x)
 * Libraries: PubSubClient (Nick O'Leary), ArduinoJson 7 (Benoit Blanchon).
 */
#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <SoftwareSerial.h>
#include <ArduinoJson.h>

// ============================================================ settings (edit these)
const char* WIFI_SSID = "CraneHotspot";
const char* WIFI_PASS = "change-me";
const char* MQTT_HOST = "192.168.43.10";  // laptop running Mosquitto
const uint16_t MQTT_PORT = 1883;

const char* T_LIVE   = "crane/live";
const char* T_CMD    = "crane/cmd";
const char* T_STATUS = "crane/status";
const char* T_EVENTS = "crane/events";

const uint16_t HEARTBEAT_MS = 1000;
const uint16_t RETRY_MS = 3000;
#define DEBUG 1   // print link traffic to USB serial (115200)

// ============================================================ globals
SoftwareSerial uno(D5, D6);   // RX = D5 (from Uno D11 via divider), TX = D6 (to Uno D10)
WiFiClient net;
PubSubClient mqtt(net);

char lineBuf[80];
uint8_t lineLen = 0;
char lastState[12] = "";
uint32_t tHeartbeat = 0, tRetry = 0, goodLines = 0, badLines = 0;

// ============================================================ helpers
/**
 * XOR checksum of a character range (same algorithm as the Uno).
 * @param s Text.
 * @param n Number of characters.
 * @return 8-bit checksum.
 */
uint8_t xorSum(const char* s, size_t n) {
  uint8_t c = 0;
  for (size_t i = 0; i < n; i++) c ^= (uint8_t)s[i];
  return c;
}

/**
 * Sends one checksummed line to the Uno.
 * @param body Line content without the checksum, e.g. "C,UP".
 * @return void
 */
void sendToUno(const char* body) {
  char out[64];
  snprintf(out, sizeof out, "%s*%02X\n", body, xorSum(body, strlen(body)));
  uno.print(out);
#if DEBUG
  Serial.print(F("-> uno ")); Serial.print(out);
#endif
}

/**
 * Verifies and strips the "*XX" checksum from a line received from the Uno.
 * @param line Null-terminated line; the checksum is removed in place.
 * @return true when the checksum matches.
 */
bool checkLine(char* line) {
  char* star = strrchr(line, '*');
  if (!star || strlen(star) != 3) return false;
  uint8_t want = (uint8_t)strtoul(star + 1, nullptr, 16);
  *star = '\0';
  return xorSum(line, strlen(line)) == want;
}

/**
 * Tells whether a state name is one the app should be alerted about.
 * @param st State name from the Uno.
 * @return true for OVERLOAD, JAM, E_STOP and AT_TOP.
 */
bool isEventState(const char* st) {
  return !strcmp(st, "OVERLOAD") || !strcmp(st, "JAM") || !strcmp(st, "E_STOP") || !strcmp(st, "AT_TOP");
}

// ============================================================ Uno -> MQTT
/**
 * Converts a D line into JSON on crane/live, and publishes a crane/events
 * message when the state changes into an alarm or the top.
 * @param line Verified line without checksum: D,kg,amps,top,state,max,flags,height
 * @return void
 */
void handleData(char* line) {
  strtok(line, ",");
  char* kg = strtok(nullptr, ",");
  char* amps = strtok(nullptr, ",");
  char* top = strtok(nullptr, ",");
  char* st = strtok(nullptr, ",");
  char* mx = strtok(nullptr, ",");
  char* fl = strtok(nullptr, ",");
  char* hg = strtok(nullptr, ",");   // hook height in mm, -1 until homed
  if (!kg || !amps || !top || !st || !mx || !fl) return;
  int flags = atoi(fl);
  bool homed = (flags & 4) && hg;

  char json[256];
  snprintf(json, sizeof json,
           "{\"kg\":%s,\"amps\":%s,\"top\":%s,\"state\":\"%s\",\"max\":%s,\"near\":%s,\"linkLost\":%s,"
           "\"homed\":%s,\"height\":%s,\"encErr\":%s}",
           kg, amps, top[0] == '1' ? "true" : "false", st, mx,
           (flags & 1) ? "true" : "false", (flags & 2) ? "true" : "false",
           homed ? "true" : "false", homed ? hg : "null", (flags & 8) ? "true" : "false");
  if (mqtt.connected()) mqtt.publish(T_LIVE, json, true);

  if (strcmp(st, lastState) != 0) {
    if (isEventState(st) && mqtt.connected()) {
      char ev[96];
      snprintf(ev, sizeof ev, "{\"type\":\"%s\",\"kg\":%s,\"amps\":%s}", st, kg, amps);
      mqtt.publish(T_EVENTS, ev);
    }
    strncpy(lastState, st, sizeof lastState - 1);
    lastState[sizeof lastState - 1] = '\0';
  }
}

/**
 * Publishes a rejected-command reason (E line) to crane/events.
 * @param line Verified line without checksum: E,reason
 * @return void
 */
void handleReject(char* line) {
  char* reason = strchr(line, ',');
  if (!reason || !mqtt.connected()) return;
  char ev[80];
  snprintf(ev, sizeof ev, "{\"type\":\"REJECTED\",\"reason\":\"%s\"}", reason + 1);
  mqtt.publish(T_EVENTS, ev);
}

/**
 * Reads characters from the Uno and dispatches complete, verified lines.
 * @return void
 */
void readUno() {
  while (uno.available()) {
    char c = uno.read();
    if (c == '\n') {
      lineBuf[lineLen] = '\0';
      if (lineLen && checkLine(lineBuf)) {
        goodLines++;
#if DEBUG
        Serial.print(F("<- uno ")); Serial.println(lineBuf);
#endif
        if (lineBuf[0] == 'D') handleData(lineBuf);
        else if (lineBuf[0] == 'E') handleReject(lineBuf);
      } else if (lineLen) {
        badLines++;
      }
      lineLen = 0;
    } else if (c != '\r' && lineLen < sizeof(lineBuf) - 1) {
      lineBuf[lineLen++] = c;
    }
  }
}

// ============================================================ MQTT -> Uno
/**
 * Handles a crane/cmd message: {"cmd":"UP"} or {"cmd":"MAX","value":2.0}.
 * Only known commands are forwarded.
 * @param topic Topic name.
 * @param payload Message bytes.
 * @param len Payload length.
 * @return void
 */
void onMqtt(char* topic, byte* payload, unsigned int len) {
  JsonDocument doc;
  if (deserializeJson(doc, payload, len)) return;
  const char* cmd = doc["cmd"] | "";
  char body[40];
  if (!strcmp(cmd, "UP") || !strcmp(cmd, "DOWN") || !strcmp(cmd, "STOP") ||
      !strcmp(cmd, "RESET") || !strcmp(cmd, "TARE")) {
    snprintf(body, sizeof body, "C,%s", cmd);
  } else if ((!strcmp(cmd, "MAX") || !strcmp(cmd, "CAL")) && doc["value"].is<float>()) {
    snprintf(body, sizeof body, "C,%s,%.3f", cmd, doc["value"].as<float>());
  } else {
    return;
  }
  sendToUno(body);
}

/**
 * Connects to the broker when disconnected (non-blocking retry every 3 s).
 * Sets the Last Will so the app sees "offline" if the NodeMCU drops.
 * @return void
 */
void ensureMqtt() {
  if (mqtt.connected() || WiFi.status() != WL_CONNECTED) return;
  if (millis() - tRetry < RETRY_MS) return;
  tRetry = millis();
  char id[24];
  snprintf(id, sizeof id, "crane-%06X", ESP.getChipId());
  if (mqtt.connect(id, nullptr, nullptr, T_STATUS, 1, true, "offline")) {
    mqtt.publish(T_STATUS, "online", true);
    mqtt.subscribe(T_CMD, 1);
#if DEBUG
    Serial.println(F("MQTT connected"));
#endif
  }
}

// ============================================================ main
/**
 * Starts serial ports, Wi-Fi and the MQTT client.
 * @return void
 */
void setup() {
  Serial.begin(115200);
  uno.begin(9600);
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  mqtt.setServer(MQTT_HOST, MQTT_PORT);
  mqtt.setCallback(onMqtt);
  mqtt.setBufferSize(512);
  mqtt.setKeepAlive(15);
  Serial.println(F("crane_nodemcu ready"));
}

/**
 * Keeps the connections alive, moves data both ways and sends the heartbeat.
 * The heartbeat only flows while MQTT is connected, so the Uno stops the
 * motor if the app link is lost.
 * @return void
 */
void loop() {
  ensureMqtt();
  mqtt.loop();
  readUno();
  if (mqtt.connected() && millis() - tHeartbeat >= HEARTBEAT_MS) {
    tHeartbeat = millis();
    sendToUno("H");
  }
}
