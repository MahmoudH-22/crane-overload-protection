# Crane Overload Protection: Project Summary
MCT332s Engineering Measurements and Sensors · Ain Shams University · Fall 2026

---

## 1. Course requirements

**Sensor station:** remotely monitored from a mobile app, with at least 3 sensors:

1. **ON/OFF sensor:** detects the presence or absence of something.
2. **Direct analog sensor:** a 0–5 V output proportional to a quantity.
3. **Sensor that needs conditioning:** low amplitude or needs excitation, with a conditioning circuit you design yourself.

**Extra requirements for 4-student teams:**
- Actuation from the mobile app is **mandatory**.
- A **4th sensor** from the course sensor pool: microphone element, IMU, load cell (no HX711), or incremental encoder (quadrature mode, measuring position).

### Grading
| Milestone | When | Marks | Items |
|---|---|---|---|
| **M1** | Week 9 | 5 (each 1 or 0) | Concept + sensors · System design · ON/OFF prototype · Direct analog prototype · Progress report |
| **M2** | Week 14 | 15 + oral | ON/OFF final (1) · Analog final (1) · Third sensor + conditioning (2) · LCD (2) · App + remote monitoring (2) · Integration (3) · Documentation + manual (4) |

Each student is questioned alone in the oral.

---

## 2. Chosen theme
**Crane overload protection for workshop hoists.**

- **The problem:** small cranes have no overload protection, so they bend, drop loads and cause injuries.
- **The solution:** a crane that weighs its load while lifting and stops itself before an overload. It also stops at the top, detects a jammed motor, and can be controlled from a lid panel or a phone.

Other themes we considered: poultry feeder, production-line weight checker, vibration monitor, water tank, and others.

---

## 3. System architecture
```
Sensors ──► Arduino Uno (all safety logic) ──► L298N ─► worm motor
   │              │   │                       ──► LCD 16×2 (I2C)
   │              │   └─ I2C ─► PCF8574 (lid control panel)
   │              └─ serial 9600 ─► NodeMCU ESP8266 ─► Wi-Fi ─► MQTT broker ─► Flutter app
Power: 12 V 2 A → diode → fuse → switch → E-stop (NC) → L298N ; 12 V → LM2596 → 5 V logic
```
**Golden rule:** the app only asks, and the Uno decides. The E-stop works in hardware even if the Uno freezes.

### Stack
- **Controller:** Arduino Uno R3. It runs all safety logic, non-blocking with `millis()` timers.
- **Wi-Fi bridge:** NodeMCU ESP8266. It only handles Wi-Fi and MQTT and makes no decisions.
- **Broker:** Mosquitto on the laptop, over a phone hotspot (2.4 GHz). HiveMQ Cloud is optional.
- **App:** Flutter 3.22+, Riverpod 2, mqtt_client 10, built in clean-architecture layers (domain / data / presentation).
- **PCB:** KiCad 8, an Uno shield carrying the modules, 120 × 90 mm.
- **CAD:** STEP files that open in SolidWorks or Inventor.

---

## 4. The four sensors

| # | Role | Part | Pin | Output / conversion |
|---|---|---|---|---|
| 1 | **ON/OFF** | Roller micro switch, top limit | **A2** | `INPUT_PULLUP`, pressed = LOW, 20 ms debounce |
| 2 | **Direct analog** | ACS712-05B, motor current | **A1** | 2.5 V + 0.185 V/A → about 26 mA per count |
| 3 | **Conditioning** (pool item 3) | 5 kg bar load cell + **INA125P** | **A0** | 1 mV/V → 0–5 mV; G = 4 + 60k/RG ≈ 663 (RG = 91 Ω); REF 0.42 V; RC 16 kΩ / 1 µF (fc 9.9 Hz); output 0.42–3.73 V; about 7.4 g per count |
| 4 | **Extra** (pool item 4) | Incremental encoder, 600 P/R, quadrature x4 | **D2 / D3** (INT0 / INT1) | 2400 counts per turn, 0.039 mm per count, homed at the top switch |

- **If the load cell is rated 2 mV/V:** use RG = 180 Ω (G ≈ 337). Otherwise the output saturates at about 2.8 kg.
- **The REF is 0.42 V, not 0.15 V,** because the INA125 output can't go below about 0.3 V on a single 5 V supply.
- **Ratiometric:** the bridge, the REF divider, the ACS712 and the ADC reference all use the same 5 V.
- **Encoder problems the pool lists, and how they're handled:**
  - Quantization: x4 decoding, speed measured over a 50 ms window.
  - Timing: an interrupt on every edge, and the count is read safely with interrupts off.
  - Noisy edges: 4.7 kΩ pull-ups, an optional RC filter and 74HC14, and a state table that rejects impossible changes and counts them as errors.

---

## 5. Physical controls (lid panel)
The buttons are read through a **PCF8574 at address 0x20** on the same I2C bus as the LCD (A4/A5).

