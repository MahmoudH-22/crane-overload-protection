# crane_uno_m2: Arduino Uno firmware (milestone 2)

The Uno reads the sensors, makes **every safety decision** (overload, top of travel, what the app may do) and talks to the phone app through the HC-05. The app only shows data and sends requests the Uno may refuse.

Open `crane_uno_m2.ino` in Arduino IDE: every file below opens as a tab and is compiled together. Board: **Arduino Uno**.

---

## What each file is for

| File | What's in it |
|---|---|
| `crane_uno_m2.ino` | only `setup()` and the loop schedule (which part runs when) |
| `config.h` | **the one place to change things:** `HAS_*` flags (which parts are fitted), pins, limits, timing |
| `ir_sensor.h/.cpp` | IR top sensor (D2, 20 ms debounce, LED 13 mirrors it) |
| `load_cell.h/.cpp` | load cell + AD620 on A0: oversampling, filter, EEPROM calibration (tare, calibrate, clear) |
| `crane_state.h/.cpp` | crane state (weight, max, overload, top), overload latch every 50 ms, TOP event |
| `commands.h/.cpp` | app commands and their rules: RESET (< 95 % of max), TARE (only IDLE), SET_MAX (0.5–1.5 kg), LIFT / LOWER / GOTO refused `NOT_FITTED` until the motor exists |
| `app_link.h/.cpp` | HC-05 link (SoftwareSerial D10 / D11, 9600): sends L / A / E / S lines, reads C lines and passes them to `commands` |
| `usb_console.h/.cpp` | Serial Monitor commands (`t`, `c`, `s`, `x`, `p`) and the status line every 0.5 s |
| `crane_link.h` | the line format + checksum (shared with the old NodeMCU sketch; the app has a Dart copy, `crane_link_codec.dart`) |

Each `.h` says **what** a part offers (with a comment on every function); its `.cpp` says **how**. Other files only include the `.h`.

---

## How the parts work together

```
               every loop pass                 every 50 ms           every 200 ms / 2 s
 ir_sensor ──► crane_state.updateTop()    crane_state.safetyTick()   app_link.sendLive() / sendSensors()
 load_cell ──► update() (filter)     ───► weight, overload latch ───►  L line / S line ──► HC-05 ──► app
                                                    ▲
 app ──► HC-05 ──► app_link.poll() ──► commands.handle() ── RESET / TARE / SET_MAX ──► A ack + E event lines
 USB ──► usb_console.poll() (t c s x p)        every 0.5 s: usb_console.printStatus()
```

Nothing waits (`delay`) in the loop, so a command from the app is handled within a few milliseconds. Only the USB calibration commands `t` and `c` block for 1.5–2 s on purpose (averaging for an accurate zero / slope).

---

## Lines sent to and received from the app (`crane_link.h`)

| Line | Direction | Example | Meaning |
|---|---|---|---|
| `L` | Uno → app, 200 ms | `L,123456,0.512,1.50,,,0,IDLE,REMOTE,NONE,,0*3C` | live: time, kg, max, height, current, top, state, mode, source, ultrasonic, obstacle (empty = not fitted) |
| `S` | Uno → app, 2 s | `S,kg top` | fitted sensors (from the `HAS_*` flags) |
| `E` | Uno → app | `E,1001,TARE,0.000` | event: OVERLOAD, OVERLOAD_CLEARED, TOP, RESET, TARE, MAX_CHANGED |
| `A` | Uno → app | `A,42,0,BUSY` | reply to a command: ok 1/0 + reason |
| `C` | app → Uno | `C,42,TARE` / `C,7,SET_MAX,1.200` | command (PING every 1 s keeps the link alive) |

`*XX` at the end = XOR checksum in hex; a line with a wrong checksum is dropped.

---

## Serial Monitor (115200 baud, line ending "Newline")

| Type | Does |
|---|---|
| `t` | tare: zero with the basket empty (saved) |
| `c 1000` | calibrate with a known weight in grams (saved) |
| `s` | show the calibration and the cell sensitivity (mV/V) |
| `x` | clear the calibration |
| `p` | status line on / off |

Status line: `kg 0.512  max 1.50  IR clear  st IDLE  link ok/bad 125/0  app yes`

---

## Adding the next part (motor, encoder, current, ultrasonic)

1. Add a pair `motor.h` / `motor.cpp` (or `encoder.*`, …) with a `begin()` and an `update()`, like `ir_sensor.*`.
2. Put its pins in `config.h` and set its flag (`HAS_MOTOR 1`).
3. Call it from `setup()` / `loop()` in `crane_uno_m2.ino`.
4. Put its safety rules in `crane_state.cpp` (automatic stops) or `commands.cpp` (accept / refuse commands).
5. Fill its field in `app_link.cpp` `sendLive()`. `sendSensors()` already reports it from the flag, and the app enables the matching card / buttons by itself.

---

## Related
- Wiring and why each connection is made: `docs/exp/` (`01-overview-power-and-pins.md`, `02-hc05-bluetooth.md`, `03-ir-top-sensor.md`, `04-load-cell-ad620.md`).
- HC-05 not found / no answer: `firmware/uno/hc05_setup/`.
- Full message contract: `CLAUDE.md`.
