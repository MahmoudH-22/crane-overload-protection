/**
 * @file crane_uno.ino
 * @brief Crane overload protection: Arduino Uno safety controller.
 *
 * Reads the load cell (A0, through the INA125 + RC filter), the ACS712 (A1),
 * the top limit switch (A2) and the drum's incremental encoder in quadrature
 * mode (D2/D3, interrupts) for hook position. Runs the safety state machine, drives the
 * L298N, the 16x2 I2C LCD, the LEDs and the buzzer, and talks to the NodeMCU
 * over SoftwareSerial using checksummed text lines.
 *
 * Libraries: LiquidCrystal_I2C (Frank de Brabander), plus the built-in
 * Wire, SoftwareSerial and EEPROM.
 *
 * Serial protocol (9600 baud, every line ends with *XX = XOR checksum):
 *   Uno  -> ESP : D,<kg>,<amps>,<top 0|1>,<STATE>,<maxKg>,<flags>,<heightMm>   every 500 ms
 *                 flags bit0 = near limit, bit1 = link lost, bit2 = homed,
 *                 bit3 = encoder errors seen; heightMm = -1 until homed
 *   Uno  -> ESP : E,<reason>                                        rejected command
 *   ESP  -> Uno : H                                                 heartbeat, every 1 s
 *   ESP  -> Uno : C,UP | C,DOWN | C,STOP | C,RESET | C,TARE
 *                 C,MAX,<kg> | C,CAL,<known kg>
 */
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <SoftwareSerial.h>
#include <EEPROM.h>

// ============================================================ build flags
// Turn sensors on as you wire them (implementation steps F, L, N, Q).
#define HAS_LOAD_CELL 1   // 0 until the INA125 circuit is connected to A0
#define HAS_CURRENT   1   // 0 until the ACS712 is connected to A1
#define HAS_ENCODER   1   // 0 until the drum encoder is connected to D2/D3
#define USE_ESTOP_SENSE 0 // 1 if the E-stop's NO contact is wired to A3
#define LCD_ADDRESS 0x27  // 0x3F on some backpacks (use the I2C scanner)

// ============================================================ pins
const uint8_t PIN_LOAD        = A0;
const uint8_t PIN_CURRENT     = A1;
const uint8_t PIN_LIMIT       = A2;  // moved from D2: D2/D3 are the only interrupt pins
const uint8_t PIN_ESTOP_SENSE = A3;
const uint8_t PIN_ENC_A       = 2;   // INT0, encoder channel A (4.7k pull-up)
const uint8_t PIN_ENC_B       = 3;   // INT1, encoder channel B (4.7k pull-up)
const uint8_t PIN_BUZZER      = 4;
const uint8_t PIN_ENA         = 5;   // PWM, about 980 Hz
const uint8_t PIN_LED_G       = 6;
const uint8_t PIN_IN1         = 7;
const uint8_t PIN_IN2         = 8;
const uint8_t PIN_LED_Y       = 9;
const uint8_t PIN_LINK_RX     = 10;  // from NodeMCU D6 (TX)
const uint8_t PIN_LINK_TX     = 11;  // to NodeMCU D5 (RX) through the 1k/2k divider
const uint8_t PIN_LED_R       = 12;

// ============================================================ tuning
const float    RATED_MAX_KG     = 2.0f;   // from the stress analysis: never above this
const float    NEAR_LIMIT_RATIO = 0.90f;  // yellow warning
const float    RESET_RATIO      = 0.95f;  // overload reset allowed below this
const uint8_t  OVERLOAD_CONFIRM = 3;      // readings in a row (3 x 50 ms)
const float    JAM_AMPS         = 1.5f;
const uint16_t JAM_MS           = 300;
const uint16_t LINK_TIMEOUT_MS  = 2000;
const uint16_t RAMP_MS          = 500;    // soft start 0 -> full in 0.5 s
const uint8_t  PWM_MAX          = 255;
const float    LOADED_KG        = 0.20f;  // above this the hook is "carrying"
const float    LANDED_KG        = 0.03f;  // below this after carrying = load landed
const uint32_t LOWER_TIMEOUT_MS = 15000;  // no bottom switch: stop lowering after 15 s
const float    ACS_V_PER_A      = 0.185f; // ACS712-05B
const float    ADC_V_PER_COUNT  = 5.0f / 1024.0f;

