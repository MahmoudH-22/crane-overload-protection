/**
 * @file ir_sensor.cpp
 * @brief IR top-of-travel sensor: see ir_sensor.h.
 */
#include "ir_sensor.h"

#include "config.h"

namespace load_ir_detection {

namespace {
const uint16_t DEBOUNCE_MS = 20;  ///< the output must be stable this long

bool detectedState = false;       ///< debounced state
bool lastRaw = false;             ///< last raw reading
unsigned long lastChangeMs = 0;   ///< when the raw reading last changed
}  // namespace

void begin() {
  pinMode(PIN_IR, INPUT);
  pinMode(PIN_IR_LED, OUTPUT);
  digitalWrite(PIN_IR_LED, LOW);
}

bool update() {
  const bool raw = (digitalRead(PIN_IR) == LOW);
  if (raw != lastRaw) {
    lastRaw = raw;
    lastChangeMs = millis();
  }
  if (raw != detectedState && millis() - lastChangeMs >= DEBOUNCE_MS) {
    detectedState = raw;
    digitalWrite(PIN_IR_LED, detectedState ? HIGH : LOW);
    return true;
  }
  return false;
}

bool detected() { return detectedState; }

}  // namespace load_ir_detection
