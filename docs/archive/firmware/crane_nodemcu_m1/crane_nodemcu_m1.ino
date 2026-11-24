/**
 * @file crane_nodemcu_m1.ino
 * @brief Crane Overload (MCT332s) - NodeMCU ESP8266 Wi-Fi / MQTT bridge, Milestone 1.
 *
 * Reads the Uno's lines on SoftwareSerial (D5 = RX from the Uno's divider, D6 = TX to the Uno's D10)
 * and publishes them in the app's MQTT format. Makes no safety decisions: it only relays.
 *
 *   Uno -> here:  D,<kg>,<top 0|1>*HH   -> crane/live JSON (5 Hz)
 *                 A,TARE,1*HH           -> crane/ack {"id":n,"ok":true}
 *   App -> here:  crane/cmd {"id":n,"cmd":"TARE"}  -> Uno: C,TARE*HH
 *                 LIFT / LOWER / GOTO / RESET / SET_MAX -> refused for Milestone 1 (no motor yet)
 *   crane/status: {"online":true,"fw":"m1.0"} retained; Last Will {"online":false}
 *
 * Board: "NodeMCU 1.0 (ESP-12E Module)". Library: PubSubClient (Nick O'Leary).
 * Serial Monitor 115200 baud shows every line received from the Uno (wiring check).
 */
#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <SoftwareSerial.h>

// ------------------------------------------------------------------ settings: edit these
const char *WIFI_SSID = "CraneHotspot";     // phone hotspot, 2.4 GHz
const char *WIFI_PASS = "12345678";
const char *MQTT_HOST = "192.168.43.100";   // laptop IP running Mosquitto
const uint16_t MQTT_PORT = 1883;
const float MAX_KG = 1.5;                    // rated load shown by the app

// ------------------------------------------------------------------ topics and timing
const char *T_LIVE = "crane/live";
const char *T_CMD = "crane/cmd";
const char *T_ACK = "crane/ack";
const char *T_EVENTS = "crane/events";
const char *T_STATUS = "crane/status";
const uint32_t LINK_BAUD = 9600;
const uint16_t REFUSE_ACK_MS = 1000;         // at most one "refused" ack per second (hold-to-run repeats)

SoftwareSerial uno(D5, D6);                  // RX, TX
WiFiClient net;
PubSubClient mqtt(net);

char rxBuf[64];
uint8_t rxLen = 0;
long pendingTareId = -1;
bool lastTop = false;
unsigned long lastMqttTryMs = 0, lastRefuseMs = 0, lastDebugMs = 0;

/**
 * XOR checksum of a text line (same as the Uno).
 * @param s Text before the '*'.
 * @return Checksum byte.
 */
uint8_t checksum(const char *s) {
  uint8_t c = 0;
  while (*s) c ^= (uint8_t)*s++;
  return c;
}

/**
 * Sends one checksummed line to the Uno.
 * @param body Text without the checksum, e.g. "C,TARE".
 * @return Nothing.
 */
void sendToUno(const char *body) {
  char out[48];
  snprintf(out, sizeof out, "%s*%02X", body, checksum(body));
  uno.println(out);
  Serial.print(F("-> uno ")); Serial.println(out);
}

/**
 * Publishes an acknowledgement for a command.
 * @param id Command id from the app.
 * @param ok true if accepted.
 * @param reason Refusal reason (ignored when ok).
 * @return Nothing.
 */
void publishAck(long id, bool ok, const char *reason) {
  char msg[80];
  if (ok) snprintf(msg, sizeof msg, "{\"id\":%ld,\"ok\":true}", id);
  else snprintf(msg, sizeof msg, "{\"id\":%ld,\"ok\":false,\"reason\":\"%s\"}", id, reason);
  mqtt.publish(T_ACK, msg);
}

/**
 * Reads a whole number after "key": in a small JSON text.
 * @param json Message text.
 * @param key Key with quotes, e.g. "\"id\"".
 * @param fallback Value returned when the key is missing.
 * @return The number, or fallback.
 */
long jsonLong(const char *json, const char *key, long fallback) {
  const char *p = strstr(json, key);
  if (!p) return fallback;
  p = strchr(p, ':');
  return p ? strtol(p + 1, nullptr, 10) : fallback;
}

/**
 * Copies the string value of "cmd" from a small JSON text.
 * @param json Message text.
 * @param out Buffer for the command name.
 * @param n Buffer size.
 * @return true if a command was found.
 */
bool jsonCmd(const char *json, char *out, size_t n) {
  const char *p = strstr(json, "\"cmd\"");
  if (!p) return false;
  p = strchr(p + 5, '"');
  if (!p) return false;
  const char *e = strchr(++p, '"');
  if (!e || (size_t)(e - p) >= n) return false;
  memcpy(out, p, e - p);
  out[e - p] = 0;
  return true;
}

/**
 * Handles a command from the app (crane/cmd).
 * @param topic MQTT topic.
 * @param payload Message bytes.
 * @param len Message length.
 * @return Nothing.
 */