// encoder (600 P/R, quadrature x4 = 2400 counts per drum turn)
const uint16_t ENC_CPR        = 2400;
const float    DRUM_RADIUS_MM = 15.0f;
const float    MM_PER_COUNT   = 6.2831853f * DRUM_RADIUS_MM / ENC_CPR;  // ~0.039 mm
const int8_t   ENC_SIGN       = +1;      // set to -1 if lifting makes the count go down
const float    TOP_HEIGHT_MM  = 250.0f;  // hook height when the top switch trips
const float    BOTTOM_MM      = 5.0f;    // soft bottom limit
const float    SLOW_ZONE_MM   = 20.0f;   // slow down this close to the top switch
const uint8_t  PWM_SLOW       = 110;     // ~43% duty in the slow zone
const float    STALL_MM_S     = 3.0f;    // below this while driven = not moving
const uint16_t STALL_MS       = 400;

const uint16_t T_SAFETY = 50;   // ms
const uint16_t T_LCD    = 200;
const uint16_t T_REPORT = 500;

// ============================================================ types
enum State : uint8_t { IDLE, LIFTING, LOWERING, AT_TOP, OVERLOAD, JAM, E_STOP };
const char* const STATE_NAMES[] = {"IDLE", "LIFTING", "LOWERING", "AT_TOP", "OVERLOAD", "JAM", "E_STOP"};

/** Calibration and settings kept in EEPROM. */
struct Config {
  uint16_t magic;
  float tareCounts;   // ADC counts with an empty hook
  float kgPerCount;   // calibration slope
  float maxKg;        // overload limit (<= RATED_MAX_KG)
};
const uint16_t CFG_MAGIC = 0xC7A1;
const int CFG_ADDR = 0;

// ============================================================ globals
LiquidCrystal_I2C lcd(LCD_ADDRESS, 16, 2);
SoftwareSerial link(PIN_LINK_RX, PIN_LINK_TX);

Config cfg;
State state = IDLE;
float kg = 0, amps = 0, acsZeroCounts = 512;
float kgBuf[5] = {0, 0, 0, 0, 0};
uint8_t kgIdx = 0;
bool atTop = false, estop = false, nearLimit = false, linkLost = true, hadLoad = false;
uint8_t overCount = 0;
uint16_t jamMs = 0;
int8_t motorDir = 0;              // +1 lift, -1 lower, 0 stop
uint8_t pwm = 0;
uint32_t lastHeartbeat = 0, moveStartMs = 0;

// encoder: written by the ISR, read with interrupts off
volatile int32_t encCount = 0;
volatile uint16_t encErrors = 0;
volatile uint8_t encPrev = 0;
int32_t encLast = 0, countAtTop = 0;
float heightMm = -1, speedMmS = 0;
bool homed = false, wasTop = false;
uint16_t stallMs = 0;
uint32_t tSafety = 0, tLcd = 0, tReport = 0;

// limit switch debounce
bool limitStable = false, limitRaw = false;
uint32_t limitChangedMs = 0;

// serial line buffer
char lineBuf[48];
uint8_t lineLen = 0;

// ============================================================ config
/**
 * Loads calibration from EEPROM, or writes safe defaults the first time.
 * @return void
 */
void loadConfig() {
  EEPROM.get(CFG_ADDR, cfg);
  if (cfg.magic != CFG_MAGIC || !(cfg.kgPerCount > 0) || !(cfg.maxKg > 0)) {
    cfg.magic = CFG_MAGIC;
    cfg.tareCounts = 86.0f;           // 0.42 V reference
    cfg.kgPerCount = 1.0f / 135.8f;   // design value, replace by calibration
    cfg.maxKg = RATED_MAX_KG;
    EEPROM.put(CFG_ADDR, cfg);
  }
  if (cfg.maxKg > RATED_MAX_KG) cfg.maxKg = RATED_MAX_KG;
}

/**
 * Saves the current calibration and settings to EEPROM.
 * @return void
 */
