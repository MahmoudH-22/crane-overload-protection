/**
 * @file i2c_scanner.ino
 * @brief Finds the LCD backpack address (usually 0x27 or 0x3F). Step C.
 */
#include <Wire.h>

/**
 * Starts I2C and the serial monitor.
 * @return void
 */
void setup() {
  Wire.begin();
  Serial.begin(115200);
  Serial.println(F("I2C scanner"));
}

/**
 * Probes every 7-bit address and prints the ones that answer.
 * @return void
 */
void loop() {
  uint8_t found = 0;
  for (uint8_t addr = 1; addr < 127; addr++) {
    Wire.beginTransmission(addr);
    if (Wire.endTransmission() == 0) {
      Serial.print(F("device at 0x"));
      if (addr < 16) Serial.print('0');
      Serial.println(addr, HEX);
      found++;
    }
  }
  if (!found) Serial.println(F("nothing found: check SDA=A4, SCL=A5, 5V, GND"));
  delay(2000);
}
