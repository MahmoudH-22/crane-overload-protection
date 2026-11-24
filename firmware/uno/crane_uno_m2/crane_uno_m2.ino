/**
 * @file crane_uno_m2.ino
 * @brief Crane Overload (MCT332s) - Uno firmware, milestone 2: IR top sensor + load cell, linked to the
 *        phone app through an HC-05 Bluetooth module. All safety decisions stay here.
 *
 * This file only starts the parts and runs the loop schedule. Each part has its own tab:
 *   config.h          fitted parts (HAS_*), pins, limits, timing          <- change things here
 *   ir_sensor.*       IR top-of-travel sensor (D2, debounced, LED 13)
 *   load_cell.*       load cell + AD620 on A0, EEPROM calibration
 *   crane_state.*     crane state + automatic safety (overload latch, TOP event)
 *   commands.*        app commands and their rules (RESET, TARE, SET_MAX, NOT_FITTED)
 *   app_link.*        HC-05 link: sends L / A / E / S lines, reads C lines
 *   crane_link.h      the line format + checksum (shared with the old NodeMCU, ported to the app)
 *   usb_console.*     Serial Monitor commands (t, c, s, x, p) and status line
 *
 * What it does now:
 *   - Load cell + AD620 on A0 (same code and EEPROM calibration as milestone 1)  -> "kg"
 *   - IR top-of-travel module on D2                                             -> "top"
 *   - Overload: weight > max for 3 readings -> OVERLOAD latched; RESET only below 95 % of max.
 *   - App commands: TARE (only IDLE), SET_MAX (0.5 .. 1.5 kg), RESET, STOP, PING.
 *     LIFT / LOWER / GOTO are refused with NOT_FITTED until the motor is wired (HAS_MOTOR 1).
 *   - Sends a live line every 200 ms, the fitted-sensor list every 2 s, events and acks to the app.
 *
 * Wiring
 *   Load cell + AD620 -> A0 (see milestone 1).   IR module: VCC 5V, GND, OUT -> D2 (active LOW).
 *   HC-05 (SoftwareSerial 9600): VCC -> 5V, GND -> GND, HC-05 TXD -> D10,
 *     Uno D11 -> 1 k -> HC-05 RXD, with 2 k (or 1 k) from HC-05 RXD to GND.
 *   Not discoverable / no answer: reset the HC-05 with firmware/uno/hc05_setup.
 *
 * USB Serial Monitor 115200 baud, line ending "Newline":
 *   t  tare (empty basket)   c 1000  calibrate with a known weight in grams   s  settings
 *   x  clear calibration     p  toggle the status print
 *
 * Protocol: crane_link.h. Contract: CLAUDE.md "MQTT contract".
 */
#include "app_link.h"
#include "config.h"
#include "crane_state.h"
#include "ir_sensor.h"
#include "load_cell.h"
#include "usb_console.h"

unsigned long tSafety = 0, tLive = 0, tSensors = 0, tPrint = 0;  ///< last run of each periodic task

/**
 * Starts USB serial, the HC-05 link and the fitted sensors.
 * @return Nothing.
 */
void setup() {
  Serial.begin(USB_BAUD);
  link::begin();
  analogReference(DEFAULT);
  Serial.print(F("\nCrane Overload - Uno "));
  Serial.print(FW_TAG);
  Serial.println(F(": IR + load cell -> HC-05 Bluetooth -> app"));
#if HAS_IR
  load_ir_detection::begin();
#endif
#if HAS_LOAD_CELL
  load_cell_with_conditioning::begin();
#endif
  link::sendSensors();
}

/**
 * Non-blocking main loop: sensors every pass, safety every 50 ms, live every 200 ms, sensor list every 2 s.
 * @return Nothing.
 */
void loop() {
  crane::updateTop();
#if HAS_LOAD_CELL
  load_cell_with_conditioning::update();
#endif
  link::poll();
  usb_console::poll();

  const unsigned long now = millis();
  if (now - tSafety >= SAFETY_MS) {
    tSafety = now;
    crane::safetyTick();
  }
  if (now - tLive >= LIVE_MS) {
    tLive = now;
    link::sendLive();
  }
  if (now - tSensors >= SENSORS_MS) {
    tSensors = now;
    link::sendSensors();
  }
  if (now - tPrint >= PRINT_MS) {
    tPrint = now;
    usb_console::printStatus();
  }
}
