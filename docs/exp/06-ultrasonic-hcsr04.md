# Ultrasonic HC-SR04 (obstacle under the load) ↔ Arduino Uno

The HC-SR04 hangs **under the basket, pointing down**. It measures the distance from the basket's bottom to whatever is below it. If that distance is clearly shorter than the hook height says it should be, **something is under the load**, and the Uno refuses to lower onto it.

![Ultrasonic wiring](<../wiring diagrams/ultrasonic_hcsr04_wiring.svg>)

---

## Connections

| HC-SR04 pin | Connects to | Why |
|---|---|---|
| **VCC** | Uno **5V** | the module needs 5 V (~15 mA) |
| **Trig** | Uno **D4** | the Uno sends a 10 µs pulse to start a measurement |
| **Echo** | Uno **D11** | the module answers with a pulse whose length = the echo's travel time |
| **GND** | Uno **GND** | common reference |

All four go through one **4-core flexible cable (~0.7 m)** that runs down along the rope to the basket.

---

## How it works

1. D4 goes HIGH for 10 µs → the module sends 8 bursts of 40 kHz ultrasound.
2. Echo goes HIGH and stays HIGH until the sound comes back.
3. Distance = echo time × speed of sound (343 m/s) ÷ 2 (there and back):

```
distance [mm] = echo time [µs] × 0.343 / 2  ≈  echo time [µs] / 5.83
```

| Distance | Echo pulse |
|---|---|
| 20 mm (closest it can see) | 117 µs |
| 346 mm (full travel) | 2.0 ms |
| 1 m | 5.8 ms |
| nothing in range (~4 m) | ~25 ms, or no echo at all |

**The obstacle rule (on the Uno):** with `h` = hook height from the encoder, the table should be about `h` below the basket. If `us < h − 30 mm` (or there's no echo) while `h ≥ 50 mm` for 2 readings in a row, that's an **obstacle**: LOWER and downward GOTO are refused, and a lowering in progress stops. It clears by itself after 0.5 s clear. Below 50 mm the basket is near the table anyway, so the check is off.

---

## Why it is wired and coded this way

### No level shifting
The HC-SR04 is a 5 V module and the Uno is 5 V, so Trig and Echo connect directly.

### Why D4 and D11
Those were left after the motor driver (D5, D7, D10), the encoder (D2, D3) and the HC-05 (D8, D9 on AltSoftSerial in the full crane) got their pins. Neither the trigger nor the echo needs a PWM or interrupt pin, though D11 can be used with a pin-change interrupt (see the timing note).

### Timing: keep the 50 ms loop fast
- Waiting for an echo blocks the program. Use a **timeout of ~6 ms** (≈ 1 m): the full crane travel needs only 2 ms, and a missing echo then costs at most 6 ms, not 25.
- **Interrupts disturb simple `pulseIn()` timing** (encoder pulses, serial). Better: measure the echo with a **pin-change interrupt on D11** and `micros()`, or take the **median of 3** readings. An "obstacle" needs 2 readings in a row anyway.
- One reading every 50–100 ms is plenty.

### The sensor and cable are on the scale
The basket hangs from the load cell, so **the sensor (~9 g) and whatever cable hangs from the hook are weighed too**:
- **Tare with the sensor fitted**, so its own weight is zeroed.
- **Tie the cable to the rope** every ~10 cm and **clip it to the Z-mount top plate (above the load cell)**, then run a short slack loop down to the sensor. That way the rope, not the load cell, carries the cable, and the reading doesn't change as the hook moves up and down.
- Use thin, flexible wire (e.g. 4-core 0.08 mm² or a ribbon cable).

### Mounting
- Point it **straight down**, centred under the basket. A tilted sensor sees the edge of the table or the mast.
- It can't see closer than ~2 cm: the firmware sends `us = null` then.
- Soft objects (cloth, foam) absorb sound and may give no echo. That reads as "no echo" = obstacle, which is the safe side.

---

## Quick checks

| Check | Expected |
|---|---|
| Hand 10 cm below the sensor | `us` ≈ 100 mm in the app's "Under the load" card |
| Basket hanging over the empty table at h = 200 mm | `us` ≈ 200 mm, CLEAR |
| Box 80 mm tall under the basket | `us` ≈ 120 mm, OBJECT BELOW, LOWER disabled |
| `us` jumps around | cable loose, sensor tilted, measuring while SoftwareSerial receives → use the median |
| Weight changes as the hook moves | the cable is hanging from the hook: clip it above the load cell |