void saveConfig() { EEPROM.put(CFG_ADDR, cfg); }

// ============================================================ sensors
/**
 * Averages several ADC readings of one pin.
 * @param pin Analog pin.
 * @param n Number of samples.
 * @return Average in ADC counts (0-1023).
 */
float readAdcAverage(uint8_t pin, uint8_t n) {
  uint32_t sum = 0;
  for (uint8_t i = 0; i < n; i++) sum += analogRead(pin);
  return (float)sum / n;
}

/**
 * Reads the load cell and returns a smoothed weight.
 * Averages 5 ADC samples, converts with the calibration, then applies
 * a moving average over the last 5 results (250 ms).
 * @return Weight on the hook in kg.
 */
float readLoadKg() {
#if HAS_LOAD_CELL
  float counts = readAdcAverage(PIN_LOAD, 5);
  float raw = (counts - cfg.tareCounts) * cfg.kgPerCount;
  kgBuf[kgIdx] = raw;
  kgIdx = (kgIdx + 1) % 5;
  float s = 0;
  for (uint8_t i = 0; i < 5; i++) s += kgBuf[i];
  return s / 5.0f;
#else
  return 0.0f;
#endif
}

/**
 * Measures the ACS712 output with the motor off and stores it as 0 A.
 * @return void
 */
void calibrateCurrentZero() {
#if HAS_CURRENT
  acsZeroCounts = readAdcAverage(PIN_CURRENT, 200);
#endif
}

/**
 * Reads the motor current from the ACS712.
 * @return Current in amps (absolute value, so both directions read positive).
 */
float readCurrentA() {
#if HAS_CURRENT
  float counts = readAdcAverage(PIN_CURRENT, 10);
  return fabs((counts - acsZeroCounts) * ADC_V_PER_COUNT / ACS_V_PER_A);
#else
  return 0.0f;
#endif
}

/**
 * Reads the top limit switch with a 20 ms debounce.
 * Wiring: COM to GND, NO to A2, INPUT_PULLUP. Pressed reads LOW.
 * @return true when the hook is at the top.
 */
bool readLimitPressed() {
  bool raw = digitalRead(PIN_LIMIT) == LOW;
  uint32_t now = millis();
  if (raw != limitRaw) { limitRaw = raw; limitChangedMs = now; }
  if (now - limitChangedMs >= 20) limitStable = limitRaw;
  return limitStable;
}

/**
 * Reads the optional E-stop sense contact (NO contact to GND, INPUT_PULLUP).
 * The E-stop's NC contact cuts the motor power in hardware either way.
 * @return true while the E-stop is pressed.
 */
bool readEstop() {
#if USE_ESTOP_SENSE
  return digitalRead(PIN_ESTOP_SENSE) == LOW;
#else
  return false;
#endif
}

// ============================================================ encoder
/**
 * Quadrature decode table indexed by (previous state << 2) | new state,
 * with state = A | (B << 1). Valid Gray-code steps give +1 / -1; "no change"
 * and impossible jumps (both channels changed = missed or noisy edge) give 0.
 */
const int8_t QDEC[16] = {0, +1, -1, 0, -1, 0, 0, +1, +1, 0, 0, -1, 0, -1, +1, 0};

/**
 * Interrupt handler for both encoder channels (x4 decoding: every edge counts).
 * Reads D2 and D3 together from PIND so A and B are sampled at the same instant.
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
 * Takes an atomic snapshot of the count and updates speed and hook height.
 * Speed uses the change over one 50 ms tick, smoothed (EMA) to soften quantization.
 * @return void
 */
void readEncoder() {
#if HAS_ENCODER
  noInterrupts();
  int32_t c = encCount;
  interrupts();
  float v = (float)((c - encLast) * ENC_SIGN) * MM_PER_COUNT * 1000.0f / T_SAFETY;
  encLast = c;
  speedMmS = 0.7f * speedMmS + 0.3f * v;
  if (homed) heightMm = TOP_HEIGHT_MM + (float)((c - countAtTop) * ENC_SIGN) * MM_PER_COUNT;
#endif
}

