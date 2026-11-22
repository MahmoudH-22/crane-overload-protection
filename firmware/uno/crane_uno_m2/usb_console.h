/**
 * @file usb_console.h
 * @brief USB Serial Monitor (115200, line ending "Newline"): calibration commands and the status line.
 *
 * Commands: t tare (empty basket) | c 1000 calibrate with a known weight in grams | s settings |
 *           x clear calibration | p toggle the status line.
 */
#pragma once
#include <Arduino.h>

namespace usb_console {

/**
 * Handles one typed command, if a line is waiting.
 * @return Nothing.
 */
void poll();

/**
 * Prints one status line (weight, max, IR, state, link counters) unless turned off with p.
 * @return Nothing.
 */
void printStatus();

}  // namespace usb_console
