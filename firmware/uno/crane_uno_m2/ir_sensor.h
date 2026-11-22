/**
 * @file ir_sensor.h
 * @brief IR top-of-travel sensor (ON/OFF), from milestone 1: debounced, mirrored on the built-in LED.
 */
#pragma once
#include <Arduino.h>

namespace load_ir_detection {

/**
 * Sets the IR input and the indicator LED.
 * @return Nothing.
 */
void begin();

/**
 * Reads and debounces the IR output, and drives the LED. Non-blocking; call every loop.
 * @return true if the debounced state changed on this call.
 */
bool update();

/**
 * Current debounced state.
 * @return true when the hook is at the top (lifting must stop).
 */
bool detected();

}  // namespace load_ir_detection
