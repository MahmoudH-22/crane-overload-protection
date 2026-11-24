# Crane Overload: Load Design Specification

**Project:** Crane Overload, MCT332s Engineering Measurements and Sensors (Fall 2026, Ain Shams University)
**Team:** Mahmoud Hisham 2400844 · Ziad Hany 2301401 · Abdulrahman Mohamed 2400544 · Ahmed Hany 2400311

This document specifies everything that carries, lifts, weighs or limits the load: ratings, load path, every load-bearing part with its dimensions, structural checks, drive, sensing, safety limits and acceptance tests.
**Units:** mm, kg, N.
**Coordinates:** X from the mast centre toward the hook, Y up from the table, Z across.

---

## 1. Ratings

| Item | Value |
|---|---|
| **Rated load (safe working load)** | **1.5 kg** (basket contents) |
| Proof test load (125%) | 1.9 kg, held 10 min |
| Load cell capacity | 5 kg (rated load = 30% of capacity) |
| Dynamic factor φ (start, stop, swing) | 1.3 |
| Design rope tension at rated load | (1.5 × 1.3 + 0.15 hook stack) × 9.81 ≈ **20.6 N** |
| Hook travel | **0–380 mm** (basket bottom above the table) |
| Lift speed | ≈ 32 mm/s (20 RPM motor, Ø30 drum) |
| Hoist type | Single fall, worm-gear drive (self-locking: holds the load with power off) |
| Outreach (mast centre → rope) | ≈ 409 mm (rope leaves the pulley groove bottom) |
| Overall crane size | 740 (L) × 300 (W) × 618 (H) |

**Required safety factors**

| Check | Minimum |
|---|---|
| Wood / MDF parts | 3 |
| Rope | 5 |
| Tipping | 1.5 |
| Motor torque | 1.5 |
| Bolts / pins | 3 |

---

## 2. Load path

```
basket → 4 cords → bridle loop → M3 pin (bottom lug) → bottom Z-part → 2 × M4 through-bolts
→ load cell FREE end → load cell bar (bends, strain gauges) → load cell FIXED end
→ 2 × M4 through-bolts → top Z-part → M3 pin (top lug) → rope loop → rope
→ pulley wheel (on a printed sleeve) → M4 axle → U-bracket → 2 × M3 × 65 through the arm tip block stack
→ arm (box beam) + brace + gussets → mast (box beam) → base box (socket, ribs) → table
                                  └ rope back to the drum → motor (worm gear) → motor plate → mast
```

**Rule:** the force between the rope and the basket must pass **only through the load cell bar**. Each end of the load cell is bolted to **one** printed part only.

---

## 3. Load-carrying parts and dimensions

### 3.1 Basket and bridle
| Item | Specification |
|---|---|
| Basket | Plastic box ≈ 70 × 60 × 70, open top |
| Cords | 4 cords from the corners, tied into one short bridle line with an end loop |
| Connection | Bridle loop up through the bottom lug's Ø4 hole, round the M3 pin. **No S-hook.** |
| Test weights | Water bottles weighed on a kitchen scale: 0.5 / 1.0 / 1.5 kg (+ 1.9 kg for the proof test) |

### 3.2 Load cell (sensor 3: analog with conditioning)
| Item | Specification |
|---|---|
| Type | Single-point bending-beam bar, binocular slot, strain gauges under white potting |
| Size | 80 × 12.7 × 12.7 |
| Capacity | 5 kg |
| Rated output | 1 mV/V (check the label; 2 mV/V changes RG, see §6) |
| Mounting holes | 2 per end, Ø4 threaded (check M4 / M5), through the bar |
| Orientation | Threaded-hole faces **horizontal** (up/down), double hole facing **sideways**, label arrow down |
| Fixed end | **Wire end**, bolted to the **top** Z-part only |
| Free end | Other end, bolted to the **bottom** Z-part only |
| Wires | Red E+ (5 V), black E− (GND), green S+ (INA125 +in), white S− (INA125 −in) |

