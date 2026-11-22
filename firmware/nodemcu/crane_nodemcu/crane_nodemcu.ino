/**
 * @file crane_nodemcu.ino
 * @brief Crane Overload: NodeMCU ESP8266 Wi-Fi / MQTT bridge (milestone 2). Makes NO safety decisions.
 *
 * Uno lines -> MQTT (see crane_link.h for the line format, CLAUDE.md for the MQTT contract):
 *   L -> crane/live      A -> crane/ack      E -> crane/events      S -> crane/status (retained, "sensors")
 * MQTT -> Uno:
 *   crane/cmd {"id":17,"cmd":"LIFT"} -> "C,17,LIFT"   (only known commands are forwarded)
 *
 * crane/status (retained): {"online":true,"fw":"m2.0","sensors":["kg","top"]}
 *   - online = the Uno is talking (a line within the last 2 s). Unplug the Uno -> the app shows "Crane offline".
 *   - Last Will {"online":false} retained, keepalive 2 s: power cut / Wi-Fi loss -> "Crane offline" in ~3 s.
 *
 * Wiring (SoftwareSerial 9600):
 *   NodeMCU D5 (RX) <- Uno D11 (TX) through a 1 k / 2 k divider (5 V -> 3.3 V)
 *   NodeMCU D6 (TX) -> Uno D10 (RX)
 *   NodeMCU GND     -- Uno GND
 *
 * Board: "NodeMCU 1.0 (ESP-12E Module)" (esp8266 core 3.x).
 * Libraries: PubSubClient (Nick O'Leary), ArduinoJson 7 (Benoit Blanchon).
 * USB Serial Monitor 115200 shows Wi-Fi / MQTT status and every line in both directions.
 * Settings: config.h.
 */
#include <ArduinoJson.h>
#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <SoftwareSerial.h>

#include "config.h"
#include "crane_link.h"

using namespace crane_link;

// ============================================================ constants
const char* const T_LIVE = "crane/live";
const char* const T_CMD = "crane/cmd";
const char* const T_ACK = "crane/ack";
const char* const T_EVENTS = "crane/events";
const char* const T_STATUS = "crane/status";
const char* const FW_TAG = "m2.0";
const char* const WILL = "{\"online\":false}";

const uint16_t MQTT_KEEPALIVE_S = 2;   // broker publishes the Last Will ~3 s after we vanish
const uint16_t MQTT_RETRY_MS = 2000;
const uint16_t UNO_SILENT_MS = 2000;   // no Uno line this long -> status online:false
const uint16_t REPORT_MS = 5000;       // USB status line
#define DEBUG_LINES 1                  // 1 = print every line on USB (set 0 if it is too chatty)

// ============================================================ globals
SoftwareSerial uno(D5, D6);  // RX, TX
WiFiClient net;
PubSubClient mqtt(net);

char rx[MAX_LINE];
uint8_t rxLen = 0;
unsigned long lastUnoMs = 0, lastRetryMs = 0, lastReportMs = 0;
uint32_t goodLines = 0, badLines = 0, published = 0, commands = 0;
char sensors[48] = "";            // from the Uno's S line
bool statusOnline = false;        // last value published on crane/status
char statusSensors[48] = "#";     // sensors last published ("#" = never)
bool wifiWasUp = false;

// ============================================================ helpers
/**
 * Whether the Uno has sent a valid line recently.
 * @return true if the last line arrived within UNO_SILENT_MS.
 */
bool unoAlive() {
  return lastUnoMs != 0 && millis() - lastUnoMs < UNO_SILENT_MS;
}

/**
 * Publishes a JSON payload when connected.
 * @param topic MQTT topic.
 * @param json Payload.
 * @param retain Retained flag.
 * @return true if handed to the client.
 */
bool publish(const char* topic, const char* json, bool retain = false) {
  if (!mqtt.connected()) return false;
  const bool ok = mqtt.publish(topic, json, retain);
  if (ok) published++;
  return ok;
}

/**
 * Publishes crane/status (retained) if the online flag or the sensor list changed, or when forced.
 * @param force Publish even if nothing changed (after a reconnect).
 * @return Nothing.
 */
void publishStatus(bool force = false) {
  const bool online = unoAlive();
  if (!force && online == statusOnline && strcmp(sensors, statusSensors) == 0) return;
  char json[128];
  if (!statusJson(online, FW_TAG, sensors, json, sizeof json)) return;
  if (publish(T_STATUS, json, true)) {
    statusOnline = online;
    strncpy(statusSensors, sensors, sizeof statusSensors - 1);
    Serial.print(F("status ")); Serial.println(json);
  }
}

/**
 * Sends one framed line to the Uno.
 * @param body Line body without checksum.
 * @return Nothing.
 */
void sendToUno(const char* body) {
  char out[MAX_LINE];
  if (!frame(body, out, sizeof out)) return;
  uno.print(out);
#if DEBUG_LINES
  Serial.print(F("-> uno ")); Serial.print(out);
#endif
}

// ============================================================ Uno -> MQTT
/**
 * Handles one verified line from the Uno.
 * @param line Line without checksum (split in place).
 * @return Nothing.
 */
