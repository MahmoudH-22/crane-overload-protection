# HC-05 Bluetooth module ↔ Arduino Uno

The HC-05 is the crane's wireless link to the phone app. It acts like an invisible serial cable: whatever the Uno sends on its TX pin comes out on the phone over Bluetooth, and whatever the app sends comes back into the Uno's RX pin. The HC-05 makes no decisions; it only carries the text lines from `crane_link.h`.

![HC-05 wiring](<../wiring diagrams/hc05_arduino_wiring.png>)

---

## Connections

| HC-05 pin | Connects to | Through | Signal direction |
|---|---|---|---|
| **VCC** | Uno **5V** | wire | power in |
| **GND** | Uno **GND** | wire | common reference |
| **TXD** | Uno **D10** | wire, direct | HC-05 → Uno (app commands) |
| **RXD** | middle point of the divider | R1 = 1 kΩ from Uno **D11**, R2 = 1 kΩ (or 2 kΩ) to **GND** | Uno → HC-05 (live data, events) |
| **EN** (KEY) | not connected | — | only used to enter AT mode |
| **STATE** | not connected | — | (could later tell the Uno "phone connected") |

```
Uno D11 ──[ R1 1 kΩ ]──●──[ R2 1 kΩ ]── GND
                       │
                   HC-05 RXD   (≈ 2.5 V when D11 is HIGH)

HC-05 TXD ──────────────────── Uno D10   (3.3 V HIGH, read as HIGH by the Uno)
```

In the code (`config.h`): `PIN_BT_RX = 10`, `PIN_BT_TX = 11`, `BT_BAUD = 9600`; `app_link.cpp` opens `SoftwareSerial bt(10, 11)`.

---

## Why each connection is done this way

### 1. Power: VCC → 5V
The ZS-040 board has its own 3.3 V regulator; the label says **Power 3.6 V – 6 V**. Feeding it 5 V from the Uno is inside that range. The module draws roughly 30–40 mA while searching / pairing and less once connected, which the Uno's 5 V pin supplies easily from USB.

The **radio chip itself (CSR BC417) runs at 3.3 V**. That is why the label also says **LEVEL: 3.3V**: the TXD / RXD pins are 3.3 V logic even though the board is powered from 5 V.

### 2. Common ground: GND → GND
A logic level is a voltage *measured against ground*. If the two boards do not share GND, "3.3 V" on TXD means nothing to the Uno and the data turns into garbage. Every signal connection in this project needs this shared ground.

### 3. Uno → HC-05 needs a voltage divider (D11 → RXD)
The Uno is a 5 V board, so its D11 output swings 0 V ↔ **5 V**. HC-05 RXD is a 3.3 V input; 5 V on it is above its maximum rating. It may survive for a while, but it is out of spec and can damage the chip or make it unreliable.

A voltage divider scales the 5 V down:

```
V_RXD = 5 V × R2 / (R1 + R2)
```

| R1 (top, from D11) | R2 (bottom, to GND) | V_RXD when D11 is HIGH | Comment |
|---|---|---|---|
| 1 kΩ | 2 kΩ | 3.33 V | ideal: exactly 3.3 V logic |
| 1 kΩ | 2.2 kΩ | 3.44 V | fine |
| **1 kΩ** | **1 kΩ** | **2.50 V** | **what we use** (only two 1 kΩ available). Still read as HIGH by the HC-05, with less margin |
| 2 kΩ | 1 kΩ | 1.67 V | **wrong way round**: too low, the HC-05 never sees the commands |

Things to check:
- R1 (top) must be on the **D11 side**, R2 (bottom) on the **GND side**.
- Current through the divider when D11 is HIGH: 5 V / 2 kΩ = 2.5 mA, far below the Uno pin limit (20 mA recommended).
- To get the ideal 3.3 V later with only 1 kΩ resistors: R1 = one 1 kΩ, R2 = two 1 kΩ in series (2 kΩ).

