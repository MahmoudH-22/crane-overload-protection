# Control panel (box lid) ↔ Arduino Uno

The control panel on the electronics box lid lets an operator run the crane **without the phone** (LOCAL mode) and shows its state on the spot. Parts, from the lid cut-out (`mechanical/dxf/CR-27_lid_cutout.dxf`): **16×2 LCD**, **3 LEDs**, **E-STOP** (22 mm), **LIFT / LOWER / STOP / RESET** buttons (16 mm), **MODE key switch** (19 mm), **power switch**, **buzzer**.

![Control panel wiring](<../wiring diagrams/control_panel_wiring.svg>)

---

## Why an I2C expander

The Uno has 20 pins. The motor, encoder, sensors and HC-05 already use most of them (see `01-overview-power-and-pins.md`). The panel needs ~12 more. So the **slow** inputs and outputs (buttons, key, LEDs) go on a **PCF8574 I/O expander**, and the LCD has its own I2C backpack. Both share the **two I2C pins A4 (SDA) and A5 (SCL)**. Only the parts that must react instantly or are safety-related get their own Uno pin: STOP (D12), E-stop sense (A3), buzzer (D6).

**I2C in one line:** a two-wire bus (data SDA + clock SCL) where each chip has an address. The Uno talks to the LCD at **0x27** and the expander at **0x20** over the same two wires.

---

## Connections

### I2C bus (A4 / A5)

| Device | VCC | GND | SDA | SCL | Address |
|---|---|---|---|---|---|
| LCD 16×2 with I2C backpack | 5V | GND | A4 | A5 | 0x27 (some boards 0x3F) |
| PCF8574 module | 5V | GND | A4 | A5 | 0x20 (A0–A2 jumpers to GND) |

Both modules already have pull-up resistors on SDA / SCL. Keep these wires short (inside the box).

### PCF8574 pins

| Pin | Connected to | Logic |
|---|---|---|
| P0 | **LIFT** button → GND | pressed = LOW (hold-to-run in LOCAL mode) |
| P1 | **LOWER** button → GND | pressed = LOW |
| P2 | **RESET** button → GND | pressed = LOW |
| P3 | **MODE key** → GND | **closed = REMOTE**, open = LOCAL |
| P4 | green LED (5V → LED → 330 Ω → P4) | pin LOW = on: ready / link OK |
| P5 | amber LED | moving / load near max (≥ 90 %) |
| P6 | red LED | OVERLOAD / JAM / E-STOP |
| P7 | spare | |

### Direct Uno pins

| Part | Uno pin | Wiring | Logic |
|---|---|---|---|
| **STOP** button (NC contact) | **D12** | D12 → STOP (NC) → GND, `INPUT_PULLUP` | normal = LOW; pressed **or wire broken** = HIGH → stop |
| **Buzzer** (active module with transistor) | **D6** | I/O → D6, VCC 5V, GND | HIGH = beep |
| **E-stop sense** | **A3** | 12 V after the E-stop → 10 kΩ → A3 node → 4.7 kΩ → GND | ≈ 3.8 V = released, 0 V = pressed (or wire broken) |

### Power path

```
12 V supply + ─► POWER SWITCH ─┬─► Uno power (barrel jack, or via a buck converter)
                               └─► E-STOP (NC) ─┬─► L298N +12V (motor only)
                                                └─► 10 kΩ ─► A3 ─► 4.7 kΩ ─► GND (sense)
```

---

## Why each part is wired this way

### E-STOP: cuts motor power in hardware, and the Uno still knows about it
- A latching mushroom button with a **normally-closed (NC)** contact, **in series with the motor's 12 V**. Pressing it physically disconnects the motor. That works even if the Uno has crashed, which a software stop can't guarantee.
- The **Uno stays powered** (its supply branches off before the E-stop), so it can show **E-STOP** on the LCD and send it to the app.
- The worm-gear motor holds the basket when power is cut (it can't be back-driven).
- **Sense divider:** 12 V × 4.7 / (10 + 4.7) = **3.84 V** on A3: above the Uno's 3.0 V HIGH threshold and safely below 5 V. Pressed → no 12 V → the 4.7 kΩ pulls A3 to **0 V**. A broken sense wire also reads 0 V = E-stop, the safe side.
- Releasing the E-stop restores power but **doesn't restart motion**: the crane waits in ESTOP until RESET.

### STOP: normally-closed for fail-safety
STOP uses the NC contact with the internal pull-up: in normal use the closed contact holds D12 LOW. Pressing opens it → HIGH → stop. A **broken wire also reads HIGH = stop**. (With a normally-open STOP, a broken wire would silently disable the button.) STOP is a software stop: the Uno stops the motor; the E-stop is the hardware one.

### MODE key: LOCAL is the safe default
- **LOCAL**: only the panel buttons can move the crane; the app's motion commands are refused (`LOCAL_MODE`). For someone standing at the crane.
- **REMOTE**: the app may drive it.
- Key **closed = REMOTE**, so a broken wire or unplugged key falls back to LOCAL, where the phone can't move the crane.

### LIFT / LOWER / RESET on the expander
Human presses last 100 ms or more, so reading the expander every 50 ms in the safety loop is plenty. The PCF8574 has weak internal pull-ups, so a button only needs to pull its pin to GND. LIFT / LOWER are hold-to-run on the panel too: release = stop.

### LEDs on the expander
The PCF8574 can **sink** current well (up to ~25 mA per pin) but only source a tiny current, so each LED is wired **5V → LED → 330 Ω → pin** and turns on when the pin goes LOW. 330 Ω gives (5 − 2) / 330 ≈ **9 mA**: bright enough, and three LEDs stay far below the chip's limit.

### Buzzer on D6
Use an **active buzzer module** (it has its own transistor): a HIGH on D6 beeps. A bare buzzer draws ~30 mA, more than a pin should give; the module's transistor takes that current from 5V instead. Beep pattern: overload, jam, E-stop, top reached.

### LCD 16×2
Shows e.g. `0.512/1.50kg IDLE` on line 1 and `h 212mm REMOTE BT` on line 2. The backlight takes ~20 mA from 5V. Contrast is set with the small blue potentiometer on the backpack: if the screen shows only blocks or nothing, turn it.

---

## Quick checks

| Check | Expected |
|---|---|
| I2C scanner sketch | finds 0x20 and 0x27 (or 0x3F) |
| A3 with the E-stop released / pressed | ≈ 3.8 V / 0 V |
| L298N +12V with the E-stop pressed | 0 V |
| D12 with STOP released / pressed | 0 V / 5 V |
| PCF8574 P0 with LIFT released / pressed | ≈ 5 V / 0 V |
| MODE key turned | LCD shows LOCAL ↔ REMOTE; app motion buttons disabled in LOCAL |