### 3.3 Z-mount (2 identical printed parts)
| Feature | Dimension |
|---|---|
| Part envelope | 48 × 14 × 30 |
| Plate | 48 × 14 × **6** |
| Boss (one end) | 20 × 14 × **10** (= gap between plate and bar) |
| Lug (over the bar centre) | R8, 14 wide, pin centre 6 above the plate |
| Pin hole | Ø5 (M3 × 20 pin + rope/bridle loop) |
| Rope hole | Ø4, from the lug top into the pin hole, edge chamfered |
| Bolt holes | Ø4.4 at −35 and −25 from the lug centre (through the boss and plate) |
| Clearance to potting | ≥ 7 mm (gap 10, potting ≈ 2.6 high) |
| Material / print | PETG, printed on its side (14 mm = print height), 4 walls, 50% infill, ≈ 9 g |
| Fasteners | 4 × **M4 × 40** + washer + **nylock** (through-bolts: fixed end down from the top part, free end up from the bottom part) |
| Pins | 2 × **M3 × 20** + nylock |
| Stack height (top lug top → bottom lug bottom) | 8 + 6 + 6 + 10 + 12.7 + 10 + 6 + 6 + 8 ≈ **73** |

**Alignment:** the top rope hole, the bar centre and the bottom hole are on **one vertical line**. The rope loop pivots on the top pin, so the mount self-levels and does not tilt under any load (0–2 kg).

**Plate check (printed PETG):**
- Lever from the boss edge to the lug ≈ 20 mm.
- M = 20.6 N × 20 mm ≈ 410 N·mm.
- σ = 6M / (b t²) = 6 × 410 / (14 × 6²) ≈ **4.9 MPa**, against PETG ≈ 40 MPa along the layers → SF ≈ 8 ✅

### 3.4 Rope
| Item | Specification |
|---|---|
| Type | Braided PE (Dyneema-type) fishing line, low stretch, low twist |
| Diameter / strength | 0.6 mm / ≥ 30 kg (≈ 294 N) |
| Design tension | 20.6 N → **SF ≈ 14** ✅ |
| Length | ≈ 3 m (drum anchor + ≥ 5 dead turns + 380 travel + run to the pulley) |
| Ends | Tied loops (perfection loop / double figure-8) round the M3 pins; drum end through the drum's Ø2 anchor hole |
| Swivel | **None**: the rope, mount and load cell wires turn together, so the wires never wrap |
| Load cell wires | Zip-tied loosely along the rope, slack loop at the arm, into the base through the Ø20 grommet |

### 3.5 Pulley (no bearing)
| Part | Dimension |
|---|---|
| Wheel | Ø24 × 6.0, flat faces, bore **Ø7.3** |
| Rope groove | V with flat bottom: 3.5 deep, 4.4 wide at the rim, 1.6 flat, Ø17 at the bottom (rope pitch radius ≈ 8.8) |
| Sleeve (fixed) | Ø7.0 / Ø4.3 × **7.5**, clamped between the cheeks; covers the whole gap |
| Spacer rings | 2 × Ø11 / Ø7.4 × 0.5 (wheel 6.0 + 1.0 = 7.0 in a 7.6 gap → 0.3 side clearance) |
| Axle | M4 × 30 (threaded is fine, hidden inside the sleeve) + 2 washers outside the cheeks + nylock |
| Lubricant | Vaseline in the wheel bore |
| Rope wrap angle | ≈ 140° |
| Resultant on the axle | 2 T sin(70°) ≈ 2 × 20.6 × 0.94 ≈ **39 N** |
| Bore pressure | 39 N / (7.3 × 6.0) ≈ **0.9 MPa** (greased PETG on PETG) ✅ |
| Speed | ≈ 31 RPM at 32 mm/s |

### 3.6 Pulley U-bracket
| Feature | Dimension |
|---|---|
| Envelope | 28 × 17.6 × 24 |
| Base | 28 × 17.6 × 5 (against the arm underside) |
| Cheeks | 5 thick, gap 7.6, rounded R8 around the axle |
| Axle hole | Ø4.4, centre 16 below the base top (= 16 below the arm) |
| Arm bolt holes | Ø3.4 at +3 and +13 from the axle (arm x = 403 / 413) |
| Fixing | 2 × **M3 × 65** from the top of the arm through the 5-block stack + washer + nylock under the base |
| Material / print | PETG, base on the bed, 5 walls, 60% infill |
| Pulley axle position | X = 400 from the mast centre, Y = 552 |

### 3.7 Top limit (sensor 1: ON/OFF)
| Item | Specification |
|---|---|
| Switch | KW11-3Z roller-lever micro switch, COM → GND, NO → Uno A2 (pull-up) |
| Mount | Printed / MDF plate P15 + foot P16 under the arm tip (x 420–440), 2 × M3 × 65 through the arm, 2 × M2.5 × 12 for the switch |
| Trip point | The top Z-part's plate presses the roller ≈ **10 mm** before the lug reaches the pulley (set on the slot) |
| Action | Stops lifting and sets the encoder's height zero (380 mm) |