/**
 * Homes the position on the rising edge of the top limit switch.
 * @return void
 */
void homeOnTopSwitch() {
#if HAS_ENCODER
  if (atTop && !wasTop) {
    noInterrupts();
    countAtTop = encCount;
    interrupts();
    homed = true;
    heightMm = TOP_HEIGHT_MM;
  }
  wasTop = atTop;
#endif
}

/**
 * Tells whether the hook is within the slow zone below the top switch.
 * @return true when homed and less than SLOW_ZONE_MM below the top.
 */
bool inSlowZone() { return homed && heightMm >= TOP_HEIGHT_MM - SLOW_ZONE_MM; }

// ============================================================ motor
/**
 * Starts the motor in one direction with a soft-start ramp.
 * @param dir +1 to lift, -1 to lower.
 * @return void
 */
void motorStart(int8_t dir) {
  if (dir == motorDir) return;
  motorDir = dir;
  pwm = 0;
  analogWrite(PIN_ENA, 0);
  digitalWrite(PIN_IN1, dir > 0 ? HIGH : LOW);   // swap the motor wires if lift/lower are reversed
  digitalWrite(PIN_IN2, dir > 0 ? LOW : HIGH);
  moveStartMs = millis();
  hadLoad = false;
}

/**
 * Stops the motor immediately (no ramp down: stopping is always instant).
 * The worm gear holds the load when the motor is off.
 * @return void
 */
void motorStop() {
  motorDir = 0;
  pwm = 0;
  analogWrite(PIN_ENA, 0);
  digitalWrite(PIN_IN1, LOW);
  digitalWrite(PIN_IN2, LOW);
}

/**
 * Advances the soft-start ramp and caps the speed in the top slow zone.
 * Call once per safety tick.
 * @return void
 */
void motorUpdate() {
  if (motorDir == 0) return;
  uint8_t limit = (motorDir > 0 && inSlowZone()) ? PWM_SLOW : PWM_MAX;
  uint16_t step = (uint16_t)PWM_MAX * T_SAFETY / RAMP_MS;
  uint16_t next = (uint16_t)pwm + step;
  if (next > limit) next = limit;
  if (next != pwm) { pwm = (uint8_t)next; analogWrite(PIN_ENA, pwm); }
}

// ============================================================ link (serial)
/**
 * XOR checksum of a character range.
 * @param s Text.
 * @param n Number of characters.
 * @return 8-bit checksum.
 */
uint8_t xorSum(const char* s, size_t n) {
  uint8_t c = 0;
  for (size_t i = 0; i < n; i++) c ^= (uint8_t)s[i];
  return c;
}

/**
 * Sends one checksummed line to the NodeMCU.
 * @param body Line content without the checksum.
 * @return void
 */
void sendLine(const char* body) {
  char cs[3];
  snprintf(cs, sizeof cs, "%02X", xorSum(body, strlen(body)));
  link.print(body);
  link.print('*');
  link.print(cs);
  link.print('\n');
}

/**
 * Reports a rejected command so the app can show why.
 * @param reason Short reason code (e.g. OVERLOAD, AT_TOP).
 * @return void
 */
void reject(const char* reason) {
  char body[32];
  snprintf(body, sizeof body, "E,%s", reason);
  sendLine(body);
}

/**
 * Verifies and strips the "*XX" checksum from a received line.
 * @param line Null-terminated line; the checksum is removed in place.
 * @return true when the checksum matches.
 */
bool checkLine(char* line) {
  char* star = strrchr(line, '*');
  if (!star || strlen(star) != 3) return false;
  uint8_t want = (uint8_t)strtoul(star + 1, nullptr, 16);
  *star = '\0';
  return xorSum(line, strlen(line)) == want;
}

// ============================================================ commands
/**
 * Handles a lift request: only allowed when no alarm, not at the top, and the link is alive.
 * @return void
 */
void cmdUp() {
  if (state == OVERLOAD || state == JAM || state == E_STOP) return reject(STATE_NAMES[state]);
  if (atTop) return reject("AT_TOP");
  motorStart(+1);
  state = LIFTING;
}

/**
 * Handles a lower request: allowed in OVERLOAD so the load can be put down safely.
 * @return void
 */
