# Load cell + AD620 amplifier ↔ Arduino Uno A0

This circuit weighs the load on the hook. It is the crane's **analog sensor with signal conditioning**: the load cell gives a signal of only a few millivolts, the AD620 amplifies it ~275×, an LM358 provides a stable reference so the signal sits in the middle of the usable range, and an RC filter removes noise before the Uno's ADC reads it on **A0**.

![Load cell wiring](<../wiring diagrams/load-cell-AD620-wiring.png>)

```
Load cell ──► AD620 (gain 275) ──► 16 kΩ ──┬──► A0
 (bridge)          ▲ REF                     │
                   │                       1 µF
            LM358 follower                   │
                   ▲                        GND
          2.2 kΩ / 1 kΩ divider (1.56 V)
```

---

## 1. The load cell

A 5 kg bar load cell is a metal beam with four **strain gauges** glued on it, wired as a **Wheatstone bridge**. When the beam bends under load, two gauges stretch and two compress, so the bridge's two middle points move apart by a tiny voltage.

| Wire | Name | Connects to | Why |
|---|---|---|---|
| **Red** | E+ (excitation +) | **5V** | powers the bridge |
| **Black** | E− (excitation −) | **GND** | |
| **Green** | S+ (signal +) | AD620 **pin 3** (+IN) | bridge output, goes up with load |
| **White** | S− (signal −) | AD620 **pin 2** (−IN) | bridge output, goes down with load |

**How small the signal is:** a typical cell gives **1 mV per volt of excitation at full load** (1 mV/V). At 5 V excitation and 5 kg capacity:
- full load (5 kg): 5 V × 1 mV/V = **5 mV**
- **1 kg → 1 mV**, 1.5 kg (our max) → 1.5 mV

The Uno's ADC step is 4.9 mV, so it cannot see 1 mV directly. That's why it needs amplification.

Both signal wires sit at about **2.5 V** (half of the 5 V excitation); only their *difference* carries the weight. The AD620 amplifies only that difference and ignores the common 2.5 V.

If the weight goes **negative** when you add load, green and white are swapped: swap them and tare again.

---

## 2. AD620 instrumentation amplifier

An instrumentation amplifier amplifies the **difference** between its two inputs, rejects what they have in common (noise picked up by both wires, the 2.5 V bridge midpoint), and has very high input resistance so it doesn't load the bridge.

| AD620 pin | Name | Connects to | Why |
|---|---|---|---|
| 1 and 8 | RG | **180 Ω** between them | sets the gain |
| 2 | −IN | load cell **white** | |
| 3 | +IN | load cell **green** | |
| 4 | −Vs | **GND** | single 5 V supply |
| 5 | REF | **1.56 V** from the LM358 | sets the output when the load is 0 (see section 3) |
| 6 | OUT | **16 kΩ** → A0 | the amplified signal |
| 7 | +Vs | **5V**, with **100 nF** from pin 7 to pin 4 right at the chip | supply + local decoupling |

**Gain:** `G = 1 + 49.4 kΩ / RG = 1 + 49400 / 180 = 275.4`

**Output:** `V_out = V_REF + G × (V_green − V_white)`
- empty: 1.56 V
- 1 kg (1 mV): 1.56 + 0.275 = **1.84 V**
- 1.5 kg: 1.56 + 0.41 = **1.97 V**
- with a 2 mV/V cell everything doubles: 0.55 V per kg

**Why RG = 180 Ω:** enough gain to make 1 kg worth ~56 ADC steps, while the output stays far below the AD620's upper limit even well above 1.5 kg (room for about 8 kg with a 1 mV/V cell, so overload can never saturate the reading).

**Why the 100 nF capacitor:** the chip needs a clean local supply. The capacitor right at pins 7–4 supplies fast current spikes and shorts high-frequency noise on the 5 V line to ground. Keep its legs short.

---

## 3. REF = 1.56 V from the LM358 (why not 0 V, why buffered)

**Why not REF = 0 V?** On a single 5 V supply the AD620's output can only swing about **1.2 V to 3.8 V**; it cannot go down to 0 V. With REF at 0 V, an empty basket would ask for ~0 V, which the chip can't give, so small weights would read as nothing and a small negative offset would be invisible. Lifting REF to **1.56 V** puts the zero point just inside the usable range, and the weight then pushes the output *up* towards 3.8 V.

