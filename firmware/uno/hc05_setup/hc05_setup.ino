/**
 * @file hc05_at_setup.ino
 * @brief One-off helper: talk to the HC-05 in AT mode through the Uno to reset it to a discoverable slave at 9600.
 *
 * Wiring: the same as the crane (HC-05 TXD -> D10, Uno D11 -> 1 k -> HC-05 RXD with 2 k to GND, VCC 5V, GND).
 *
 * How to use
 *   1. Upload this sketch. Unplug the Uno USB.
 *   2. Hold the HC-05 button, plug the USB back in, release after ~2 s.
 *      The LED should now blink SLOWLY (on ~1 s, off ~1 s) = AT mode.
 *   3. Serial Monitor: 9600 baud, line ending "Both NL & CR".
 *      At start the sketch tries AT at 38400, 9600, 19200, 57600 and keeps the speed that answers OK.
 *      Type  ?  to scan again. On fast-blink modules you can also HOLD the button while a command is sent.
 *   4. Type the commands one by one:
 *        AT                    -> OK
 *        AT+ORGL               -> OK            factory defaults (slave, PIN 1234)
 *        AT+ROLE=0             -> OK            slave = discoverable by the phone
 *        AT+UART=9600,0,0      -> OK            data-mode baud used by the crane sketch
 *        AT+NAME=HC-05         -> OK
 *        AT+ROLE?  AT+UART?  AT+PSWD?            check
 *   5. Upload crane_uno_m2 again, power-cycle WITHOUT holding the button: fast blink, now pairable.
 */
#include <SoftwareSerial.h>

/** Link to the HC-05: RX = D10 (from HC-05 TXD), TX = D11 (to HC-05 RXD via divider). */
SoftwareSerial bt(10, 11);

/** Speeds tried, AT-mode default first. */
const long BAUDS[] = {38400, 9600, 19200, 57600};

/** Speed in use (0 = none answered). */
long current = 0;

/**
 * Sends "AT" at one speed and waits for "OK".
 * @param baud Speed to try.
 * @return true when the module answered OK.
 */
bool tryBaud(long baud) {
  bt.end();
  bt.begin(baud);
  delay(50);
  while (bt.available()) bt.read();  // drop noise
  bt.print(F("AT\r\n"));
  String reply;
  const unsigned long start = millis();
  while (millis() - start < 600) {
    while (bt.available()) reply += (char)bt.read();
  }
  reply.trim();
  Serial.print(F("  ")); Serial.print(baud); Serial.print(F(" baud -> "));
  Serial.println(reply.length() ? reply : String(F("(no reply)")));
  return reply.indexOf(F("OK")) >= 0;
}

/**
 * Tries every speed in BAUDS and keeps the first that answers; prints what to check if none does.
 * @return Nothing.
 */
void scan() {
  Serial.println(F("Trying AT at each speed..."));
  current = 0;
  for (long b : BAUDS) {
    if (tryBaud(b)) { current = b; break; }
  }
  if (current) {
    Serial.print(F("HC-05 answers at ")); Serial.print(current);
    Serial.println(F(" baud. Type your AT commands now."));
  } else {
    bt.begin(38400);
    Serial.println(F("No answer at any speed. Check: LED blinking SLOWLY (AT mode)? HC-05 TXD -> D10?"));
    Serial.println(F("Uno D11 -> 1k -> HC-05 RXD (2k to GND)? Common GND? Then type ? to try again."));
  }
}

/**
 * Starts USB serial (9600) and looks for the HC-05.
 * @return Nothing.
 */
void setup() {
  Serial.begin(9600);
  delay(300);
  Serial.println(F("\nHC-05 AT helper. Line ending: Both NL & CR. Type ? to scan again."));
  scan();
}

/** Line typed in the Serial Monitor, sent to the HC-05 when Enter arrives. */
String line;

/**
 * Sends whole typed lines to the HC-05 (with CR LF) and echoes them; a line that is only "?" re-runs the scan.
 * Commands such as AT+ROLE? contain '?' and are sent normally. Replies are copied back to the Serial Monitor.
 * @return Nothing.
 */
void loop() {
  while (Serial.available()) {
    const char c = Serial.read();
    if (c == '\r') continue;
    if (c != '\n') { line += c; continue; }
    line.trim();
    if (line == "?") {
      scan();
    } else if (line.length()) {
      Serial.print(F("> ")); Serial.println(line);
      bt.print(line);
      bt.print(F("\r\n"));
    }
    line = "";
  }
  if (bt.available()) Serial.write(bt.read());
}