void cmdDown() {
  if (state == JAM || state == E_STOP) return reject(STATE_NAMES[state]);
  motorStart(-1);
  if (state != OVERLOAD) state = LOWERING;
}

/**
 * Handles a stop request.
 * @return void
 */
void cmdStop() {
  motorStop();
  if (state == LIFTING || state == LOWERING) state = atTop ? AT_TOP : IDLE;
}

/**
 * Clears a latched alarm if its cause is gone.
 * @return void
 */
void cmdReset() {
  if (state == OVERLOAD) {
    if (kg <= RESET_RATIO * cfg.maxKg) { overCount = 0; state = IDLE; }
    else reject("STILL_OVERLOADED");
  } else if (state == JAM) {
    jamMs = 0; state = IDLE;
  } else if (state == E_STOP) {
    if (!estop) state = IDLE; else reject("ESTOP_PRESSED");
  }
}

/**
 * Sets the overload limit, clamped to the rated load.
 * @param value Requested limit in kg.
 * @return void
 */
void cmdMax(float value) {
  if (!(value > 0)) return reject("BAD_VALUE");
  cfg.maxKg = min(value, RATED_MAX_KG);
  saveConfig();
}

/**
 * Stores the current reading as 0 kg. The hook must be empty and still.
 * @return void
 */
void cmdTare() {
  if (motorDir != 0) return reject("MOVING");
  cfg.tareCounts = readAdcAverage(PIN_LOAD, 64);
  for (uint8_t i = 0; i < 5; i++) kgBuf[i] = 0;
  saveConfig();
}

/**
 * Calibrates the slope with a known weight hanging still on the hook.
 * @param knownKg The known weight in kg (e.g. 1.000).
 * @return void
 */
void cmdCal(float knownKg) {
  if (motorDir != 0) return reject("MOVING");
  float counts = readAdcAverage(PIN_LOAD, 64);
  float delta = counts - cfg.tareCounts;
  if (knownKg <= 0 || delta < 20) return reject("CAL_FAILED");
  cfg.kgPerCount = knownKg / delta;
  saveConfig();
}

/**
 * Parses one verified line from the NodeMCU and runs it.
 * Any valid line also counts as a heartbeat.
 * @param line Line without checksum, e.g. "C,MAX,2.0".
 * @return void
 */
void processLine(char* line) {
  lastHeartbeat = millis();
  if (line[0] == 'H') return;
  if (line[0] != 'C') return;
  strtok(line, ",");
  char* cmd = strtok(nullptr, ",");
  char* arg = strtok(nullptr, ",");
  if (!cmd) return;
  if (!strcmp(cmd, "UP")) cmdUp();
  else if (!strcmp(cmd, "DOWN")) cmdDown();
  else if (!strcmp(cmd, "STOP")) cmdStop();
  else if (!strcmp(cmd, "RESET")) cmdReset();
  else if (!strcmp(cmd, "TARE")) cmdTare();
  else if (!strcmp(cmd, "MAX") && arg) cmdMax(atof(arg));
  else if (!strcmp(cmd, "CAL") && arg) cmdCal(atof(arg));
  else reject("UNKNOWN");
}

/**
 * Reads incoming characters from the NodeMCU and processes complete lines.
 * @return void
 */
void readLink() {
  while (link.available()) {
    char c = link.read();
    if (c == '\n') {
      lineBuf[lineLen] = '\0';
      if (lineLen && checkLine(lineBuf)) processLine(lineBuf);
      lineLen = 0;
    } else if (c != '\r' && lineLen < sizeof(lineBuf) - 1) {
      lineBuf[lineLen++] = c;
    }
  }
}

// ============================================================ safety
/**
 * One safety tick (every 50 ms): read sensors, apply every rule, drive the motor.
 * Order matters: the most serious condition wins.
 * @return void
 */
