# Motor GA25-370 (with Hall encoder) + L298N driver (with and without the ACS712)

The hoist motor winds the rope on the drum to lift and lower the basket. The Uno can't power a motor directly (a pin gives 20 mA; the motor needs up to ~1–2 A at 12 V), so an **L298N H-bridge** switches the 12 V supply to the motor under the Uno's control. The motor's **built-in Hall encoder** counts how far it turned, which gives the hook height. The optional **ACS712** measures the motor current to detect a jammed motor.

| Diagram | When |
|---|---|
| ![Motor without current sensor](<../wiring diagrams/motor_l298n_wiring.svg>) | motor + encoder + driver only (no jam detection) |
| ![Motor with ACS712](<../wiring diagrams/motor_l298n_acs712_wiring_with_current_sensor.svg>) | full version: + ACS712 in series with the motor (jam detection) |

Parts: **25GA370 12 V, 45 : 1 (≈ 130 rpm) gear motor with Hall encoder** (`docs/datasheets/GA25-370 motor datasheet.pdf`), L298N module, roller limit switch at the top, ACS712-5A. Mechanical design: `mechanical/design/crane-structure-3d.html`.

---

## 1. Connections

### The GA25-370's 6 wires
The encoder is a small board on the back of the motor with one 6-pin connector. These are the **usual colours**; check the labels printed on the encoder board (M1 / M2 / GND / VCC / C1 / C2), because suppliers differ.

| Wire (usual colour) | Label | Connects to | Why |
|---|---|---|---|
| Red | M1 / M+ | L298N **OUT1** (through the ACS712 in the full version) | motor power |
| White | M2 / M− | L298N **OUT2** | motor power |
| Blue | VCC | Uno **5V** | encoder supply (3.3–5 V) |
| Black | GND | Uno **GND** | encoder ground |
| Yellow | C1 / A | Uno **D2** (+ 4.7 kΩ pull-up to 5V if needed) | pulse channel A, interrupt pin |
| Green | C2 / B | Uno **D3** (+ 4.7 kΩ pull-up to 5V if needed) | pulse channel B, tells the direction |

> Never put 12 V on VCC / GND / C1 / C2: only M1 / M2 take motor power.

### Uno → L298N (control)

| Uno | L298N | Why |
|---|---|---|
| **D5** (PWM) | **ENA** | speed: PWM duty 0–255 = 0–100 % of the 12 V. **Remove the ENA jumper**, otherwise the motor always runs at full speed |
| **D7** → top limit switch (COM → NC) → | **IN1** | direction bit 1; the limit switch is in this wire (section 3) |
| **D10** | **IN2** | direction bit 2 (D8 / D9 are kept for the HC-05, section 5) |
| **GND** | **GND** | common reference for the logic levels |

| IN1 | IN2 | ENA | Motor |
|---|---|---|---|
| HIGH | LOW | PWM | **LIFT** (if it lowers instead, swap M1 and M2) |
| LOW | HIGH | PWM | **LOWER** |
| LOW | LOW | HIGH | **brake** (motor terminals shorted: it resists turning) |
| any | any | LOW | coast (no power) |

### L298N power side

| L298N | Connects to | Why |
|---|---|---|
| +12V | 12 V supply **+**, after the **power switch** and the **E-stop (NC)** | motor power; the E-stop cuts it in hardware |
| GND | 12 V supply **−** and Uno GND | one common ground |
| 5V terminal | **not connected** | the L298N's own regulator output; never tie it to the Uno's 5 V |
| 5V-EN jumper | **leave on** | the L298N makes its own 5 V logic supply from the 12 V |

### ACS712-5A (full version only)

| ACS712 | Connects to | Why |
|---|---|---|
| IP+ / IP− (screw terminals) | **in series** in the motor lead: OUT1 → IP+ → IP− → M1 | all motor current flows through the sensor |
| VCC / GND | 5V / GND | |
| OUT | **A1** | analog voltage proportional to the current |

---

## 2. The hoist drive: how the drum turns