---

## 4. Hoist drive

| Item | Primary choice | Fallback |
|---|---|---|
| Motor | JGY-370 12 V worm gear motor **with Hall encoder**, ≈ **20 RPM**, ≥ 8 kg·cm, Ø6 D-shaft | Same motor, **130 RPM**, ≥ 2 kg·cm |
| Drum core | **Ø30** × 25 wide, flanges Ø42 | **Ø10** × 15 wide, flanges Ø20 |
| Rope per drum turn | ≈ 96 mm | ≈ 33 mm |
| Lift speed | ≈ 32 mm/s (full travel 12 s) | ≈ 72 mm/s (≈ 5 s) |
| Torque needed at rated load (×1.3) | ≈ 3.1 kg·cm | ≈ 1.0 kg·cm |
| Torque margin | ≈ 3× | ≈ 1.5–2.4× |
| Drum fixing | On the motor D-shaft, M3 set screw on the flat ≈ 7 from the gearbox face; rope wound close to the gearbox | Same |
| Holding | Worm gear self-locks: load must stay put with power off (test) | Same |
| Motor plate | 2 × 7 mm MDF (14 thick), 200 × 90, located by a key in the mast slot, 2 × M4 × 80 through the mast | Same |

The drum is printed (PETG, 40% infill, 4 walls) **after** the motor arrives and its shaft is measured.

**Drive electronics**
| Item | Specification |
|---|---|
| H-bridge | L298N: ENA D5 (PWM), IN1 D7, IN2 D8 |
| Power path | 12 V 2 A adapter → Schottky (1N5822 / SR340 / SB540) → 2 A slow fuse → power switch → E-stop (NC) → L298N |
| Motion profile | 0.5 s soft start and stop; slow zone (≈ 43% PWM) in the last 20 mm before the top; with the 130 RPM fallback, full PWM while lifting |

---

## 5. Structure (7 mm MDF, tab-and-slot, box beams)

| Part | Dimensions | Role |
|---|---|---|
| Base box | 450 × 300 × 100 (7 mm plates, 86 mm ribs, divider) | Footing, electronics bay, counterweight compartment |
| Counterweight | 2.0 kg (steel), 120 × 40 × 100 compartment behind the mast | Tipping resistance |
| Mast | 50 × 50 box, 561 long (468 above the base), finger-jointed | Carries the arm moment to the base |
| Arm | 50 × 50 box, 465 long, finger-jointed, top at Y = 618 | Carries the pulley 400 from the mast centre |
| Brace | 2 × 7 mm strips glued (40 × 14), tabs + M4 × 60 cross-bolts | Stiffens the mast–arm joint (compression) |
| Gussets | 2 × 150 × 150 triangles, 2 dowels + 2 × M4 × 80 | Mast–arm joint |
| Block stacks | 36 × 36 × 7 blocks, 5 per stack on 2 Ø6 dowels | Solid material wherever a bolt passes |

**Checks at rated load (φ = 1.3)**
| Check | Result | Required | Status |
|---|---|---|---|
| Arm bending (MDF ≈ 20 MPa) | σ ≈ 0.6 MPa → SF ≈ 34 | ≥ 3 | ✅ |
| Arm tip deflection (E ≈ 2.5 GPa) | ≈ 0.45 mm | ≤ L/200 ≈ 2 mm | ✅ |
| Brace buckling (40 × 14, L ≈ 266) | P_cr ≈ 3.2 kN vs ≈ 61 N → SF ≈ 52 | ≥ 3 | ✅ |
| Tipping about the base front edge | SF ≈ 2.5 or more (the taller base adds mass behind the edge) | ≥ 1.5 | ✅ |
| Rope | SF ≈ 14 | ≥ 5 | ✅ |
| Z-part plates (PETG) | SF ≈ 8 | ≥ 3 | ✅ |
| Motor torque (20 RPM / Ø30) | SF ≈ 3 | ≥ 1.5 | ✅ |

Re-run the tipping and arm checks with the real masses once the crane is built, using the guide's stress calculator.

---

## 6. Load sensing and conditioning

