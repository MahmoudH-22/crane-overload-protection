/**
 * @file load_cell.h
 * @brief Load cell + AD620 on A0 (analog sensor with conditioning), from milestone 1.
 *
 * 64x oversampling + exponential filter; calibration (zero and slope) saved in EEPROM, so a milestone-1 calibration
 * is kept. USB commands (usb_console): t tare, c <grams> calibrate, s settings, x clear.
 */
#pragma once
#include <Arduino.h>

namespace load_cell_with_conditioning {

/**
 * Settles the input and loads the calibration (prints what it found on USB).
 * @return Nothing.
 */
void begin();

/**
 * Takes one oversampled reading into the filter. Call every loop (~7 ms).
 * @return Nothing.
 */
void update();

/**
 * Weight from the smoothed reading.
 * @return kg (can be slightly negative around zero).
 */
float weightKg();

/**
 * Tare from the app: uses the already-smoothed value, so it does not block the loop. Saved in EEPROM.
 * @return Nothing.
 */
void tareQuick();

/**
 * Tare from the USB monitor: averages 1.5 s for the best zero (blocking). Saved in EEPROM.
 * @return Nothing.
 */
void tareSlow();

/**
 * Calibrates the slope with a known weight (blocking, 2 s). Saved in EEPROM.
 * @param grams Known weight in grams.
 * @return Nothing.
 */
void calibrate(float grams);

/**
 * Forgets the saved calibration and goes back to the default slope.
 * @return Nothing.
 */
void clearCalibration();

/**
 * Prints the calibration and the measured cell sensitivity on USB.
 * @return Nothing.
 */
void printSettings();

}  // namespace load_cell_with_conditioning
