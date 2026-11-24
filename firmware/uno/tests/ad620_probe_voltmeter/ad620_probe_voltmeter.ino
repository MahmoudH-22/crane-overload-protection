/**
 * @file ad620_probe_voltmeter.ino
 * @brief Uses the Uno's analog pins as a 6-channel voltmeter (0-5 V) to debug the AD620 load cell circuit.
 *
 * Keep A0 on the filter output as before, and add jumper wires:
 *   A1 -> AD620 pin 6 (OUT, before the 16 k resistor)   expect 1.1-2.1 V
 *   A2 -> AD620 pin 5 (REF)                             expect 1.56 V
 *   A3 -> LM358 pin 3 (divider middle)                  expect 1.56 V
 *   A4 -> AD620 pin 3 (green, S+)                       expect 2.5 V
 *   A5 -> AD620 pin 2 (white, S-)                       expect 2.5 V
 * Never connect an analog pin to anything above 5 V (e.g. the 12 V motor supply).
 * Serial Monitor at 115200 baud.
 */

const uint8_t PINS[] = {A0, A1, A2, A3, A4, A5};
const char *const NAMES[] = {"A0 filter out", "A1 AD620 p6 OUT", "A2 AD620 p5 REF", "A3 LM358 p3 div", "A4 AD620 p3 S+", "A5 AD620 p2 S-"};
const float EXPECT_LO[] = {1.0, 1.0, 1.45, 1.45, 2.3, 2.3};
const float EXPECT_HI[] = {2.2, 2.2, 1.65, 1.65, 2.7, 2.7};
const uint8_t N_PINS = 6;
const uint8_t OVERSAMPLE = 32;

/**
 * Reads one analog pin several times and returns the average voltage.
 * @param pin Analog pin (A0..A5).
 * @return Volts (0..5).
 */
float readVolts(uint8_t pin) {
  analogRead(pin);                      // first reading after switching channels is discarded
  uint32_t sum = 0;
  for (uint8_t i = 0; i < OVERSAMPLE; i++) sum += analogRead(pin);
  return (sum / (float)OVERSAMPLE) * 5.0 / 1023.0;
}

/**
 * Starts serial and prints the probe map.
 * @return Nothing.
 */
void setup() {
  Serial.begin(115200);
  Serial.println(F("\nAD620 circuit probe (Uno as a voltmeter)"));
  Serial.println(F("A0 filter out | A1 AD620 p6 | A2 AD620 p5 REF | A3 LM358 p3 | A4 AD620 p3 green | A5 AD620 p2 white"));
}

/**
 * Prints all six voltages with OK / CHECK, twice a second.
 * @return Nothing.
 */
void loop() {
  for (uint8_t i = 0; i < N_PINS; i++) {
    const float v = readVolts(PINS[i]);
    Serial.print(NAMES[i]);
    Serial.print(F(": "));
    Serial.print(v, 2);
    Serial.print(F(" V "));
    Serial.print(v >= EXPECT_LO[i] && v <= EXPECT_HI[i] ? F("OK") : F("CHECK"));
    Serial.print(i < N_PINS - 1 ? F("  |  ") : F("\n"));
  }
  delay(500);
}