The current mechanical design is the interactive model `mechanical/design/crane-structure-3d.html` (15-11-2026), and it already uses this motor. The older `mechanical/README.md`, `bom.csv` and STEP files still show the first design (JGY-370 worm motor, Ø30 drum, separate encoder): ignore them for the drive.

```
 12 V ─► L298N ─► motor (≈ 5 850 rpm) ─► 45 : 1 gearbox ─► Ø4 D-shaft (≈ 130 rpm no load)
                                                              │  D-shaped bore, 6.9 mm engaged
                                                              ▼
                     outboard support wall ◄─ Ø7 journal ── DRUM (core Ø10, flanges Ø20)
                     (Ø7.4 hole = plain bearing)              │  rope Ø0.6 anchored through a Ø2 hole,
                                                              │  wound in one layer
                                                              ▼
                                   rope runs diagonally up to the pulley at the arm tip (x = 400 mm)
                                                              ▼
                                   over the Ø24 pulley wheel, then straight down (x = 412 mm)
                                                              ▼
                                   load cell (between 2 printed Z-parts) ─► bridle ─► basket
```

**Step by step:**
1. **Motor mount.** The motor is held **by its gearbox face**: 2 × M3 × 6 countersunk screws into the **motor wall** of the printed bracket (part 06). The bracket sits on the motor plate, clamped by the 2 mast bolts (M4 × 90) plus 2 × M3 × 25. The motor plate is keyed into the mast, so it can only go in one place.
2. **Torque into the drum.** The drum (part 07, PETG, 100 % infill) slides onto the **Ø4 D-shaft** with a matching D-shaped bore (6.9 mm of the shaft engaged). The flat on the shaft drives the drum; there's no key or set screw.
3. **Support at the other end.** The drum's **Ø7 journal** turns in a **Ø7.4 hole** in the **outboard support** (part 08), a plain bearing. The drum is carried **at both ends**, so the rope's pull is shared between the gearbox bearing and the support instead of bending the thin 4 mm shaft.
4. **Winding.** The rope (Ø0.6 mm) is anchored through the Ø2 hole in the core. One drum turn = π × 10.6 mm (core plus half the rope) ≈ **33 mm of rope**. The full 346 mm travel is ≈ **10.4 turns**, about 6.2 mm of the 13 mm core, so the rope stays in **one layer**. Every turn gives the same 33 mm, so the height is simply proportional to the encoder count.
5. **Rope path.** From the top of the drum the rope runs diagonally up to the **pulley** at the arm tip (a Ø24 printed wheel turning on a fixed sleeve, M4 axle), wraps over it, and hangs straight down to the load cell, the bridle and the basket. There's one rope fall, so rope tension = load.
6. **Directions.** LIFT turns the drum so it **winds rope on**; LOWER reverses the motor and the drum **pays rope out**. If LIFT lowers, swap M1 / M2.

**Assembly tips**
- The D-shaft and the Ø7.4 support hole must be **on one axis**: fit the drum first, then tighten the outboard support, and check the drum turns freely by hand.
- Put a drop of grease or PTFE dry lube in the journal hole, and check it for wear after the tests (PETG on PETG).
- Before the first run, check that the rope leaves the **top** of the drum toward the pulley, as in the model. The winding direction decides which motor direction is LIFT.

### Your motor: 25GA370, 12 V, 45 : 1 (from the design page)

| Quantity | Value | How |
|---|---|---|
| Output speed, no load | ≈ 130 rpm | label / design page |
| Lifting speed with load | ≈ 50 mm/s | ≈ 90 rpm × 33 mm; full travel in ≈ 7 s |
| Rated torque | ≈ 1.9–2.0 kg·cm | 5-stage gearbox (datasheet: 2.0 rated, 6.0 peak) |
| Torque needed | ≈ 1.15 kg·cm | (1.5 kg + basket) × 0.53 cm × 1.3 for starting and jerks |
| Safety factor | ≈ 1.65 | 1.9 ÷ 1.15 |
| Stall current | ≈ 1.2 A (measure it) | 45:1 isn't in the datasheet table; the 26:1 model has the same ~6 000 rpm 12 V winding and stalls at 1.2 A. Below the L298N's 2 A |
| Lifting current, 1.5 kg | ≈ 0.3 A (estimate, measure it) | scaled from the datasheet's efficiency point |