**The divider:** 2.2 kΩ from 5V, 1 kΩ to GND:
```
V = 5 V × 1 kΩ / (2.2 kΩ + 1 kΩ) = 5 / 3.2 = 1.5625 V
```

**Why the LM358 buffer?** The AD620's REF pin is not a high-impedance input: it connects to internal ~10 kΩ resistors and current flows in or out of it. Connected straight to the divider, that current would pull the divider's voltage and **change the gain and the zero**. The LM358 wired as a **voltage follower** copies the divider voltage with almost no current from the divider, and can supply whatever current the REF pin needs.

| LM358 pin | Connects to | Why |
|---|---|---|
| 8 | **5V** | supply |
| 4 | **GND** | |
| 3 (+IN A) | divider middle point (1.56 V) | input of the follower |
| 2 (−IN A) | joined to pin 1 | 100 % feedback = follower (gain 1) |
| 1 (OUT A) | pins 2 **and** AD620 **pin 5** | the buffered 1.56 V |
| 7 + 6 | joined together | unused half B also made a follower… |
| 5 | **GND** | …with its input at GND, so it can't oscillate or pick up noise |

---

## 4. RC low-pass filter: 16 kΩ + 1 µF → A0

```
f_c = 1 / (2π × R × C) = 1 / (2π × 16 000 × 0.000 001) ≈ 10 Hz
```
- The weight changes slowly (a load swinging on the hook is a few Hz at most), so everything above ~10 Hz is **noise**: mains 50 Hz hum picked up by the wires, motor noise later, switching noise from the Uno. The filter removes it.
- It is also the **anti-aliasing** filter for the ADC.
- The 1 µF capacitor acts as a charge reservoir for the ADC's sampling capacitor, so the 16 kΩ resistance (above the 10 kΩ the ATmega datasheet recommends) doesn't cause sampling errors.
- The 16 kΩ also limits the current into A0 if anything goes wrong.

The firmware filters further: 64 readings averaged (~7 ms) and an exponential filter (α = 0.2).

**10 µF across 5V–GND** (near the Uno): bulk capacitor that keeps the shared 5 V steady when the HC-05 transmits or other parts switch.

---

## 5. Arduino A0 and the numbers in the firmware

| Quantity | Value |
|---|---|
| ADC | 10-bit, reference = 5 V (`analogReference(DEFAULT)`) → 5 / 1023 = 4.89 mV per step |
| Empty basket | ≈ 1.56 V ≈ 320 counts (`Zero` from tare) |
| Default slope (1 mV/V cell, before calibration) | 0.275 V/kg = **56.4 counts/kg** (≈ 18 g per step) |
| Constants (`load_cell.cpp`) | `RG_OHM 180`, `GAIN 275.4`, `EXCITATION 5.0`, `CELL_CAPACITY_KG 5.0`, `OVERSAMPLE 64`, `FILTER_ALPHA 0.2` |

**Why the excitation is the same 5 V as the ADC reference:** the bridge output and the ADC both scale with the 5 V supply (a **ratiometric** measurement). If USB gives 4.9 V instead of 5.0 V, the signal and the ADC scale shrink together, so the weight stays almost correct.

**Calibration** (Serial Monitor 115200, Newline): `t` with the basket empty (zero), then `c 1000` with a known 1 kg (slope). Both are saved in EEPROM. `s` shows the result, including the cell's real sensitivity in mV/V.

---

## Quick checks with a multimeter (to GND)

| Point | Expected |
|---|---|
| Load cell red / black | 5 V / 0 V |
| Green and white, empty | both ≈ 2.5 V, within a few mV of each other |
| LM358 pin 3 (divider) and pin 1 | ≈ 1.56 V on both |
| AD620 pin 5 (REF) | ≈ 1.56 V |
| AD620 pin 6 / A0, empty | ≈ 1.5 – 1.7 V |
| A0 with 1 kg | ≈ +0.28 V more (1 mV/V cell) or +0.55 V (2 mV/V) |

| Problem | Likely cause |
|---|---|
| A0 stuck ≈ 1.2 V or lower | REF missing (check LM358, divider), or green / white swapped |
| A0 stuck ≈ 3.8 V | input wire loose (an open input drifts to the rail), RG missing |
| Weight negative when loaded | green / white swapped → swap, `t` |
| Weight jumps | loose breadboard wire, missing 100 nF, long unshielded cell wires |
| Reading drifts slowly for a few minutes after power-up | normal warm-up of the bridge; tare after ~2 min |