void handleUnoLine(char* line) {
  char* f[MAX_FIELDS];
  const uint8_t n = split(line, f, MAX_FIELDS);
  char json[256];
  switch (f[0][0]) {
    case 'L':
      if (liveJson(f, n, json, sizeof json)) publish(T_LIVE, json);
      break;
    case 'A':
      if (ackJson(f, n, json, sizeof json)) publish(T_ACK, json);
      break;
    case 'E':
      if (eventJson(f, n, json, sizeof json)) publish(T_EVENTS, json);
      break;
    case 'S':
      if (n >= 2) {
        // trim the trailing space the Uno leaves
        strncpy(sensors, f[1], sizeof sensors - 1);
        sensors[sizeof sensors - 1] = '\0';
        for (int i = (int)strlen(sensors) - 1; i >= 0 && sensors[i] == ' '; i--) sensors[i] = '\0';
      }
      break;
    default:
      break;
  }
}

/**
 * Reads characters from the Uno and dispatches complete, verified lines.
 * @return Nothing.
 */
void readUno() {
  while (uno.available()) {
    const char c = uno.read();
    if (c == '\n') {
      rx[rxLen] = '\0';
      if (rxLen && unframe(rx)) {
        goodLines++;
        lastUnoMs = millis();
#if DEBUG_LINES
        if (rx[0] != 'L') { Serial.print(F("<- uno ")); Serial.println(rx); }  // L every 200 ms is too chatty
#endif
        handleUnoLine(rx);
      } else if (rxLen) {
        badLines++;
      }
      rxLen = 0;
    } else if (rxLen < sizeof rx - 1) {
      rx[rxLen++] = c;
    } else {
      rxLen = 0;  // over-long / garbage: drop
    }
  }
}

// ============================================================ MQTT -> Uno
/**
 * Handles a crane/cmd message and forwards known commands to the Uno.
 * @param topic Topic.
 * @param payload Bytes.
 * @param len Length.
 * @return Nothing.
 */
void onMqtt(char* topic, byte* payload, unsigned int len) {
  if (strcmp(topic, T_CMD) != 0) return;
  JsonDocument doc;
  if (deserializeJson(doc, payload, len)) return;
  const long id = doc["id"] | -1L;
  const char* cmd = doc["cmd"] | "";
  const bool hasValue = doc["value"].is<double>();
  const double value = doc["value"] | 0.0;
  char body[48];
  if (!commandBody(id, cmd, hasValue, value, body, sizeof body)) return;
  commands++;
  if (strcmp(cmd, "PING") == 0) {
    char out[MAX_LINE];
    if (frame(body, out, sizeof out)) uno.print(out);  // forward silently (every second)
  } else {
    sendToUno(body);
  }
}

// ============================================================ connections
/**
 * Prints Wi-Fi changes on USB.
 * @return Nothing.
 */
void watchWifi() {
  const bool up = WiFi.status() == WL_CONNECTED;
  if (up == wifiWasUp) return;
  wifiWasUp = up;
  if (up) { Serial.print(F("Wi-Fi up, IP ")); Serial.println(WiFi.localIP()); }
  else Serial.println(F("Wi-Fi down, reconnecting..."));
}

/**
 * Connects to the broker when needed (non-blocking retry), with the Last Will.
 * @return Nothing.
 */
void ensureMqtt() {
  if (mqtt.connected() || WiFi.status() != WL_CONNECTED) return;
  if (millis() - lastRetryMs < MQTT_RETRY_MS) return;
  lastRetryMs = millis();
  char id[24];
  snprintf(id, sizeof id, "crane-%06X", ESP.getChipId());
  Serial.print(F("MQTT connecting to ")); Serial.print(MQTT_HOST); Serial.print(':'); Serial.println(MQTT_PORT);
  if (mqtt.connect(id, nullptr, nullptr, T_STATUS, 1, true, WILL)) {
    mqtt.subscribe(T_CMD, 1);
    Serial.println(F("MQTT connected"));
    publishStatus(true);
  } else {
    Serial.print(F("MQTT failed, state ")); Serial.print(mqtt.state());
    Serial.println(F(" (-2 = broker unreachable: check MQTT_HOST, Mosquitto running, firewall)"));
  }
}

/**
 * Prints a short health line on USB every few seconds.
 * @return Nothing.
 */
void report() {
  if (millis() - lastReportMs < REPORT_MS) return;
  lastReportMs = millis();
  Serial.print(F("wifi ")); Serial.print(WiFi.status() == WL_CONNECTED ? F("up") : F("down"));
  Serial.print(F("  mqtt ")); Serial.print(mqtt.connected() ? F("up") : F("down"));
  Serial.print(F("  uno ")); Serial.print(unoAlive() ? F("talking") : F("SILENT (check wiring / baud / GND)"));
  Serial.print(F("  lines ok/bad ")); Serial.print(goodLines); Serial.print('/'); Serial.print(badLines);
  Serial.print(F("  published ")); Serial.print(published);
  Serial.print(F("  cmds ")); Serial.println(commands);
}

// ============================================================ main
/**
 * Starts serial ports, Wi-Fi and the MQTT client.
 * @return Nothing.
 */
void setup() {
  Serial.begin(115200);
  uno.begin(9600);
  Serial.println(F("\ncrane_nodemcu m2.0 starting"));
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  mqtt.setServer(MQTT_HOST, MQTT_PORT);
  mqtt.setCallback(onMqtt);
  mqtt.setBufferSize(512);
  mqtt.setKeepAlive(MQTT_KEEPALIVE_S);
  mqtt.setSocketTimeout(2);
}

/**
 * Keeps the links alive and moves data both ways.
 * @return Nothing.
 */
void loop() {
  watchWifi();
  ensureMqtt();
  mqtt.loop();
  readUno();
  publishStatus();  // only publishes when online / sensors change
  report();
}
