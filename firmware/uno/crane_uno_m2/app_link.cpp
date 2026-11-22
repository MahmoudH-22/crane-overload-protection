/**
 * @file app_link.cpp
 * @brief Link to the phone app through the HC-05: see app_link.h.
 */
#include "app_link.h"

#include <SoftwareSerial.h>

#include "commands.h"
#include "config.h"
#include "crane_link.h"
#include "crane_state.h"

namespace link {

using namespace crane_link;

unsigned long lastMsgMs = 0;
uint32_t goodLines = 0;
uint32_t badLines = 0;

namespace {
SoftwareSerial bt(PIN_BT_RX, PIN_BT_TX);  ///< RX = D10 (from HC-05 TXD), TX = D11 (to HC-05 RXD via divider)
char rx[MAX_LINE];                        ///< line being received
uint8_t rxLen = 0;

/**
 * Formats a float (AVR printf has no %f).
 * @param v Value.
 * @param buf Output (at least 12 chars).
 * @param decimals Digits after the point.
 * @return buf.
 */
char* fmt(float v, char* buf, uint8_t decimals = 3) {
  dtostrf(v, 0, decimals, buf);
  return buf;
}
}  // namespace

void begin() { bt.begin(BT_BAUD); }

void send(const char* body) {
  char out[MAX_LINE];
  if (frame(body, out, sizeof out)) bt.print(out);
}

void ack(long id, bool ok, const char* reason) {
  char body[40];
  snprintf(body, sizeof body, "A,%ld,%d,%s", id, ok ? 1 : 0, reason);
  send(body);
}

void event(const char* type, float value) {
  char body[48], v[12];
  snprintf(body, sizeof body, "E,%lu,%s,%s", millis(), type, fmt(value, v));
  send(body);
  Serial.print(F("EVENT "));
  Serial.println(type);
}

void sendLive() {
  char kg[12], mx[12];
  char body[MAX_LINE];
  fmt(crane::kg, kg);
  fmt(crane::maxKg, mx, 2);
  // L,t,kg,max,h,a,top,st,mode,src,us,obs  (h, a, us empty until those sensors are wired)
  snprintf(body, sizeof body, "L,%lu,%s,%s,,,%d,%s,REMOTE,NONE,,0", millis(), kg, mx, crane::top ? 1 : 0,
           crane::stateName());
  send(body);
}

void sendSensors() {
  char body[48] = "S,";
#if HAS_LOAD_CELL
  strcat(body, "kg ");
#endif
#if HAS_IR
  strcat(body, "top ");
#endif
#if HAS_ENCODER
  strcat(body, "h ");
#endif
#if HAS_CURRENT
  strcat(body, "a ");
#endif
#if HAS_ULTRASONIC
  strcat(body, "us ");
#endif
#if HAS_MOTOR
  strcat(body, "motor ");
#endif
  send(body);
}

void poll() {
  while (bt.available()) {
    const char c = bt.read();
    if (c == '\n') {
      rx[rxLen] = '\0';
      if (rxLen && unframe(rx)) {
        goodLines++;
        char* f[MAX_FIELDS];
        const uint8_t n = split(rx, f, MAX_FIELDS);
        if (n >= 3 && strcmp(f[0], "C") == 0) {
          lastMsgMs = millis();
          commands::handle(atol(f[1]), f[2], n >= 4 ? f[3] : "");
        }
      } else if (rxLen) {
        badLines++;
      }
      rxLen = 0;
    } else if (rxLen < sizeof rx - 1) {
      rx[rxLen++] = c;
    } else {
      rxLen = 0;  // over-long line: drop it
    }
  }
}

}  // namespace link
