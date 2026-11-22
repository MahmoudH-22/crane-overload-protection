# IR top-of-travel sensor ↔ Arduino Uno

The IR sensor tells the Uno when the hook has reached the **top of its travel**. When it triggers, the crane state becomes **TOP**, a TOP event is sent to the app, and lifting is not allowed (the app greys out LIFT; with the motor fitted the Uno will stop it). It is an **ON/OFF (digital) sensor**.

---

## The module (FC-51 style IR obstacle sensor)

| Part on the board | What it does |
|---|---|
| IR LED (clear / blue "eye") | sends invisible infrared light forward |
| Photodiode (dark "eye") | receives the light that bounces back from an object |
| LM393 comparator chip | compares the received light with a threshold, gives a clean HIGH / LOW |
| Blue potentiometer | sets that threshold = the detection distance (about 2 – 30 cm) |
| Power LED | on whenever the module has power |
| Obstacle LED | on when something is detected |
| Pull-up resistor on OUT | keeps OUT at VCC (HIGH) when nothing is detected |

Output logic: **nothing in front → OUT HIGH**, **object in front → OUT LOW** ("active LOW").

---

## Connections

| IR module pin | Connects to | Why |
|---|---|---|
| **VCC** | Uno **5V** (breadboard + rail) | the module works from 3.3 – 5 V; 5 V gives the strongest IR LED and range |
| **GND** | Uno **GND** (breadboard − rail) | common reference with the Uno |
| **OUT** | Uno **D2** | digital input, read with `digitalRead()` |

```
            ┌──────────────┐
  5V  ──────┤ VCC          │
  GND ──────┤ GND   FC-51  │   ))) IR ───► hook / flag at the top
  D2  ──────┤ OUT          │
            └──────────────┘
```

In the code (`config.h`): `PIN_IR = 2`, `PIN_IR_LED = 13`; `ir_sensor.cpp` reads it.

---

## Why it is wired and coded this way

### 1. Direct wire to D2, no resistor
OUT is already a clean 0 V / 5 V logic signal from the LM393 with its own pull-up, so it can go straight to a digital pin. The pin is set as a plain `INPUT` (no internal pull-up needed, the module has one).

### 2. Why D2 (and why it will move)
D2 was the free digital pin used in milestone 1. **D2 and D3 are the Uno's only external-interrupt pins**, and the hook-height **encoder will need them** (it produces fast pulses that must not be missed). When the encoder is fitted, move IR OUT to **A2**: the analog pins also work as normal digital inputs, and the IR signal is slow, so it doesn't need an interrupt. Only `PIN_IR` in `config.h` changes.

### 3. Active LOW → "detected" in software
`ir_sensor.cpp` treats `digitalRead(PIN_IR) == LOW` as **detected**. If a different module gives HIGH when it detects, only that comparison needs flipping.

### 4. Debounce (20 ms)
At the edge of the detection distance, or when something moves past, the output can flicker for a few milliseconds. The code only accepts a new state after it has been stable for **20 ms**, so one arrival at the top gives **one** TOP event, not a burst.

### 5. LED 13 mirrors the sensor
The Uno's built-in "L" LED (pin 13) turns on when the IR detects, so you can test the sensor without the Serial Monitor or the app.

### 6. Shared 5V / GND with the HC-05
The Uno has one 5 V pin and the HC-05, IR module and load-cell circuit all need it. Use the breadboard rails: Uno 5V → red (+) rail, Uno GND → blue (−) rail, and every module's VCC / GND to the rails. The IR module draws only ~20 mA.

---

## Adjusting and mounting
- Turn the potentiometer **clockwise** for a longer detection distance, **anticlockwise** for shorter. Set it so it triggers when the hook (or a small white flag on it) is about **2 – 5 cm** away, at the point where lifting must stop.
- White / shiny surfaces reflect IR well; black matte surfaces reflect poorly (shorter range).
- Sunlight and some lamps contain IR and can trigger it by themselves: keep it shaded.
- Point it so it never "sees" the frame, a wall or the table at the set distance, otherwise it stays on.

---

## Quick checks

| Test | Module | Serial Monitor (115200) | Uno LED 13 | App |
|---|---|---|---|---|
| Nothing in front | obstacle LED off | `IR clear  st IDLE` | off | grey **IR clear**, IDLE |
| Hand / paper 3 cm in front | obstacle LED on | `IR TOP  st TOP`, `EVENT TOP` | on | amber **IR TOP**, state TOP, TOP in Events |
| Multimeter OUT → GND | — | ≈ 5 V clear, ≈ 0 V detected | | |

| Problem | Likely cause |
|---|---|
| Power LED off | VCC / GND not connected |
| Obstacle LED works, Uno always "clear" | OUT not on D2, or no common GND |
| Always "TOP" | range too long, sees the table / wall, sunlight → turn the pot anticlockwise, shade it |
| Reversed (TOP when clear) | module is active HIGH → flip the comparison in `ir_sensor.cpp` |
