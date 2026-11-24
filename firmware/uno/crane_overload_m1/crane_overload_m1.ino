/**
 * @file crane_overload_m1.ino
 * @brief Crane Overload (MCT332s) - Milestone 1 firmware: the two working sensor prototypes in one sketch.
 *
 * Modules
 *   load_ir_detection            ON/OFF sensor: IR obstacle module (FC-51) sees the load at the top
 *                                (OUT active LOW) -> LED on D13, "STOP!" / "KEEP GOING".
 *   load_cell_with_conditioning  Analog sensor with conditioning: 5 kg load cell -> AD620AN
 *                                (RG 180 ohm, gain 275.4, REF 1.56 V via LM358) -> 16k/1uF -> A0.
 *
 * Wiring (as tested)
 *   IR module: VCC 5V, GND, OUT -> D2.   Load cell + AD620: see load-cell-AD620-wiring.png, output on A0.
 *   Note: in the full crane, D2/D3 are kept for the motor encoder interrupts; move IR OUT to A2 then
 *   and change IR_PIN below (A2 works as a digital input).
 *
 * Serial Monitor 115200 baud, line ending "Newline". Commands:
 *   t        tare the load cell (empty basket)
 *   c 1000   calibrate with a known weight in grams
 *   s        show load cell settings and measured sensitivity (mV/V)
 *   r        toggle the raw / voltage columns
 *   x        clear the saved calibration
 */
#include <EEPROM.h>

// =====================================================================================
// Module 1: load_ir_detection  (ON/OFF sensor)
// =====================================================================================
namespace load_ir_detection {
  const uint8_t IR_PIN = 2;              // FC-51 OUT (active LOW: LOW = object detected)
  const uint8_t LED_PIN = 13;            // built-in LED (or an external LED/buzzer)
  const uint16_t DEBOUNCE_MS = 20;       // the output must stay the same this long to be accepted

  bool detectedState = false;            // debounced state
  bool lastRaw = false;
  unsigned long lastChangeMs = 0;

  /**
   * Sets the IR input and the indicator LED.
   * @return Nothing.
   */
  void begin() {
    pinMode(IR_PIN, INPUT);
    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, LOW);
  }

  /**
   * Reads and debounces the IR output, and drives the LED. Call every loop (non-blocking).
   * @return true if the debounced state changed on this call.
   */
  bool update() {
    const bool raw = (digitalRead(IR_PIN) == LOW);
    if (raw != lastRaw) { lastRaw = raw; lastChangeMs = millis(); }
    if (raw != detectedState && millis() - lastChangeMs >= DEBOUNCE_MS) {
      detectedState = raw;
      digitalWrite(LED_PIN, detectedState ? HIGH : LOW);
      return true;
    }
    return false;
  }

  /**
   * Current debounced state.
   * @return true when the load is detected at the top (lifting must stop).
   */
  bool detected() {
    return detectedState;
  }

  /**
   * Status text, as in the original IR sketch.
   * @return "STOP!" when detected, otherwise "KEEP GOING".
   */
  const __FlashStringHelper *statusText() {
    return detectedState ? F("STOP!") : F("KEEP GOING");
  }
}

// =====================================================================================
// Module 2: load_cell_with_conditioning  (analog sensor with signal conditioning)
// =====================================================================================
namespace load_cell_with_conditioning {
  void printSettings();                 // forward declaration (used by calibrate before its definition)

  // ------------------------------------------------------------------ hardware and design values
  const uint8_t PIN_LOAD = A0;
  const float ADC_VREF = 5.0;                      // Uno ADC reference = the same 5 V that excites the bridge
  const float RG_OHM = 180.0;
  const float GAIN = 1.0 + 49400.0 / RG_OHM;       // AD620: G = 1 + 49.4 k / RG = 275.4
  const float REF_EXPECTED = 5.0 * 1.0 / 3.2;      // 1.56 V from 2.2 k / 1 k
  const float EXCITATION = 5.0;                    // V across the bridge (red - black)
  const float CELL_CAPACITY_KG = 5.0;

  // ------------------------------------------------------------------ measurement settings
  const uint8_t OVERSAMPLE = 64;                   // ADC readings averaged per sample (≈ 7 ms)
  const float FILTER_ALPHA = 0.2;                  // exponential smoothing of the samples (0..1)
  const uint16_t PRINT_MS = 250;
  const float OUT_MIN_V = 1.0, OUT_MAX_V = 3.9;    // AD620 on a single 5 V supply swings ≈ 1.2..3.8 V