**Why the drum is so small (Ø10):** torque = rope force × drum radius. A small drum needs little torque, so a fast, low-ratio gearbox (45:1) can lift 1.5 kg at a good speed. The cost: the drum must stay in one layer (it does) and be printed solid (100 % infill).

## 3. Top limit switch in the IN1 wire (hardware backup)

The IR sensor reports the top position to the Uno (software stop). The **roller limit switch** is a second, independent stop that works **even if the code is wrong**:

```
D7 ──○ COM    NC ○──●── IN1
                    │
                  10 kΩ  (pull-down)
                    │
                   GND
```

- Normally closed: D7 drives IN1.
- At the top the hook plate presses the roller, the switch **opens**, and the 10 kΩ pulls IN1 **LOW**. Lifting needs IN1 HIGH, so the motor can't lift any more; **lowering (IN1 LOW, IN2 HIGH) still works**.
- A broken switch wire also leaves IN1 LOW: lifting stops (fail-safe).
- If LIFT turns the wrong way, swap **M1 / M2**, never IN1 / IN2, otherwise the switch would block the wrong direction.

---

## 4. The Hall encoder: hook height

A small magnet disc on the **motor shaft** (before the gearbox) passes two Hall sensors, giving two square waves A and B a quarter period apart ("quadrature"):

```
A  ‾|_|‾|_|‾|_       lifting: A rises while B is LOW
B  _|‾|_|‾|_|‾       lowering: A rises while B is HIGH
```

- **Pulses:** typically **11 pulses per motor turn** on A (check the listing: some are 7 or 16). It counts the motor shaft, before the 45 : 1 gearbox:

| Counting | Per drum turn (33 mm) | Per mm of rope | Full travel (346 mm) |
|---|---|---|---|
| A rising edges only (×1) | 11 × 45 = 495 | ≈ 15 (0.07 mm each) | ≈ 5 200 |
| every edge of A and B (×4) | 1 980 | ≈ 60 (the design page's figure) | ≈ 20 800 |

  Both are far finer than needed (the GOTO tolerance is 3 mm), so ×1 is enough and lighter for the Uno.
- **Pulse rate:** the motor shaft turns at ≈ 5 850 rpm, so A gives ≈ **1 kHz** (×4 counting: ≈ 4 kHz) while moving. Fine for an interrupt, but see section 5.
- **Why D2 / D3:** the Uno's only two external-interrupt pins. Each edge runs a tiny routine that adds or subtracts 1, so no pulse is missed while the loop is busy. That's why the IR sensor moves from D2 to **A2**.
- **Pull-ups:** many GA25 encoder boards already have pull-ups (outputs are 0 V / VCC). If A / B only ever read LOW on a meter, the outputs are open-collector: add the 4.7 kΩ pull-ups to 5V. Adding them when the board already has its own does no harm.
- **Zero point (homing):** an encoder only counts *changes*. At power-up, lift slowly until the IR top sensor triggers and set h = 346 mm (or lower onto the table and set h = 0).
- **Count with care:** count only A rising edges (direction from B), and keep the interrupt routine to a few lines.

---

## 5. Why the HC-05 moves to D8 / D9 (AltSoftSerial)

The HC-05 currently uses **SoftwareSerial** on D10 / D11. To send each byte, SoftwareSerial switches **interrupts off for about 1 ms** (at 9600 baud). The live line is ~50 bytes every 200 ms, so interrupts are off about a quarter of the time while the crane moves. With encoder pulses every ~0.5–1 ms, **pulses would be lost** and the height would drift.

**AltSoftSerial** uses a hardware timer instead and keeps interrupts on. Its pins are fixed: **RX = D8, TX = D9**. So, for the full crane:

| Signal | Milestone 2 (now) | Full crane |
|---|---|---|
| HC-05 TXD → Uno | D10 | **D8** (AltSoftSerial RX) |
| Uno → divider → HC-05 RXD | D11 | **D9** (AltSoftSerial TX) |
| L298N IN2 | — | **D10** |
| HC-SR04 Echo | — | **D11** |

The divider and the HC-05 side stay the same; only the two Uno wires move. In the firmware: `#include <AltSoftSerial.h>`, `AltSoftSerial bt;` (the pins are fixed), and update `config.h`. AltSoftSerial uses Timer1, so D10 can't do PWM any more; that's fine, IN2 only needs on/off.

---

## 6. ACS712: motor current and jam detection

The ACS712 is a **Hall-effect** current sensor: the motor current flows through a copper path inside the chip, and its magnetic field becomes a voltage. The motor circuit stays electrically isolated from the Uno side.

```
V_out = 2.5 V + 0.185 V/A × I       (ACS712-5A, VCC = 5 V)
```

| Motor current | A1 voltage | ADC counts |
|---|---|---|
| 0 A | 2.50 V | 512 |
| +0.3 A (lifting) | 2.56 V | 523 |
| −0.3 A (lowering) | 2.44 V | 500 |
| 1.6 A (jammed) | 2.80 V | 573 |
| ≈ 1.2 A (stall, 45:1 motor) | 2.72 V | 557 |

- **In series with the motor** (not the 12 V supply line): the motor's inductance smooths the current there. In the supply line the PWM would chop it into pulses. The sign follows the direction, so the firmware uses the absolute value.
- **Jam rule** (as in the simulator): current above the threshold for 0.3 s while driving → stop, state **JAM**, event to the app. The simulator uses 1.6 A, but this motor stalls at only ≈ 1.2 A: set the threshold between the measured lifting current with 1.5 kg (≈ 0.3 A) and the measured stall current, e.g. ≈ 0.8 A.
- **Resolution:** 4.9 mV per ADC step ÷ 0.185 V/A ≈ **26 mA**. Average 16–64 readings, because the motor current is noisy.
- **Without the ACS712** (first diagram): everything else works, but there's no jam detection (`HAS_CURRENT 0`, the app shows "not fitted").

---

## 7. Holding the load: the GA25 is not self-locking

A worm gear can't be turned backwards by the load; a spur gearbox like the GA25's can. With 1.5 kg the rope pulls the drum with ≈ 0.85 kg·cm. A **45 : 1** spur gearbox is fairly easy to back-drive, so **expect the basket to sink slowly when the motor is unpowered**.

- **Test it:** hang 1.5 kg at mid height, switch the 12 V off, and watch the encoder count for a minute.
- When stopped, the firmware should use **brake mode** (IN1 = IN2 = LOW, ENA HIGH): the shorted motor resists turning strongly.
- If it still creeps: the firmware can hold the position with the encoder (small corrections), and the E-stop design must accept that the load may sink slowly while power is cut. Otherwise use a higher ratio (slower lifting), or add a simple ratchet / pawl on the drum flange.

---

## 8. Power and noise

- The motor runs **only** from the 12 V supply through the L298N, never from the Uno's 5 V.
- **One common ground:** supply −, L298N GND, Uno GND, encoder black wire.
- Solder a **100 nF ceramic capacitor across the motor terminals**. It kills brush sparks that otherwise disturb the encoder and the HC-05.
- Twist the two motor wires together and keep them away from the encoder and load-cell wires. The encoder and motor share one cable on this motor, so keep it short.

---

## 9. Quick checks

| Check | Expected |
|---|---|
| Encoder powered, turn the motor shaft slowly by hand (or run it slowly), meter on C1 | toggles 0 V ↔ 5 V. Stuck at 0 V → add the pull-ups |
| Before the motor is connected: OUT1–OUT2, LIFT held | ≈ +10 V (LOWER ≈ −10 V) |
| L298N +12V with the E-stop pressed | 0 V |
| Hook at the top, IN1 terminal with D7 HIGH | 0 V (limit switch opened) |
| A1 with the motor off | ≈ 2.50 V |
| Count over one drum turn (mark the drum) | ≈ 495 (×1) or 1 980 (×4) |
