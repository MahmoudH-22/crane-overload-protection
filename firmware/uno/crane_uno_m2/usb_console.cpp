/**
 * @file usb_console.cpp
 * @brief USB Serial Monitor commands and status line: see usb_console.h.
 */
#include "usb_console.h"

#include "app_link.h"
#include "crane_state.h"
#include "load_cell.h"

namespace usb_console {

namespace {
bool statusOn = true;  ///< status line on / off (p)
}  // namespace

void poll() {
  if (!Serial.available()) return;
  String line = Serial.readStringUntil('\n');
  line.trim();
  if (!line.length()) return;
  const char cmd = tolower(line.charAt(0));
  if (cmd == 't') {
    load_cell_with_conditioning::tareSlow();
  } else if (cmd == 'c') {
    load_cell_with_conditioning::calibrate(line.substring(1).toFloat());
  } else if (cmd == 's') {
    load_cell_with_conditioning::printSettings();
  } else if (cmd == 'x') {
    load_cell_with_conditioning::clearCalibration();
    Serial.println(F("Calibration cleared."));
  } else if (cmd == 'p') {
    statusOn = !statusOn;
  } else {
    Serial.println(F("Commands: t | c <grams> | s | x | p"));
  }
}

void printStatus() {
  if (!statusOn) return;
  Serial.print(F("kg "));
  Serial.print(crane::kg, 3);
  Serial.print(F("  max "));
  Serial.print(crane::maxKg, 2);
  Serial.print(F("  IR "));
  Serial.print(crane::top ? F("TOP  ") : F("clear"));
  Serial.print(F("  st "));
  Serial.print(crane::stateName());
  Serial.print(F("  link ok/bad "));
  Serial.print(link::goodLines);
  Serial.print('/');
  Serial.print(link::badLines);
  Serial.print(F("  app "));
  Serial.println(millis() - link::lastMsgMs < 2000 ? F("yes") : F("no"));
}

}  // namespace usb_console