  // ------------------------------------------------------------------ calibration (saved in EEPROM)
  const uint16_t CAL_MAGIC = 0xC0A6;
  struct Calibration {
    uint16_t magic;       // CAL_MAGIC when valid
    float zeroCounts;     // ADC counts with the empty basket
    float countsPerKg;    // ADC counts per kg (slope)
  };
  Calibration cal;
  float filtered = 0;     // smoothed ADC counts
  bool showRaw = true;
  unsigned long lastPrint = 0;

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
   * Converts ADC counts to the voltage at A0.
   * @param counts ADC counts.
   * @return Volts.
   */
  float countsToVolts(float counts) {
    return counts * ADC_VREF / 1023.0;
  }

  /**
   * Default slope before calibration, assuming a 1 mV/V cell (1 mV per kg at 5 V excitation).
   * @return ADC counts per kg.
   */
  float defaultCountsPerKg() {
    const float voltsPerKg = (1.0e-3 * EXCITATION / CELL_CAPACITY_KG) * GAIN;   // 0.275 V/kg
    return voltsPerKg * 1023.0 / ADC_VREF;                                        // ≈ 56 counts/kg
  }

  /**
   * Loads the calibration from EEPROM, or sets defaults if none is saved.
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
   * Saves the current calibration to EEPROM.
   * @return Nothing.
   */
  void saveCalibration() {
    cal.magic = CAL_MAGIC;
    EEPROM.put(0, cal);
  }

  /**
   * Weight from the smoothed ADC counts using the calibration.
   * @return Weight in kg (can be slightly negative around zero).
   */
  float weightKg() {
    return (filtered - cal.zeroCounts) / cal.countsPerKg;
  }

  /**
   * Averages the input for a while, to settle the filter before tare/calibration.
   * @param ms Time to average, in milliseconds.
   * @return Average ADC counts over that time.
   */
  float settleAndAverage(uint16_t ms) {
    float sum = 0;
    uint16_t n = 0;
    unsigned long t0 = millis();
    while (millis() - t0 < ms) {
      float c = readCountsAveraged();
      sum += c;
      n++;
      filtered += FILTER_ALPHA * (c - filtered);
    }
    return sum / n;
  }

  /**
   * Sets the zero point with the empty basket and saves it.
   * @return Nothing.
   */
  void tare() {
    Serial.println(F("Tare: keep the basket empty and still..."));
    cal.zeroCounts = settleAndAverage(1500);
    saveCalibration();
    Serial.print(F("Zero = "));
    Serial.print(cal.zeroCounts, 1);
    Serial.print(F(" counts ("));
    Serial.print(countsToVolts(cal.zeroCounts), 3);
    Serial.println(F(" V). Saved."));
  }

  /**
   * Calibrates the slope with a known weight in the basket and saves it.
   * @param grams The known weight in grams (e.g. 1000).
   * @return Nothing.
   */
  void calibrate(float grams) {
    if (grams <= 0) { Serial.println(F("Give the weight in grams, e.g.  c 1000")); return; }
    Serial.print(F("Calibrating with "));
    Serial.print(grams, 0);
    Serial.println(F(" g: keep it still..."));
    const float counts = settleAndAverage(2000);
    const float delta = counts - cal.zeroCounts;
    if (delta < 5) {
      Serial.println(F("Change is too small: tare first with the empty basket, or swap the green and white wires if the reading drops."));
      return;
    }
    cal.countsPerKg = delta / (grams / 1000.0);
    saveCalibration();
    Serial.print(F("Slope = "));
    Serial.print(cal.countsPerKg, 2);
    Serial.println(F(" counts/kg. Saved."));
    printSettings();
  }

  /**
   * Prints the settings and the cell sensitivity worked out from the calibration.
   * @return Nothing.
   */
  void printSettings() {
    const float voltsPerKg = countsToVolts(cal.countsPerKg);
    const float bridgeMvPerKg = voltsPerKg / GAIN * 1000.0;
    const float mvPerV = bridgeMvPerKg * CELL_CAPACITY_KG / EXCITATION;
    Serial.println(F("------------------------------------------------"));
    Serial.print(F("Gain (RG 180 ohm): ")); Serial.println(GAIN, 1);
    Serial.print(F("Zero: ")); Serial.print(cal.zeroCounts, 1); Serial.print(F(" counts = ")); Serial.print(countsToVolts(cal.zeroCounts), 3); Serial.println(F(" V"));
    Serial.print(F("Slope: ")); Serial.print(cal.countsPerKg, 2); Serial.print(F(" counts/kg = ")); Serial.print(voltsPerKg, 3); Serial.println(F(" V/kg at A0"));
    Serial.print(F("Resolution: ")); Serial.print(1000.0 / cal.countsPerKg, 1); Serial.println(F(" g per ADC count (before averaging)"));
    Serial.print(F("Cell sensitivity: ")); Serial.print(mvPerV, 2); Serial.println(cal.magic == CAL_MAGIC ? F(" mV/V (measured)") : F(" mV/V (default, not calibrated)"));
    Serial.println(F("------------------------------------------------"));
  }

