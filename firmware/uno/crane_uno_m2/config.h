/**
 * @file config.h
 * @brief Crane Uno m2: everything you may need to change in one place: which parts are fitted, pins, limits, timing.
 *
 * Set a HAS_* flag to 1 when that part is wired and tested. The flags decide what the crane reports to the app
 * (the S line) and which code runs; the app enables the matching cards and buttons by itself.
 */
#pragma once
#include <Arduino.h>

// ------------------------------------------------------------------ fitted parts
#define HAS_LOAD_CELL 1   ///< load cell + AD620 on A0
#define HAS_IR 1          ///< IR top-of-travel sensor
#define HAS_MOTOR 0       ///< motor driver: LIFT / LOWER / GOTO (not yet)
#define HAS_CURRENT 0     ///< ACS712 motor current (not yet)
#define HAS_ENCODER 0     ///< hook height encoder (not yet)
#define HAS_ULTRASONIC 0  ///< HC-SR04 under the basket (not yet)

/** Firmware tag (shown on the USB monitor). */
const char FW_TAG[] = "m2.0";

// ------------------------------------------------------------------ pins
/** IR module OUT (FC-51, active LOW). Full crane: move to A2 (D2 / D3 are needed for the encoder). */
const uint8_t PIN_IR = 2;
/** Built-in LED, mirrors the IR state. */
const uint8_t PIN_IR_LED = 13;
/** AD620 output (through 16 k / 1 uF). */
const uint8_t PIN_LOAD = A0;
/** SoftwareSerial RX from HC-05 TXD. */
const uint8_t PIN_BT_RX = 10;
/** SoftwareSerial TX to HC-05 RXD (through the 1 k / 2 k divider). */
const uint8_t PIN_BT_TX = 11;

// ------------------------------------------------------------------ serial speeds
/** USB Serial Monitor. */
const long USB_BAUD = 115200;
/** HC-05 data-mode speed (factory default; set with firmware/uno/hc05_setup). */
const long BT_BAUD = 9600;

// ------------------------------------------------------------------ crane limits (same as tools/crane_sim.py)
/** Highest overload limit the app may set, kg (also the start value). */
const float MAX_LIMIT_KG = 1.5;
/** Lowest overload limit, kg (below -> ack RANGE). */
const float MIN_LIMIT_KG = 0.5;
/** Consecutive 50 ms readings above max before OVERLOAD latches. */
const uint8_t OVERLOAD_READINGS = 3;
/** RESET is accepted only below this fraction of max. */
const float RESET_FRACTION = 0.95;

// ------------------------------------------------------------------ timing, ms
const uint16_t SAFETY_MS = 50;    ///< safety step (overload latch)
const uint16_t LIVE_MS = 200;     ///< live line to the app
const uint16_t SENSORS_MS = 2000; ///< fitted-sensor list to the app
const uint16_t PRINT_MS = 500;    ///< status line on USB
