# Crane Overload: 3D-printed parts

All files are in mm and already **turned the right way for printing**: just place them on the bed. Material: **PETG**.

| File | Print | How it sits on the bed | Infill / walls |
|---|---|---|---|
| `00_tolerance_test_PRINT_FIRST.stl` | 1 | Flat (plate + 4 rings) | 100% |
| `01_load_cell_z_part_PRINT_x2.stl` | **2** | On its side (the 14 mm width is the height) | 4 walls, 50% |
| `02_pulley_wheel.stl` | 1 | Flat | 100%, 0.12–0.16 mm layers |
| `03_pulley_sleeve.stl` | 1 (print 2 if you want a spare) | Standing up | 100% |
| `04_pulley_spacers_x2.stl` | 1 file = 2 rings | Flat (0.5 mm thick) | 100% |
| `05_pulley_u_bracket.stl` | 1 | Base on the bed, cheeks up | 5 walls, 60% |

No supports are needed for any part. Turn on **elephant-foot compensation** (about 0.2 mm) in the slicer.

## 1. Print the tolerance test first (about 10 min)
Print `00_tolerance_test` and one `03_pulley_sleeve`:
- **M4 row:** the smallest hole an M4 bolt passes through freely (1 dot = Ø4.2 … 5 dots = Ø4.6). The design uses **Ø4.4**.
- **M3 row:** the same with an M3 bolt. The design uses **Ø3.4**.
- **Rings:** slide each ring onto the printed sleeve. Pick the one that spins freely without wobbling (1 notch = Ø7.1 … 4 notches = Ø7.4). The design uses **Ø7.3**.

If your results match, print everything. If not, send the results and the parts will be adjusted.

## 2. Main sizes
| Part | Size (mm) |
|---|---|
| Z-part | 48 × 14 × 30; plate 6, boss 20 × 14 × 10, lug R8; pin hole Ø5, rope hole Ø4; M4 holes Ø4.4 at −35 / −25 from the lug |
| Wheel | Ø24 × 6.0; rope groove 3.5 deep, 4.4 wide, 1.6 flat bottom (Ø17); bore Ø7.3 |
| Sleeve | Ø7.0 / Ø4.3 × 7.5 |
| Spacer rings | Ø11 / Ø7.4 × 0.5 |
| U-bracket | 28 × 17.6 × 24; base 5, cheeks 5 with a 7.6 gap; axle hole Ø4.4, 16 below the base top; M3 holes Ø3.4 at +3 / +13 from the axle |

## 3. Hardware
| Item | Qty | Use |
|---|---|---|
| M4 × 40 bolt + nylock nut + 2 washers | 4 | Z-parts to the load cell (each end to its own part only) |
| M3 × 20 bolt + nylock nut | 2 | Pins through the Z-part lugs (rope loop / basket loop) |
| M4 × 30 bolt (threads are fine) + nylock nut + 2 washers | 1 | Pulley axle (washers outside the cheeks) |
| M3 × 65 bolt + nylock nut + 2 washers | 2 | U-bracket to the arm, through the block stack |
| Vaseline | a little | Inside the wheel bore |

## 4. Pulley assembly
1. Grease the sleeve, slide the wheel on, with a spacer ring each side.
2. Put it between the cheeks; the sleeve ends touch the cheeks.
3. M4 × 30 through cheek, sleeve, cheek; washer + nylock outside. Tighten snug: the sleeve is clamped and the wheel spins freely.
4. Bolt the bracket under the arm tip with 2 × M3 × 65 from the top of the arm (holes at 428 / 438 mm from the mast end).

The `STEP` folder has the same parts for editing in Inventor or SolidWorks.