  /**
   * Checks the output stays inside the AD620's usable range and explains what is wrong if not.
   * @param volts Voltage at A0.
   * @return Nothing.
   */
  void checkRange(float volts) {
    if (volts < OUT_MIN_V) Serial.print(F("   << LOW: check REF (1.56 V at AD620 pin 5), the LM358, or green/white swapped"));
    else if (volts > OUT_MAX_V) Serial.print(F("   << HIGH: output saturated: overload, or a bridge wire is loose"));
  }

  /**
   * Reads one command line from the Serial Monitor and runs it.
   * @return Nothing.
   */
  void handleSerial() {
    if (!Serial.available()) return;
    String line = Serial.readStringUntil('\n');
    line.trim();
    if (line.length() == 0) return;
    const char cmd = tolower(line.charAt(0));
    if (cmd == 't') tare();
    else if (cmd == 'c') calibrate(line.substring(1).toFloat());
    else if (cmd == 's') printSettings();
    else if (cmd == 'r') showRaw = !showRaw;
    else if (cmd == 'x') { cal.magic = 0; EEPROM.put(0, cal); loadCalibration(); Serial.println(F("Calibration cleared (defaults).")); }
    else Serial.println(F("Commands: t | c <grams> | s | r | x"));
  }

  /**
   * Prints one line of readings.
   * @return Nothing.
   */
  void printReading() {
    const float volts = countsToVolts(filtered);
    const float dV = volts - countsToVolts(cal.zeroCounts);
    if (showRaw) {
      Serial.print(F("raw ")); Serial.print(filtered, 1);
      Serial.print(F("   A0 ")); Serial.print(volts, 3); Serial.print(F(" V"));
      Serial.print(F("   dV ")); Serial.print(dV >= 0 ? F("+") : F("")); Serial.print(dV, 3);
      Serial.print(F("   bridge ")); Serial.print(dV / GAIN * 1000.0, 2); Serial.print(F(" mV   "));
    }
    Serial.print(F("weight ")); Serial.print(weightKg(), 3); Serial.print(F(" kg"));
    checkRange(volts);
    Serial.println();
  }

  /**
   * Settles the input and loads (or creates) the calibration, then prints the settings.
   * @return Nothing.
   */
  void begin() {
    filtered = readCountsAveraged();
    settleAndAverage(800);
    if (loadCalibration()) Serial.println(F("Saved calibration loaded."));
    else Serial.println(F("No calibration yet: using 1 mV/V defaults. Empty basket -> type t, then a known weight -> c <grams>."));
    printSettings();
  }

  /**
   * Takes one oversampled reading into the smoothing filter. Call every loop.
   * @return Nothing.
   */
  void update() {
    filtered += FILTER_ALPHA * (readCountsAveraged() - filtered);
  }
}

// =====================================================================================
// Main sketch
// =====================================================================================
const uint16_t STATUS_MS = 250;                  // one status line every 250 ms
unsigned long lastStatusMs = 0;

/**
 * Prints one combined line: IR state, then the load cell reading.
 * @return Nothing.
 */
void printStatus() {
  Serial.print(F("IR: "));
  Serial.print(load_ir_detection::statusText());
  Serial.print(load_ir_detection::detected() ? F("        | ") : F("   | "));
  load_cell_with_conditioning::printReading();
}

/**
 * Starts serial and both sensor modules.
 * @return Nothing.
 */
void setup() {
  Serial.begin(115200);
  analogReference(DEFAULT);
  Serial.println(F("\nCrane Overload - Milestone 1: IR top detection + load cell (AD620)"));
  load_ir_detection::begin();
  load_cell_with_conditioning::begin();
}

/**
 * Updates both sensors, handles load cell commands, prints a status line every STATUS_MS,
 * and prints IR changes immediately.
 * @return Nothing.
 */
void loop() {
  if (load_ir_detection::update()) {
    Serial.print(F(">> IR changed: "));
    Serial.println(load_ir_detection::statusText());
  }
  load_cell_with_conditioning::update();
  load_cell_with_conditioning::handleSerial();
  if (millis() - lastStatusMs >= STATUS_MS) {
    lastStatusMs = millis();
    printStatus();
  }
}