void safetyTick() {
  uint32_t now = millis();
  kg = readLoadKg();
  amps = readCurrentA();
  atTop = readLimitPressed();
  estop = readEstop();
  readEncoder();
  homeOnTopSwitch();

  // 1. E-stop (hardware already cut the motor power; this keeps the logic in sync)
  if (estop) { motorStop(); state = E_STOP; }
  if (state == E_STOP) { motorStop(); return; }

  // 2. Overload: weight above the limit for 3 readings in a row
  if (kg > cfg.maxKg) { if (overCount < 255) overCount++; } else overCount = 0;
  if (overCount >= OVERLOAD_CONFIRM && state != OVERLOAD && state != JAM) {
    if (motorDir > 0) motorStop();     // lowering is still allowed
    state = OVERLOAD;
  }

  // 3. Jam: high current while lifting
  if (motorDir > 0 && amps > JAM_AMPS) jamMs += T_SAFETY; else jamMs = 0;
  if (jamMs >= JAM_MS) { motorStop(); state = JAM; }

  // 3b. Stall seen by the encoder: driven hard but not moving (works lifting and lowering)
#if HAS_ENCODER
  if (motorDir != 0 && pwm >= PWM_SLOW && fabs(speedMmS) < STALL_MM_S) stallMs += T_SAFETY; else stallMs = 0;
  if (stallMs >= STALL_MS && state != JAM) { motorStop(); state = JAM; }
#endif

  // 4. Top limit: never lift past the switch
  if (atTop && motorDir > 0) { motorStop(); if (state == LIFTING) state = AT_TOP; }
  if (state == AT_TOP && !atTop && motorDir == 0) state = IDLE;

  // 5. Link loss: stop any motion if the heartbeat is gone
  linkLost = (now - lastHeartbeat) > LINK_TIMEOUT_MS;
  if (linkLost && motorDir != 0) {
    motorStop();
    if (state == LIFTING || state == LOWERING) state = atTop ? AT_TOP : IDLE;
  }

  // 6. Lowering ends at the soft bottom limit (encoder), when the load lands, or after a timeout
  if (motorDir < 0) {
    if (kg > LOADED_KG) hadLoad = true;
    bool landed = hadLoad && kg < LANDED_KG;
    bool atBottom = homed && heightMm <= BOTTOM_MM;
    if (atBottom || landed || now - moveStartMs > LOWER_TIMEOUT_MS) {
      motorStop();
      if (state == LOWERING) state = IDLE;
    }
  }

  nearLimit = (state != OVERLOAD) && kg >= NEAR_LIMIT_RATIO * cfg.maxKg;
  motorUpdate();
}

// ============================================================ outputs
/**
 * Writes one LCD row padded to 16 characters (overwrites old text without clearing).
 * @param row 0 or 1.
 * @param text Up to 16 characters.
 * @return void
 */
void lcdLine(uint8_t row, const char* text) {
  char buf[17];
  snprintf(buf, sizeof buf, "%-16s", text);
  lcd.setCursor(0, row);
  lcd.print(buf);
}

/**
 * Updates the LCD with labels, units and status words for the current state.
 * @return void
 */
void updateLcd() {
  char a[17], b[17], k[8], m[8], i[8];
  float shownKg = kg < 0 ? 0 : kg;
  dtostrf(shownKg, 5, 2, k);
  dtostrf(cfg.maxKg, 4, 2, m);
  dtostrf(amps, 4, 2, i);
  switch (state) {
    case E_STOP:   snprintf(a, sizeof a, "!! E-STOP !!");  snprintf(b, sizeof b, "RELEASE + RESET"); break;
    case OVERLOAD: snprintf(a, sizeof a, "!! OVERLOAD !!"); snprintf(b, sizeof b, "%skg>%skg", k, m); break;
    case JAM:      snprintf(a, sizeof a, "!! MOTOR JAM !!"); snprintf(b, sizeof b, "I:%sA  RESET", i); break;
    case AT_TOP:   snprintf(a, sizeof a, "HOOK AT TOP");    snprintf(b, sizeof b, "LOWER ONLY"); break;
    default: {
      int pct = (int)(100.0f * shownKg / cfg.maxKg + 0.5f);
      snprintf(a, sizeof a, "LOAD:%skg %s", k, nearLimit ? "!!" : "OK");
      if (linkLost && motorDir == 0) snprintf(b, sizeof b, "WIFI LOST");
      else if (nearLimit) snprintf(b, sizeof b, "NEAR LIMIT %d%%", pct);
      else if (homed) snprintf(b, sizeof b, "H:%3dmm I:%sA", (int)(heightMm + 0.5f), i);
      else snprintf(b, sizeof b, "%s I:%sA", motorDir > 0 ? "LIFT" : motorDir < 0 ? "LOWR" : "IDLE", i);
    }
  }
  lcdLine(0, a);
  lcdLine(1, b);
}

