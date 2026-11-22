# Wiring overview: power, ground and the Uno pin map

This is the starting point for the crane's wiring. Each part has its own explanation file:

| File | Part |
|---|---|
| `01-overview-power-and-pins.md` | this file: power, ground, which pin does what, and why |
| `02-hc05-bluetooth.md` | HC-05 Bluetooth link to the phone app (D10 / D11 + voltage divider) |
| `03-ir-top-sensor.md` | IR top-of-travel sensor (D2) |
| `04-load-cell-ad620.md` | load cell + AD620 amplifier + LM358 reference + filter (A0) |

Diagrams: `docs/wiring diagrams/`. Firmware pins: `firmware/uno/crane_uno_m2/config.h`.

---

## The whole crane (what is wired now)

```
                         ┌───────────────────── Arduino Uno ─────────────────────┐
 Load cell ─► AD620 ─► RC├─ A0                                                D10 ├─◄── HC-05 TXD
            ▲ LM358 REF  │                                                    D11 ├──►─ divider ─► HC-05 RXD
 IR module OUT ──────────├─ D2                                                    │       ))) Bluetooth ))) phone app
                         │  D13 built-in LED = IR state                           │
                         │  USB (D0/D1) = upload + Serial Monitor (115200)        │
                         └─ 5V ──► breadboard + rail      GND ──► breadboard − rail┘
```

---

## Pin map

| Uno pin | Used for | Direction | Notes |
|---|---|---|---|
| D0 / D1 | USB serial (upload, Serial Monitor) | — | **keep free**: wired to the USB chip |
| **D2** | IR sensor OUT | input | moves to A2 when the encoder is fitted (D2/D3 = interrupt pins) |
| D3 | free | | reserved for the encoder (interrupt) |
| D4 – D9 | free | | motor driver (D5 / D6 / D9 are PWM), ultrasonic, E-stop, panel key later |
| **D10** | SoftwareSerial RX ← HC-05 TXD | input | |
| **D11** | SoftwareSerial TX → divider → HC-05 RXD | output | |
| D12 | free | | |
| **D13** | built-in LED: on when IR detects | output | |
| **A0** | load cell (AD620 output via RC filter) | analog input | |
| A1 – A5 | free | | ACS712 current sensor (analog) later; A2 for the IR later |
| **5V** | supply for the HC-05, IR module, load cell, AD620, LM358 | | through the breadboard + rail |
| **GND** | common ground for everything | | through the breadboard − rail |

---

## Power and ground: how and why

### One 5 V source, shared through the breadboard rails
Everything runs from the Uno's **5V** pin, which comes from the laptop's USB (or a 7–12 V supply on the barrel jack through the Uno's regulator). The Uno has only a few 5V/GND pins, so:

1. Uno **5V** → breadboard **red (+)** rail.
2. Uno **GND** → breadboard **blue (−)** rail.
3. Every module's VCC and GND go to these rails.

On long breadboards the rails are often **split in the middle**: if a part on the far half gets no power, add a jumper across the gap.

### Why every part must share GND
A signal voltage is measured *against ground*. The HC-05's "3.3 V" or the AD620's "1.84 V" only mean something to the Uno if they share the same 0 V reference. A missing common ground is the most common cause of garbage serial data and jumping readings.

### Current budget (from USB, ~500 mA available)

| Part | Typical current |
|---|---|
| Arduino Uno | ~50 mA |
| HC-05 | ~30–40 mA while pairing, less when connected |
| IR module | ~20 mA |
| Load cell bridge (≈ 350 Ω at 5 V) | ~14 mA |
| AD620 + LM358 | ~2 mA |
| **Total** | **≈ 120 mA**, well within USB |

**The motor must not run from the Uno's 5V pin.** When the motor driver is added it needs its own supply, with only GND shared with the Uno. Motor current spikes on the Uno's 5 V would reset the board, disturb the weight reading (the load cell uses 5 V as its reference) and drop the Bluetooth link.

### Decoupling capacitors
- **100 nF** right at each chip's supply pins (AD620 pins 7–4): filters fast noise locally.
- **10 µF** across 5V–GND: a small reservoir that keeps 5 V steady when the HC-05 transmits.

---

## Logic levels in this project

| Connection | Driver | Receiver | Level problem? | Solution |
|---|---|---|---|---|
| Uno D11 → HC-05 RXD | 5 V | 3.3 V input | **yes**: 5 V too high | voltage divider (1 k / 1 k → 2.5 V, or 1 k / 2 k → 3.3 V) |
| HC-05 TXD → Uno D10 | 3.3 V | 5 V input | no: 3.3 V > Uno's 3.0 V HIGH threshold | direct wire |
| IR OUT → Uno D2 | 5 V (module on 5 V) | 5 V input | no | direct wire |
| AD620 OUT → A0 | 1.2 – 3.8 V analog | 0 – 5 V ADC | no | RC filter (16 kΩ / 1 µF) |

---

## Safe wiring habits
- Wire with the **USB unplugged**, check, then power up.
- Check the chip orientation (notch / dot = pin 1) before power-up: a reversed AD620 or LM358 gets hot within seconds.
- Keep the load-cell wires short and twisted together, away from the motor wires later.
- Measure with a multimeter before blaming the code: each part's file has a table of the voltages to expect.