void onMessage(char *topic, byte *payload, unsigned int len) {
  char json[160];
  len = len < sizeof(json) - 1 ? len : sizeof(json) - 1;
  memcpy(json, payload, len);
  json[len] = 0;
  char cmd[16];
  if (!jsonCmd(json, cmd, sizeof cmd)) return;
  const long id = jsonLong(json, "\"id\"", 0);
  Serial.print(F("<- app ")); Serial.println(json);
  if (strcmp(cmd, "TARE") == 0) {
    pendingTareId = id;
    sendToUno("C,TARE");
  } else if (strcmp(cmd, "PING") == 0 || strcmp(cmd, "STOP") == 0) {
    // nothing moves in Milestone 1: heartbeat and STOP need no action
  } else if (millis() - lastRefuseMs >= REFUSE_ACK_MS) {
    lastRefuseMs = millis();
    publishAck(id, false, "BUSY");          // LIFT, LOWER, GOTO, RESET, SET_MAX: motor not fitted yet
  }
}

/**
 * Turns a data line from the Uno into crane/live JSON (and a TOP event on change).
 * @param kg Weight text from the Uno.
 * @param top IR top state.
 * @return Nothing.
 */
void publishLive(const char *kg, bool top) {
  char msg[220];
  snprintf(msg, sizeof msg,
           "{\"t\":%lu,\"kg\":%s,\"max\":%.2f,\"h\":0,\"a\":0,\"top\":%s,\"st\":\"%s\",\"mode\":\"REMOTE\",\"src\":\"NONE\",\"us\":0,\"obs\":false}",
           millis(), kg, MAX_KG, top ? "true" : "false", top ? "TOP" : "IDLE");
  mqtt.publish(T_LIVE, msg);
  if (top && !lastTop) {
    char ev[80];
    snprintf(ev, sizeof ev, "{\"t\":%lu,\"type\":\"TOP\",\"kg\":%s}", millis(), kg);
    mqtt.publish(T_EVENTS, ev);
  }
  lastTop = top;
}

/**
 * Checks a line from the Uno and acts on it.
 * @param line Received text without the line ending (modified in place).
 * @return Nothing.
 */
void handleUnoLine(char *line) {
  if (millis() - lastDebugMs >= 1000) {     // print about one line per second as a wiring check
    lastDebugMs = millis();
    Serial.print(F("<- uno ")); Serial.println(line);
  }
  char *star = strchr(line, '*');
  if (!star) return;
  *star = 0;
  if ((uint8_t)strtol(star + 1, nullptr, 16) != checksum(line)) { Serial.println(F("bad checksum")); return; }
  if (strncmp(line, "D,", 2) == 0) {
    char *kg = line + 2;
    char *comma = strchr(kg, ',');
    if (!comma) return;
    *comma = 0;
    if (mqtt.connected()) publishLive(kg, comma[1] == '1');
  } else if (strcmp(line, "A,TARE,1") == 0 && pendingTareId >= 0) {
    if (mqtt.connected()) publishAck(pendingTareId, true, "");
    pendingTareId = -1;
  }
}

/**
 * Reads characters from the Uno and handles each complete line.
 * @return Nothing.
 */
void readUno() {
  while (uno.available()) {
    const char c = uno.read();
    if (c == '\n' || c == '\r') {
      if (rxLen) { rxBuf[rxLen] = 0; handleUnoLine(rxBuf); rxLen = 0; }
    } else if (rxLen < sizeof(rxBuf) - 1) {
      rxBuf[rxLen++] = c;
    } else {
      rxLen = 0;
    }
  }
}

/**
 * (Re)connects to the broker every 3 s while disconnected, with the Last Will set.
 * @return Nothing.
 */
void keepMqtt() {
  if (mqtt.connected() || WiFi.status() != WL_CONNECTED) return;
  if (millis() - lastMqttTryMs < 3000) return;
  lastMqttTryMs = millis();
  Serial.print(F("MQTT connect to ")); Serial.print(MQTT_HOST); Serial.print(F(" ... "));
  if (mqtt.connect("crane-nodemcu", nullptr, nullptr, T_STATUS, 1, true, "{\"online\":false}")) {
    mqtt.publish(T_STATUS, "{\"online\":true,\"fw\":\"m1.0\"}", true);
    mqtt.subscribe(T_CMD, 1);
    Serial.println(F("ok"));
  } else {
    Serial.print(F("failed, state ")); Serial.println(mqtt.state());
  }
}

/**
 * Starts the serial ports, Wi-Fi and MQTT client.
 * @return Nothing.
 */
void setup() {
  Serial.begin(115200);
  uno.begin(LINK_BAUD);
  Serial.println(F("\nCrane Overload NodeMCU bridge m1.0"));
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);         // connects in the background
  mqtt.setServer(MQTT_HOST, MQTT_PORT);
  mqtt.setCallback(onMessage);
}

/**
 * Relays Uno lines to MQTT and app commands to the Uno; keeps the connections up.
 * @return Nothing.
 */
void loop() {
  static bool wifiShown = false;
  if (WiFi.status() == WL_CONNECTED && !wifiShown) {
    wifiShown = true;
    Serial.print(F("Wi-Fi ok, IP ")); Serial.println(WiFi.localIP());
  }
  readUno();
  keepMqtt();
  mqtt.loop();
}