/**
 * Sets the LEDs and buzzer: green normal, yellow warning, red + beep for latched alarms.
 * @return void
 */
void updateIndicators() {
  bool alarm = state == OVERLOAD || state == JAM || state == E_STOP;
  bool blink = (millis() / 250) % 2;
  digitalWrite(PIN_LED_G, !alarm && !nearLimit && !linkLost);
  digitalWrite(PIN_LED_Y, !alarm && (nearLimit || state == AT_TOP || linkLost));
  digitalWrite(PIN_LED_R, alarm && blink);
  digitalWrite(PIN_BUZZER, (state == OVERLOAD || state == JAM) && blink);
}

/**
 * Sends the telemetry line to the NodeMCU.
 * @return void
 */
void sendReport() {
  char k[10], a[8], m[8], h[10], body[72];
  dtostrf(kg < 0 ? 0 : kg, 1, 2, k);
  dtostrf(amps, 1, 2, a);
  dtostrf(cfg.maxKg, 1, 2, m);
  dtostrf(homed ? heightMm : -1.0f, 1, 1, h);
  noInterrupts();
  bool encErr = encErrors > 0;
  interrupts();
  uint8_t flags = (nearLimit ? 1 : 0) | (linkLost ? 2 : 0) | (homed ? 4 : 0) | (encErr ? 8 : 0);
  snprintf(body, sizeof body, "D,%s,%s,%d,%s,%s,%d,%s", k, a, atTop ? 1 : 0, STATE_NAMES[state], m, flags, h);
  sendLine(body);
}

// ============================================================ main
/**
 * Configures pins, the LCD, the serial link and calibration.
 * The motor must be off here so the ACS712 zero is correct.
 * @return void
 */
void setup() {
  pinMode(PIN_LIMIT, INPUT_PULLUP);
  pinMode(PIN_ESTOP_SENSE, INPUT_PULLUP);
  pinMode(PIN_BUZZER, OUTPUT);
  pinMode(PIN_ENA, OUTPUT);
  pinMode(PIN_IN1, OUTPUT);
  pinMode(PIN_IN2, OUTPUT);
  pinMode(PIN_LED_G, OUTPUT);
  pinMode(PIN_LED_Y, OUTPUT);
  pinMode(PIN_LED_R, OUTPUT);
  motorStop();
#if HAS_ENCODER
  pinMode(PIN_ENC_A, INPUT_PULLUP);   // plus external 4.7k to 5 V (open-collector outputs)
  pinMode(PIN_ENC_B, INPUT_PULLUP);
  encPrev = (PIND >> 2) & 0x03;
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_A), encoderIsr, CHANGE);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_B), encoderIsr, CHANGE);
#endif

  Serial.begin(115200);   // USB debug
  link.begin(9600);
  lcd.init();             // some library versions use lcd.begin() instead
  lcd.backlight();
  lcdLine(0, "CRANE-OPS v1.0");
  lcdLine(1, "starting...");

  loadConfig();
  delay(300);             // let the analog supplies settle (setup only)
  calibrateCurrentZero();
  for (uint8_t i = 0; i < 5; i++) readLoadKg();   // fill the moving average
  Serial.println(F("crane_uno ready"));
}

/**
 * Non-blocking scheduler: each task runs when its millis() timer is due.
 * @return void
 */
void loop() {
  readLink();
  uint32_t now = millis();
  if (now - tSafety >= T_SAFETY) { tSafety = now; safetyTick(); updateIndicators(); }
  if (now - tLcd >= T_LCD)       { tLcd = now; updateLcd(); }
  if (now - tReport >= T_REPORT) { tReport = now; sendReport(); }
}
