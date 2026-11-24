/**
 * @file load_cell.cpp
 * @brief Load cell + AD620: see load_cell.h.
 */
#include "load_cell.h"

#include <EEPROM.h>

#include "config.h"

namespace load_cell_with_conditioning {

namespace {
const float ADC_VREF = 5.0;
const float RG_OHM = 180.0;
const float GAIN = 1.0 + 49400.0 / RG_OHM;  ///< AD620: 275.4
const float EXCITATION = 5.0;               ///< V across the bridge (red - black)
const float CELL_CAPACITY_KG = 5.0;
const uint8_t OVERSAMPLE = 64;              ///< ~7 ms per sample
const float FILTER_ALPHA = 0.2;

const uint16_t CAL_MAGIC = 0xC0A6;          ///< marks a saved calibration in EEPROM

/** Calibration saved at EEPROM address 0 (same layout as milestone 1). */
struct Calibration {
  uint16_t magic;
  float zeroCounts;
  float countsPerKg;
};

Calibration cal;
float filtered = 0;  ///< smoothed ADC counts

/**
 * Reads A0 OVERSAMPLE times and returns the average.
 * @return Average ADC counts (0..1023, fractional).
 */
float readCountsAveraged() {
  uint32_t sum = 0;
  for (uint8_t i = 0; i < OVERSAMPLE; i++) sum += analogRead(PIN_LOAD);
  return (float)sum / OVERSAMPLE;
}

/**
 * Converts ADC counts to volts at A0.
 * @param counts ADC counts.
 * @return Volts.
 */
float countsToVolts(float counts) { return counts * ADC_VREF / 1023.0; }

/**
 * Default slope before calibration (1 mV/V cell).
 * @return ADC counts per kg.
 */
float defaultCountsPerKg() {
  const float voltsPerKg = (1.0e-3 * EXCITATION / CELL_CAPACITY_KG) * GAIN;
  return voltsPerKg * 1023.0 / ADC_VREF;
}

/**
 * Loads the calibration from EEPROM, or sets defaults.
 * @return true if a saved calibration was found.
 */
bool loadCalibration() {
  EEPROM.get(0, cal);
  if (cal.magic == CAL_MAGIC && cal.countsPerKg > 1.0 && cal.countsPerKg < 2000.0) return true;
  cal.magic = 0;
  cal.zeroCounts = filtered;
  cal.countsPerKg = defaultCountsPerKg();
  return false;
}

/**
 * Saves the calibration to EEPROM.
 * @return Nothing.
 */
void saveCalibration() {
  cal.magic = CAL_MAGIC;
  EEPROM.put(0, cal);
}

/**
 * Averages the input for a while (blocking; only used by begin and the USB calibration commands).
 * @param ms Time to average.
 * @return Average counts.
 */
float settleAndAverage(uint16_t ms) {
  float sum = 0;
  uint16_t n = 0;
  const unsigned long t0 = millis();
  while (millis() - t0 < ms) {
    const float c = readCountsAveraged();
    sum += c;
    n++;
    filtered += FILTER_ALPHA * (c - filtered);
  }
  return sum / n;
}
}  // namespace

void begin() {
  filtered = readCountsAveraged();
  settleAndAverage(800);
  if (loadCalibration()) Serial.println(F("Saved calibration loaded."));
  else Serial.println(F("No calibration yet: empty basket -> t, then a known weight -> c <grams>."));
  printSettings();
}

void update() { filtered += FILTER_ALPHA * (readCountsAveraged() - filtered); }

float weightKg() { return (filtered - cal.zeroCounts) / cal.countsPerKg; }

void tareQuick() {
  cal.zeroCounts = filtered;
  saveCalibration();
}

void tareSlow() {
  Serial.println(F("Tare: keep the basket empty and still..."));
  cal.zeroCounts = settleAndAverage(1500);
  saveCalibration();
  Serial.print(F("Zero = "));
  Serial.print(cal.zeroCounts, 1);
  Serial.println(F(" counts. Saved."));
}

void calibrate(float grams) {
  if (grams <= 0) {
    Serial.println(F("Give the weight in grams, e.g.  c 1000"));
    return;
  }
  Serial.print(F("Calibrating with "));
  Serial.print(grams, 0);
  Serial.println(F(" g: keep it still..."));
  const float delta = settleAndAverage(2000) - cal.zeroCounts;
  if (delta < 5) {
    Serial.println(F("Change too small: tare first, or swap the green and white wires."));
    return;
  }
  cal.countsPerKg = delta / (grams / 1000.0);
  saveCalibration();
  printSettings();
}

void clearCalibration() {
  cal.magic = 0;
  EEPROM.put(0, cal);
  loadCalibration();
}

void printSettings() {
  const float voltsPerKg = countsToVolts(cal.countsPerKg);
  const float mvPerV = voltsPerKg / GAIN * 1000.0 * CELL_CAPACITY_KG / EXCITATION;
  Serial.print(F("Zero "));
  Serial.print(cal.zeroCounts, 1);
  Serial.print(F(" counts, slope "));
  Serial.print(cal.countsPerKg, 2);
  Serial.print(F(" counts/kg, cell "));
  Serial.print(mvPerV, 2);
  Serial.println(cal.magic == CAL_MAGIC ? F(" mV/V (calibrated)") : F(" mV/V (default, not calibrated)"));
}

}  // namespace load_cell_with_conditioning
