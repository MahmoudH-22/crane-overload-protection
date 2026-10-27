# Crane Overload Protection: MCT332s sensor station

Mechatronics course project (Ain Shams, Fall 2026). A small workshop crane that weighs its load while lifting, stops itself before overload, and is monitored and controlled from a phone over MQTT.

## Stack
- **Controller:** Arduino Uno R3. All safety logic lives here.
- **Wi-Fi bridge:** NodeMCU ESP8266 (Wi-Fi + MQTT only, no decisions)
- **Messaging:** MQTT, with Mosquitto on a laptop over a phone hotspot (HiveMQ Cloud optional)
- **App:** Flutter 3.22+, Riverpod 2, mqtt_client 10, clean architecture (domain / data / presentation)
- **PCB:** KiCad 8. Uno shield with module sockets, 120 × 90 mm.
- **CAD / stress:** Fusion 360, plus hand calculations (guide calculator)

## Structure
```
firmware/uno/crane_uno/        Uno sketch: sensors, state machine, motor, LCD, serial link
firmware/nodemcu/crane_nodemcu/ NodeMCU sketch: Wi-Fi, MQTT bridge, heartbeat
firmware/tools/                i2c_scanner, bench_test
broker/mosquitto.conf          dev broker config
app/                           Flutter app (lib/features/crane/{domain,data,presentation})
hardware/                      KiCad project, Gerbers, BOM
mechanical/                    CAD, stress analysis, FEA screenshots
docs/                          report, manual/datasheet, photos, test results
history/YYYY-MM/DD-MM-YYYY.md  daily log
```

## Sensors
| Role | Part | Pin | Conversion |
|---|---|---|---|
| ON/OFF | roller micro switch (top limit) | A2, INPUT_PULLUP | pressed = LOW, 20 ms debounce |
| Direct analog | ACS712-05B | A1 | I = (counts − zero) × 4.89 mV / 185 mV |
| Conditioned | 5 kg bar load cell + INA125P | A0 | G = 4 + 60k/91 Ω ≈ 663, REF 0.42 V, RC 16 kΩ / 1 µF (9.9 Hz); if the cell is 2 mV/V use RG = 180 Ω (G ≈ 337) |
| Extra (4-student pool) | 600 P/R incremental encoder on the drum, quadrature x4 | D2/D3 (INT0/INT1), 4.7 kΩ pull-ups | 2400 counts/turn, 0.039 mm/count, homed at the top switch |

## Interfaces
- **Serial Uno ↔ NodeMCU:** 9600 baud, SoftwareSerial (Uno D10/D11, NodeMCU D5/D6, 1k/2k divider on Uno TX). Every line ends in `*XX`, an XOR checksum.
  - `D,kg,amps,top,STATE,max,flags,heightMm`: Uno → ESP every 500 ms (flags: 1 near, 2 link lost, 4 homed, 8 encoder errors)
  - `E,reason`: Uno → ESP, rejected command
  - `H`: ESP → Uno heartbeat, every 1 s
  - `C,UP|DOWN|STOP|RESET|TARE`, `C,MAX,v`, `C,CAL,v`: ESP → Uno commands
- **MQTT topics:**
  - `crane/live`: JSON, retained
  - `crane/cmd`: JSON, QoS 1
  - `crane/status`: Last Will, retained online/offline
  - `crane/events`: alarms and rejections

## Safety rules (Uno, 20 Hz)
- E-stop: cuts the motor in hardware; the Uno can optionally sense it on D3.
- Overload: weight > max for 3 readings → stop, latch, lower only. Reset is accepted only at ≤ 95% of max.
- Near limit: ≥ 90% → yellow warning.
- Top limit: switch pressed → no lifting.
- Jam: current > 1.5 A for 0.3 s while lifting, **or** the encoder sees < 3 mm/s for 0.4 s while driven → latch.
- Link loss: no heartbeat for 2 s while moving → stop.
- Top slow zone: within 20 mm of the top switch, PWM is capped at about 43%.
- Lowering stops at the 5 mm soft bottom limit (once homed), when the load lands, or after 15 s.

## Conventions
- Doc comment before every function (Doxygen `/** */` in C++, `///` in Dart): purpose, params, return.
- Firmware is non-blocking. Use `millis()` timers and never `delay()` in `loop()`.
- Feature flags at the top of `crane_uno.ino` (`HAS_LOAD_CELL`, `HAS_CURRENT`, `HAS_ENCODER`, `USE_ESTOP_SENSE`) enable sensors as they are wired.
- The encoder ISR uses a 16-entry quadrature state table. Read the count only with interrupts disabled.
- `RATED_MAX_KG` (firmware) and `kRatedMaxKg` (app) must equal the stress-analysis rated load.
- Update this file and today's `history/` file after any significant work.

## Key decisions
- Uno + NodeMCU instead of an ESP32: safety stays separate from Wi-Fi, which is a strong point for the oral.
- INA125P amplifier, designed by the team; no HX711, so the conditioning marks are protected.
- REF = 0.42 V, not 0.15 V, because the INA125 output on a single 5 V supply can't go below about 0.3 V.
- Worm gear motor, so the load can't fall when the power is cut.
- Soft start (0.5 s PWM ramp) prevents false overloads at lift-off.
- The bridge, REF divider, ACS712 and ADC reference share the same 5 V, so readings are ratiometric.
- Tare is not done at boot. It's done from the app with an empty hook, so a load hanging at power-up can't be zeroed out.
- Rated load is 2.0 kg, governed by tipping with the default dimensions. Re-check it with the real frame.
- 4-student extra requirement: the 4th sensor is an incremental encoder (from the course sensor pool), used in quadrature mode to measure hook position. It needs D2/D3 (the only external interrupts), so the limit switch moved to A2 and the E-stop sense to A3.
- The encoder is coupled to the drum's free end, not the pulley, so there is no rope slip.
- SoftwareSerial is kept: at the max drum speed, edges on one pin are about 1.7 ms apart, which is longer than the 1.04 ms SoftwareSerial blocks for one byte, and the INT flags latch one pending edge. Switch to hardware Serial with an upload jumper if T3.14 shows errors.