### 4. HC-05 → Uno needs no resistor (TXD → D10)
Here the signal goes the safe way: a 3.3 V output into a 5 V input. 3.3 V cannot harm the Uno, and the Uno (ATmega328P at 5 V) reads a HIGH from about 3.0 V (0.6 × VCC), so 3.3 V is recognised. No divider, no level shifter.

### 5. Why D10 / D11 and not the Uno's TX/RX pins (D0 / D1)?
D0 / D1 are the Uno's hardware serial port, which is **wired to the USB chip**. They are used to upload sketches and for the Serial Monitor (calibration, status line). Putting the HC-05 there would:
- block uploads while the module is plugged in, and
- mix the Serial Monitor text with the app data.

So the HC-05 uses **SoftwareSerial** on two ordinary pins. D10 works as a SoftwareSerial RX because it has a pin-change interrupt (on the Uno all pins do). 9600 baud is used because SoftwareSerial is reliable at that speed and it is the HC-05's factory data speed. One live line (~50 characters) every 200 ms is only about 250 bytes/s, well under the ~960 bytes/s that 9600 baud carries.

### 6. Full crane: the HC-05 moves to D8 / D9 (AltSoftSerial)
SoftwareSerial switches interrupts off for ~1 ms per byte it sends. That's fine now, but the motor's Hall encoder (added later) sends pulses every ~0.5–1 ms, and those would be lost. **AltSoftSerial** keeps interrupts on, but its pins are fixed: **RX = D8, TX = D9**. When the motor is added:
- HC-05 TXD → **D8** (instead of D10)
- Uno **D9** → 1 kΩ → HC-05 RXD with the same divider (instead of D11)
- Firmware: `AltSoftSerial bt;` instead of `SoftwareSerial bt(10, 11);`, pins in `config.h`.

D10 / D11 then go to the L298N IN2 and the ultrasonic Echo. Details: `05-motor-l298n-encoder.md`, section 5.

### 7. EN and STATE stay unconnected
- **EN (KEY)**: when HIGH at power-up (or the button is held) the HC-05 starts in **AT mode** at 38400 baud, the settings mode, and is **not** discoverable. In normal use it must stay low, so it is left open.
- **STATE**: goes HIGH when a phone is connected. Not needed: the Uno already knows the app is there because the app sends PING every second.

---

## LED meaning

| HC-05 LED | Meaning |
|---|---|
| Fast blink (~5 per second) | powered, waiting to be paired / connected |
| Two short blinks every 2 s | connected to the phone |
| Slow blink (1 s on, 1 s off) | AT mode (button held / EN high at power-up) |
| Off | no power: check VCC / GND |

---

## Settings in the module (set once with AT commands)
`firmware/uno/hc05_setup/`: upload it, power up **holding the HC-05 button** (slow blink), Serial Monitor 9600 + "Both NL & CR". On this board **keep the button held while each command is sent**.

| Command | Why |
|---|---|
| `AT+ORGL` | factory reset |
| `AT+ROLE=0` | slave: phones can find it (master mode is invisible) |
| `AT+UART=9600,0,0` | must match `BT_BAUD` in `config.h` |
| `AT+NAME=HC-05` | name shown on the phone |
| `AT+PSWD?` | PIN used for pairing (1234) |

Our module: firmware 2.0-20100601, address `00:25:07:01:FC:62`.

---

## Quick checks

| Check | Expected |
|---|---|
| Multimeter, divider middle point to GND while running | ≈ 2.5 V (1 k / 1 k) or ≈ 3.3 V (1 k / 2 k) |
| Multimeter, HC-05 TXD to GND | ≈ 3.3 V (idle line is HIGH) |
| Uno Serial Monitor (115200) with the app connected | `link ok/bad` rising, few or no bad, `app yes` |
| Many bad lines | loose wire, missing common GND, baud not 9600 |
| `link ok/bad 0/0`, `app no` | D11 → divider → RXD path broken, or the app is not connected |