| Input | Contact | Behaviour |
|---|---|---|
| LIFT ▲ (P0) | NO | Hold-to-run |
| LOWER ▼ (P1) | NO | Hold-to-run |
| STOP (P2) | **NC** | Stops everything. A broken wire also reads as STOP (fail-safe) |
| RESET (P3) | NO | Clears an alarm with the same checks as the app |
| LOCAL / REMOTE key (P4) | Closed = LOCAL | Decides who is in control |

**LOCAL vs REMOTE**
- **LOCAL:** the panel drives the crane; the app can only watch and press STOP; Wi-Fi loss doesn't stop it.
- **REMOTE:** the app drives the crane, and the panel's Lift/Lower are ignored.
- **Turning the key stops any motion.**
- **STOP and the E-stop always work**, in both modes.
- **The LCD's top-right character shows the mode:** L (local), R (remote) or ? (panel fault).

---

## 6. Safety rules (Uno, checked 20 times per second)
1. **E-stop:** cuts motor power in hardware.
2. **Overload:** weight above max for 3 readings → stop, latch the alarm, block lifting. Lowering is still allowed. Reset only when the weight is ≤ 95% of max.
3. **Near limit:** ≥ 90% of max → yellow warning.
4. **Jam:** current > 1.5 A for 0.3 s while lifting, **or** the encoder sees < 3 mm/s for 0.4 s while driven.
5. **Top limit:** switch pressed → no lifting. Within 20 mm of the top, the speed is capped at about 43%.
6. **Link loss:** no heartbeat for 2 s → stop app-started motion (local motion keeps going).
7. **Lowering ends** at the 5 mm soft bottom limit, when the load lands, or after a 15 s timeout.
8. **Soft start:** 0.5 s PWM ramp, to avoid false overloads at lift-off.

---

## 7. Pin map (Uno)
| Pin | Use |
|---|---|
| A0 | Load cell amplifier output (after the RC filter) |
| A1 | ACS712 OUT |
| A2 | Limit switch |
| A3 | Optional E-stop sense |
| A4 / A5 | I2C: LCD (0x27) + PCF8574 panel (0x20) |
| D2 / D3 | Encoder A / B |
| D4 | Buzzer (through a 2N2222) |
| D5 | L298N ENA (PWM) |
| D7 / D8 | L298N IN1 / IN2 |
| D6 / D9 / D12 | Green / yellow / red LEDs (220 Ω each) |
| D10 / D11 | SoftwareSerial to the NodeMCU (Uno TX through a 1k/2k divider) |
| D0 / D1 | Free (USB) |

---

## 8. Communication
**Serial link (9600 baud, every line ends with an XOR checksum `*XX`)**
- **Uno → NodeMCU every 0.5 s:** `D,kg,amps,top,STATE,max,flags,heightMm`
  - flags: 1 near limit · 2 link lost · 4 homed · 8 encoder errors · 16 LOCAL · 32 panel fault
- **Uno → NodeMCU on a rejected command:** `E,reason`
- **NodeMCU → Uno:** `H` (heartbeat, every 1 s), `C,UP|DOWN|STOP|RESET|TARE`, `C,MAX,v`, `C,CAL,v`

**MQTT topics**
| Topic | Content |
|---|---|
| `crane/live` | JSON telemetry, retained |
| `crane/cmd` | App commands, QoS 1 |
| `crane/status` | online / offline (Last Will), retained |
| `crane/events` | Alarms and rejected commands |

---

## 9. Mechanical design (confirmed in 3D and CAD)
| Item | Value |
|---|---|
| Base | MDF 450 × 300 × 18 |
| Mast | Pine 40 × 40 × 550 |
| Arm | Pine 40 × 40 × 450; pulley at L = 400 mm from the mast centre |
| Brace | Pine 20 × 40, cut at about 51° |
| Drum → pulley height H | 450 mm |
| Base in front of the mast, a | 150 mm |
| Counterweight | 2.0 kg, 150 mm behind the mast |
| Drum | Ø30 × 40 (r = 15), PLA |
| Hook travel | **0–380 mm** (changed from 250 so the basket reaches the table) |
| Rated load | **2.0 kg** |
| Tipping | SF 2.77 at 1.25 kg; maximum safe load 2.43 kg |
| Motor | 12 V worm gear (self-locking), JGY-370 type, needs 2.9 of 10 kg·cm |

**Stress analysis**
- Hand calculations with a dynamic factor φ = 1.3.
- Required safety factors: wood 3, rope 5, tipping 1.5, motor 1.5.
- Checked: arm and mast bending, deflection, tipping, rope, motor torque, pulley bolt, load cell rating.
- Plan: also run a Fusion or Inventor FEA, plus a 125% proof-load test.

**CAD check results:** 0 clashes, and the limit switch was moved 7 mm inward so its roller actually hits the top plate.

---