| Item | Value |
|---|---|
| Excitation | 5.00 V (ratiometric with the Uno ADC) |
| Load cell output | 1 mV/V × 5 V = 5 mV at 5 kg → **1.0 mV/kg** |
| Instrumentation amplifier | **INA125P**, G = 4 + 60 kΩ / RG |
| Gain resistor | **RG = 91 Ω** → G ≈ 663 (1 mV/V); **RG = 180 Ω** → G ≈ 337 (2 mV/V) |
| Output reference (zero) | **0.42 V** from a 10 kΩ / 910 Ω divider through a buffer (MCP6002 / **LM358**), or a 1 kΩ / 91 Ω divider + 10 µF |
| Amplifier output | 0.42 V + 0.663 V/kg → **1.75 V at 2 kg** |
| Filter | 16 kΩ + 1 µF low-pass (≈ 10 Hz) into **A0** |
| Resolution | 4.89 mV per ADC count ÷ 663 mV/kg ≈ **7.4 g** per count |
| Firmware | Moving average + tare (empty basket) + one-point calibration (1.000 kg) |
| Alternatives | AD623 (RG 150 Ω, REF 0.42 V), AD620 (RG 75 Ω, REF 1.5 V). HX711 not allowed. |

**Other sensors in the load system**
| Sensor | Role in the load design |
|---|---|
| ACS712-05B on A1 | Motor current. **Jam**: > 1.5 A for 0.3 s while lifting → stop |
| Motor encoder (D2 / D3) | Hook height (zero at the top switch), soft bottom limit, motion check |
| KW11-3Z on A2 | Top limit (§3.7) |

---

## 7. Safety limits (Uno firmware, 50 ms loop)

| Rule | Setting |
|---|---|
| `RATED_MAX_KG` | **1.5** |
| Overload | Weight > 1.5 kg for 3 readings → stop, latch, lifting blocked, lowering allowed |
| Near-limit warning | ≥ 90% (1.35 kg), yellow LED |
| Overload reset | Only when ≤ 95% (1.43 kg) |
| Top limit | Switch pressed → no lifting; slow zone in the last 20 mm |
| Soft bottom | 5 mm above the table (after homing); also stops when the load lands (< 0.03 kg) |
| Lowering timeout | 15 s |
| Jam | Current > 1.5 A for 0.3 s while lifting, or encoder < 3 mm/s for 0.4 s while driven |
| Link loss | No heartbeat for 2 s → stop app-started motion |
| E-stop | NC, cuts the motor's 12 V in hardware |

---

## 8. Acceptance tests

| # | Test | Pass |
|---|---|---|
| L1 | Zero: empty basket, tare | 0.00 ± 0.01 kg |
| L2 | Calibration: 0.5 / 1.0 / 1.5 kg vs the kitchen scale | Within ± 0.05 kg (≈ ± 3%) |
| L3 | Repeatability: 1.0 kg lifted and lowered 5 times | Spread ≤ 0.03 kg |
| L4 | Overload: lift 1.6 kg | Stops at lift-off, OVERLOAD latched, lowering works |
| L5 | Top limit: lift to the top 10 times | Stops every time, ≥ 5 mm from the pulley |
| L6 | Self-lock: 1.5 kg at mid-height, power off | No drop |
| L7 | Mount alignment: 0 → 1.5 kg | No visible tilt; bar never touches a plate |
| L8 | Pulley: 20 lift/lower cycles at 1.5 kg | Wheel turns freely, rope stays in the groove, no fraying |
| L9 | Proof load: 1.9 kg hung 10 min (motor off) | No creak, crack or visible deflection; base stays flat |
| L10 | Jam: hold the drum lightly while lifting | Stops within 0.5 s |

---

## 9. Load-system hardware summary

| Item | Qty |
|---|---|
| M4 × 40 + nylock + 2 washers (load cell) | 4 |
| M3 × 20 + nylock (lug pins) | 2 |
| M4 × 30 + nylock + 2 washers (pulley axle) | 1 |
| M3 × 65 + nylock + 2 washers (U-bracket and switch bracket to the arm) | 4 |
| M2.5 × 12 + nut (limit switch) | 2 |
| Braided PE line 0.6 mm, ≥ 30 kg | 3 m |
| Basket + cord | 1 |
| Counterweight 2 kg | 1 |
| Printed: Z-part × 2, wheel, sleeve, 2 spacers, U-bracket, drum (after the motor) | — |
| Vaseline, small zip ties | — |
