/**
 * @file bench_test.ino
 * @brief Prints raw sensor values every 250 ms for steps C, E, L, N and Q.
 *
 * Open the Serial Monitor at 115200 baud.
 *   A0   load cell amplifier output (expect ~0.42 V with an empty hook)
 *   A1   ACS712 output (expect ~2.50 V with the motor off)
 *   A2   limit switch (1 = released, 0 = pressed)
 *   ENC  encoder count on D2/D3 (one drum turn = 2400 counts for 600 P/R)
 *   ERR  invalid quadrature transitions (should stay 0)
 */
const uint8_t PIN_LOAD = A0;
const uint8_t PIN_CURRENT = A1;
const uint8_t PIN_LIMIT = A2;
const uint8_t PIN_ENC_A = 2;
const uint8_t PIN_ENC_B = 3;

const int8_t QDEC[16] = {0, +1, -1, 0, -1, 0, 0, +1, +1, 0, 0, -1, 0, -1, +1, 0};
volatile int32_t encCount = 0;
volatile uint16_t encErrors = 0;
volatile uint8_t encPrev = 0;

/**
 * Quadrature x4 decoder for both encoder channels (same as the main firmware).
 * @return void
 */
void encoderIsr() {
  uint8_t s = (PIND >> 2) & 0x03;
  int8_t d = QDEC[(encPrev << 2) | s];
  if (d) encCount += d;
  else if (s != encPrev) encErrors++;
  encPrev = s;
}

/**
 * Converts ADC counts to volts with the 5 V reference.
 * @param counts Raw ADC value 0-1023.
 * @return Voltage in volts.
 */
float toVolts(int counts) { return counts * 5.0f / 1024.0f; }

/**
 * Configures inputs, encoder interrupts and the serial monitor.
 * @return void
 */
void setup() {
  pinMode(PIN_LIMIT, INPUT_PULLUP);
  pinMode(PIN_ENC_A, INPUT_PULLUP);
  pinMode(PIN_ENC_B, INPUT_PULLUP);
  encPrev = (PIND >> 2) & 0x03;
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_A), encoderIsr, CHANGE);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_B), encoderIsr, CHANGE);
  Serial.begin(115200);
  Serial.println(F("A0 counts | A0 V | A1 counts | A1 V | A2 | ENC | ERR"));
}

/**
 * Prints one line of readings.
 * @return void
 */
void loop() {
  int a0 = analogRead(PIN_LOAD);
  int a1 = analogRead(PIN_CURRENT);
  noInterrupts();
  int32_t c = encCount;
  uint16_t e = encErrors;
  interrupts();
  Serial.print(a0); Serial.print(F(" | "));
  Serial.print(toVolts(a0), 3); Serial.print(F(" V | "));
  Serial.print(a1); Serial.print(F(" | "));
  Serial.print(toVolts(a1), 3); Serial.print(F(" V | "));
  Serial.print(digitalRead(PIN_LIMIT)); Serial.print(F(" | "));
  Serial.print(c); Serial.print(F(" | "));
  Serial.println(e);
  delay(250);
}
