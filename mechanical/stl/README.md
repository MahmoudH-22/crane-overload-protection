# Crane Overload: motor drive (printed parts)

For the **25GA370, 12 V, 45 : 1 (130 RPM)** motor with encoder. Material **PETG**, no supports. Every file is already turned the right way for printing.

| File | Print | On the bed | Settings |
|---|---|---|---|
| `06_motor_bracket_base.stl` | 1 | Base flat on the bed, walls up | 5 walls, 60% infill |
| `07_rope_drum.stl` | 1 | Standing on its D-bore end | **100% infill**, 0.16 mm layers |
| `08_drum_outboard_support.stl` | 1 | Foot flat on the bed | 5 walls, 60% infill |

Turn on about 0.2 mm elephant-foot compensation. Use the tolerance test from the first print pack: if your Ø4.4 / Ø7.3 results were different, say so before printing, and the bore and journal sizes will be adjusted.

## Key sizes (mm)
| Feature | Size |
|---|---|
| Base | 72 × 64 × 5; 2 × Ø4.5 on the existing mast-bolt holes + 2 × Ø3.4 on the existing old motor-bracket holes: **no drilling** |
| Motor wall | 4 thick; Ø7.6 hole for the Ø7 boss; 2 × M3 countersunk holes 17 apart |
| Motor axis | 27 in front of the motor plate, 42 above its bottom edge; the drum's rope area is centred on the plate's centre line (in line with the pulley) |
| Drum | Core Ø10, 13 flat + 5 mm 45° cone, flanges Ø20 × 2, total 22 long |
| Drum bore | Ø4.15 D, 3.6 across the flat, 7.5 deep: **6.9 mm on the shaft** |
| Drum journal / support hole | Ø7.0 × 6.4 / Ø7.4 |
| Gaps | 0.6 between the drum and each wall |
| Rope | 0.6 mm braided PE: 380 mm ≈ 11.4 turns + 5 spare ≈ 10 mm of the 13 mm flat (one layer) |

## Hardware
| Item | Qty |
|---|---|
| **M3 × 6 countersunk** (flat head), motor face to the wall. **Never longer than M3 × 7**: deeper than 3 mm hits the gears. | 2 |
| **M4 × 90** + washers + nylock: the 2 mast bolts, now also through the base and the support foot (they replace the M4 × 80) | 2 |
| M3 × 25 + washer + nut (old motor-bracket holes, nut behind the plate) | 2 |
| M3 × 4 grub screw (optional, presses on the shaft flat) | 1 |
| Vaseline (journal) | a little |

## Assembly
1. Line the base up on the existing motor plate (P14A + B): its 2 big holes on the 2 mast-bolt holes (on the centre line, 50 apart), its 2 small holes on the old motor-bracket holes (the pair 24 mm apart, 36 mm from the centre line). The motor wall goes on that side. Fix it with 2 × M3 × 25 + nuts behind the plate.
2. Push the drum's D-bore onto the motor shaft (flat to flat) so it ends 0.6 mm from the wall face; tighten the grub screw.
3. Pass the drum through the wall from the back and screw the motor face with 2 × M3 × 6 countersunk.
4. Grease the journal and slide the outboard support over it (its foot runs under the drum to the mast bolts). Fit the 2 × M4 × 90 mast bolts through the support foot, base, motor plate and mast.
5. Turn the drum by hand: smooth, not rubbing either wall.
6. Rope: thread it through the Ø2 hole in the core, tie a stopper knot, and wind it on from the motor side.

The checks before export: all three parts are watertight, nothing clashes with the motor (gearbox, can, encoder), the bolt heads or each other, the shaft engages 6.9 mm in the drum, and the whole drive (encoder end included) stays inside the 200 × 90 motor plate.