## 10. Files delivered
| File | What it is | Where it's kept |
|---|---|---|
| `crane-project-guide.html` | Full guide: home, phases 0–5, Implementation A–Z (26 steps), stress calculator, circuit design, PCB, software, parts, options, 46 tests, docs, 34+ figures with SVG/PNG export | `U:\ASU\Measurements\` |
| `crane-overload-starter.zip` | Repo: Uno firmware, NodeMCU firmware, tools (bench / I2C / panel tests), Mosquitto config, Flutter app, project summary file, history logs | `U:\My Projects\crane-overload\` |
| `crane-3d-model.html` | Interactive 3D model: animation, 12 live design checks, exploded view, works on phones | `mechanical\` |
| `crane-solidworks-cad.zip` | STEP parts + assembly, DXF cutting files, BOM, interference report, rebuild sheet | `mechanical\step\` |
| `crane-overload-simulation.html` | Live simulation of the crane and its signal chain | – |
| `vibration-monitor-simulation.html`, `mct332s-project-options.html` | Earlier theme explorations | – |

---

## 11. Inventor workflow (what worked)
1. **Open the STEP:** File → Open → STEP → `CR-00_crane_assembly.step`, then choose **Convert Model**, units mm.
2. **Save everything:** **Save All**. The red "outside project workspace" note is only a warning.
3. **Copy to the work folder:** File → Save As → **Pack and Go**.
   - Destination: `mechanical\CAD\Inventor\parts\`
   - Tick **Copy to Single Path** and **Model files Only**.
   - Tick **Skip Libraries, Styles, Templates**.
   - Click **Search Now** (expect about 38 files), then **Start**.
4. **Put the assembly above the parts folder:**
   - Create an Inventor project rooted at `CAD\Inventor\`.
   - Open the `.iam` from `parts\`, then use plain **Save As** into `CAD\Inventor\`.
   - Delete the extra `.iam` inside `parts\`.
5. **Never move Inventor files in File Explorer.** Use Pack and Go or Save As so the links stay intact.

Final layout:
```
mechanical\
├── step\                   STEP source files (backup)
└── CAD\Inventor\
    ├── CR-00_crane_assembly.iam
    └── parts\              37 .ipt
```

---

## 12. Milestone 1: what's required and how the design covers it

| # | Item | Covered by |
|---|---|---|
| 1 | Concept + sensors | Crane theme; limit switch (A2), ACS712 (A1), load cell + INA125 (A0), with ranges; encoder mentioned as planned |
| 2 | System design | Block diagram, guide Fig. 1.1 |
| 3 | ON/OFF prototype | Limit switch → Uno → NodeMCU → MQTT → app shows AT TOP / BELOW TOP, 10 out of 10 times (T1.4) |
| 4 | Direct analog prototype | ACS712 → amps in the app: about 0.25 A empty, rising with load; matches a multimeter within ±10% (T2.2) |
| 5 | Progress report | 8 points: theme, specs, diagram, circuits, screenshots, readings, problems and remaining work, clean layout |

**Firmware flags for M1:** `HAS_LOAD_CELL 0`, `HAS_CURRENT 1` (once the ACS712 is wired), `HAS_ENCODER 0`, `HAS_PANEL 0`.

### 3-day plan (Implementation steps A–M)
- **Day 1 (switch to app):**
  - install the tools
  - check the parts and set the buck to 5.00 V
  - limit switch on A2
  - hotspot + Mosquitto
  - serial link
  - flash both boards
  - Flutter app shows AT TOP / BELOW TOP ✅
- **Day 2 (current in amps):**
  - L298N (ENA jumper removed) + E-stop
  - quick test rig
  - ACS712 in series; restart with the motor off
  - multimeter comparison at 0 / 0.5 / 1 / 1.5 / 2 kg ✅
- **Day 3:**
  - readings tables, screenshots, photos, a video
  - write the report
  - `flutter build apk`
  - 2 full rehearsals

**Team split:**
- A: wiring + firmware
- B: broker + app
- C: test rig
- D: report + figures

**Demo script (about 2 min):**
1. Power on → app shows ONLINE.
2. Press the switch 3 times → the app flips between AT TOP and BELOW TOP.
3. Lift empty / 1 kg / 2 kg → the current rises and matches the meter.
4. Press STOP in the app, then the E-stop.
5. Hand over the report.

---

## 13. Open items
- [ ] Set `TOP_HEIGHT_MM` to **380** in `crane_uno.ino`, and update the guide's 250 mm references (tests T3.12 / T3.13, `H:250mm`).
- [ ] Update the limit switch position in the guide's figures to match the CAD fix (7 mm inward).
- [ ] Confirm the load cell rating (1 or 2 mV/V) and pick RG to match.
- [ ] Ask the TA to confirm the 4th-sensor interpretation (encoder as an additional sensor).
- [ ] Optional: rename the project-summary file at the repo root to `PROJECT.md`.
