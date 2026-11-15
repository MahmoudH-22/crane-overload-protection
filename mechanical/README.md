# Crane overload protection: CAD package for SolidWorks

Every part of the crane as a solid model (STEP), the full assembly, 1:1 DXF cutting/drilling templates, a bill of materials, and an interference report. All dimensions are in **millimetres**.

| Folder / file | What it is |
|---|---|
| `step/CR-00_crane_assembly.step` | The full assembly: 37 part instances, coloured, in their working positions |
| `step/CR-01 … CR-31 *.step` | One file per unique part (31), each at its own origin |
| `dxf/*.dxf` | 1:1 templates: lid cutouts, motor plate, encoder bracket flat pattern, Z-mount plates, base drilling, box side panel |
| `bom.csv` | Bill of materials: part no., qty, make/buy, material, size, mass, notes |
| `interference_report.txt` | Solid-solid interference check with the hook at the bottom, middle and top |
| `crane-cad-preview.html` | Offline viewer of the exact STEP geometry: open it in a browser to check before SolidWorks |
| `preview_*.png` | Screenshots of the CAD assembly |
| `source/` | The parametric scripts that generate everything (CadQuery, Python). Change a value and re-run to regenerate. |

## 1. Open it in SolidWorks

1. **File → Open**. Set the file type to **STEP AP203/214/242 (\*.step; \*.stp)** and pick `step/CR-00_crane_assembly.step`.
2. In **Options…**, make sure the import creates an **assembly** with each body as a separate **part**. Then click **Open**.
3. Set the units: **Tools → Options → Document Properties → Units → MMGS**.
4. **Save** the assembly as `CR-00_crane_assembly.SLDASM`. If SolidWorks shows the parts as virtual components, right-click each one, choose **Save Part (in External File)**, and keep the `CR-xx` names.
5. To open a single part instead, open its `CR-xx_*.step` file and save it as `.SLDPRT`.

**Coordinates:**
- **Y** is up, so the crane stands upright in the **Front** view.
- **+X** points toward the hook, and **+Z** toward the viewer.
- In the assembly, the mast centre is at X = 0, Z = 0, and the table top is at Y = 0.

**Editable features:** imported parts arrive as solid bodies without a feature tree. You have two options:
- Run **FeatureWorks**: Insert → FeatureWorks → Recognize Features → Automatic. It's included in SolidWorks Professional/Premium and most education licences. It turns the holes and extrudes into editable features.
- Rebuild the **Make** parts natively with section 3 (recommended for the parts shown in your report drawings). Keep the **Buy** parts as imported envelopes, or swap them for vendor models.

## 2. Bill of materials

| Part | Name | Qty | Make / Buy | Material | Size X × Y × Z (mm) |
|---|---|---|---|---|---|
| CR-01 | Base board | 1 | Make | MDF 18 mm | 450.0 x 18.0 x 300.0 |
| CR-02 | Mast | 1 | Make | Pine 40 x 40 | 40.0 x 550.0 x 40.0 |
| CR-03 | Arm | 1 | Make | Pine 40 x 40 | 450.0 x 40.0 x 40.0 |
| CR-04 | Diagonal brace | 1 | Make | Pine 20 x 40 | 193.5 x 214.9 x 40.0 |
| CR-05 | L-bracket 50 (mast-base) | 2 | Buy | Steel 2 mm, bought | 15.0 x 50.0 x 50.0 |
| CR-06 | Corner plate (mast-arm) | 2 | Buy | Steel 2 mm, bought | 80.0 x 90.0 x 2.0 |
| CR-07 | Counterweight | 1 | Make | Steel plates / sand-filled box, 2.0 kg | 120.0 x 45.0 x 120.0 |
| CR-08 | Motor plate | 1 | Make | MDF 10 mm | 10.0 x 90.0 x 200.0 |
| CR-09 | Worm gear motor JGY-370 12 V | 1 | Buy | Bought (simplified) | 41.0 x 44.0 x 80.0 |
| CR-10 | Rope drum | 1 | Make | PLA, 3D printed, 40 % infill | 42.0 x 42.0 x 46.0 |
| CR-11 | Stub shaft 6 mm | 1 | Make | Steel rod 6 mm | 6.0 x 6.0 x 32.0 |
| CR-12 | Flexible coupler 6-6 | 1 | Buy | Aluminium, bought | 19.0 x 19.0 x 25.0 |
| CR-13 | Encoder 600 P/R (LPD3806) | 1 | Buy | Bought (simplified) | 38.0 x 38.0 x 51.0 |
| CR-14 | Encoder bracket | 1 | Make | Aluminium 3 mm (or PLA) | 55.0 x 85.0 x 33.0 |
| CR-15 | Pulley wheel 24 mm (624ZZ) | 1 | Buy | Aluminium V-groove with 624ZZ, bought | 24.0 x 24.0 x 6.0 |
| CR-16 | Pulley U-bracket | 1 | Make | Aluminium 3 mm (or PLA) | 30.0 x 28.0 x 13.2 |
| CR-17 | Pulley axle M4 x 20 | 1 | Buy | Steel bolt + nylock, bought | 7.0 x 7.0 x 20.0 |
| CR-18 | Limit switch (roller micro switch) | 1 | Buy | Bought (simplified) | 20.5 x 24.5 x 6.0 |
| CR-19 | Limit switch mount | 1 | Make | PLA, 3D printed | 25.0 x 15.0 x 10.0 |
| CR-20 | Z-mount top plate | 1 | Make | Aluminium 3 mm | 80.0 x 3.0 x 20.0 |
| CR-21 | Spacer 12 x 12 x 10 | 2 | Make | Aluminium / PLA | 12.0 x 10.0 x 12.0 |
| CR-22 | Load cell 5 kg (TAL220 type) | 1 | Buy | Bought (simplified) | 80.0 x 12.7 x 12.7 |
| CR-23 | Z-mount bottom plate | 1 | Make | Aluminium 3 mm | 80.0 x 3.0 x 20.0 |
| CR-24 | S-hook | 1 | Buy | Steel, bought | 20.0 x 30.0 x 4.0 |
| CR-25 | Basket 70 x 60 x 70 | 1 | Buy | Plastic, bought | 70.0 x 60.0 x 70.0 |
| CR-26 | Electronics box | 1 | Buy | ABS project box 200 x 120 x 75 | 200.0 x 72.0 x 120.0 |
| CR-27 | Lid with control panel | 1 | Make | ABS lid 3 mm (box lid) | 200.0 x 3.0 x 120.0 |
| CR-28 | Shield PCB 120 x 90 | 1 | Make | FR-4 1.6 mm, ordered | 120.0 x 1.6 x 90.0 |
| CR-29 | Standoff M3 x 14 | 4 | Buy | Brass, bought | 5.5 x 14.0 x 5.5 |
| CR-30 | Arduino Uno R3 | 1 | Buy | Bought (simplified) | 68.6 x 1.6 x 53.3 |
| CR-31 | L298N module | 1 | Buy | Bought (simplified) | 43.0 x 26.0 x 43.0 |

## 3. Native rebuild sheet (Make parts)

In each SolidWorks part, set the origin as described so the mates below are simple.

| Part | Plane and sketch | Features |
|---|---|---|
| **CR-01 Base** | Top plane: rectangle 450 × 300, origin at the **mast centre** (300 from the back edge, centred across) | Extrude 18. Hole Wizard (from the mast centre, X toward the hook, Z toward you): 4 × Ø4 at (0, ±45) and (0, ±62); 4 × Ø3.2 at (−250, 40) (−140, 40) (−250, 120) (−140, 120); 4 × Ø5.5 at (−200, −130) (−100, −130) (−200, −30) (−100, −30). Same as `dxf/CR-01_base_drilling.dxf`. |
| **CR-02 Mast** | Top plane: centre square 40 × 40 | Extrude 550. 2 × Ø4 through (along X) at 62 and 112 mm from the bottom, centred. |
| **CR-03 Arm** | Front plane: rectangle 450 × 40, origin 20 mm from the back end | Extrude mid-plane 40. Pilot holes Ø2.5 under the arm at 392 / 408 mm from the mast centre (pulley bracket) and at 420 / 430 (switch mount). |
| **CR-04 Brace** | Front plane: 4-point polygon with corners (20, 353.1) (213.5, 568) (186.5, 568) (20, 382.9), in mm with the mast centre / table origin | Extrude mid-plane 40. The ends sit flush on the mast face and the arm underside. |
| **CR-07 Counterweight** | Top plane: centre rectangle 120 × 120 | Extrude 45. 4 × Ø5.5 at 10 mm from each corner. Make it 2.0 kg (steel plates or a sand-filled box). |
| **CR-08 Motor plate** | Right plane: rectangle 200 × 90 | Extrude 10. Holes per `dxf/CR-08_motor_plate.dxf`: 2 × Ø4.5 to the mast, 4 × Ø3.2 for the motor bracket, 2 × Ø3.2 for the encoder bracket. |
| **CR-10 Rope drum** | Front plane: half-profile for a **revolve**, with core Ø30 × 40 and flanges Ø42 × 3 on both ends | Revolve 360°. Cut a Ø6.1 bore through. Ø2 radial rope hole 6 mm off-centre. Ø3.2 radial grub-screw hole on the motor side. 3D print in PLA, 40% infill. |
| **CR-11 Stub shaft** | Cylinder Ø6 × 32 | 6 mm silver steel rod, pressed into the drum from the encoder side. |
| **CR-14 Encoder bracket** | **Sheet metal**: base flange 55 × 85, t = 3 | Edge flange 30 at 90°. Ø21 hole for the encoder boss and 2 × Ø3.2 at ±15 mm (check your encoder). 2 × Ø3.2 in the flange. Flat pattern in `dxf/CR-14_encoder_bracket_flat.dxf`. |
| **CR-16 Pulley U-bracket** | **Sheet metal**: base 30 × 13.2, t = 3 | Two 25 mm flanges down (inside gap 7.2). Ø4.2 axle hole 13 mm below the base. Ø3.5 screw hole in the base. |
| **CR-19 Switch mount** | Rectangle 25 × 15 | Extrude 10. 2 × Ø2.2 (M2) 10 mm apart, slotted 3 mm to adjust the trip point. Print in PLA. |
| **CR-20 / CR-23 Z-mount plates** | Rectangle 80 × 20 | Extrude 3 (aluminium). Top plate: Ø3.2 centre (rope eye) + Ø4.2 at 8 mm from the left end. Bottom plate: Ø3.2 centre (hook eye) + Ø4.2 at 8 mm from the right end. |
| **CR-21 Spacer** | Square 12 × 12 | Extrude 10, Ø4.2 through. Make 2. |
| **CR-27 Lid** | Top plane: rectangle 200 × 120 | Extrude 3. Cuts per `dxf/CR-27_lid_cutout.dxf`: LCD window 71 × 24 + 4 × Ø3.2; LEDs 3 × Ø5.2; E-stop Ø22.5; LIFT / LOWER / STOP / RESET 4 × Ø16.2; MODE key Ø19.2; power switch 19 × 13; buzzer 6 × Ø3; 4 × Ø3.2 lid screws. |
| **CR-28 PCB** | Rectangle 120 × 90 | Extrude 1.6. 4 × Ø3.2 at 5 mm from the corners. The real board comes from the KiCad design. |

## 4. Assembly mates

1. **Base** fixed at the origin.
2. **Mast**: bottom face coincident with the base top; axes centred on the base origin (X = 0, Z = 0).
3. **Arm**: bottom face coincident with the mast top; back face 20 mm behind the mast centre; centred in Z.
4. **Brace**: faces coincident with the mast front face and the arm underside; centred in Z.
5. **L-brackets / corner plates**: on the mast side faces (Z = ±20).
6. **Counterweight**: bottom on the base; centre at X = −150, Z = −80.
7. **Motor plate**: back face on the mast front face (X = 20); centred in Z; bottom edge at Y = 60.
8. **Motor bracket** on the motor plate. **Drum** concentric with the motor shaft; drum flange face against the gearbox face (Z = −23).
9. **Stub shaft**, **coupler** and **encoder**: concentric with the drum. Coupler from Z = 33 to 58; encoder flange face against the bracket (Z = 60).
10. **Encoder bracket**: flange on the motor plate face (X = 30).
11. **Pulley U-bracket**: base on the arm underside; axle hole centre at X = 400, Y = 552. **Wheel** and **axle** concentric with the hole.
12. **Switch mount**: on the arm underside, X = 415–440, Z = 0–10. The switch roller sits at X = 417, Z = 5.
13. **Load cell stack**: top plate centre on the rope line X = 412. Then spacer → bar → spacer → bottom plate → hook → basket.
14. **Electronics box**: on the base at X −280 to −80, Z 20 to 140. **Lid** on top. **PCB** on 14 mm standoffs.

For a working-range check, add a **distance mate** from the table (Y = 0) to the basket bottom and drive it from **0 to 380 mm**. Then run **Tools → Evaluate → Interference Detection** at a few values. Expect zero clashes; at 380 mm the switch roller just presses the top plate.

## 5. Drawings for the report

- **Assembly drawing (A3):** isometric + front + side views, balloons, and an inserted **BOM table** (use the CR numbers and `bom.csv` descriptions as custom properties *PartNo*, *Description*, *Material*).
- **Detail drawings (A4):** CR-01 base, CR-27 lid, CR-10 drum, CR-08 motor plate, CR-14 / CR-16 brackets, CR-20 / CR-23 plates. Dimension the holes from one datum corner.
- **Exploded view:** Insert → Exploded View. Use it for the manual's assembly page.

## 6. What the CAD check found and changed

- **Interference:** 0 unexpected clashes with the basket at 0, 200 and 380 mm (`interference_report.txt`).
- **Limit switch moved 7 mm inward:** the earlier position (roller at Z = 10.5–13.5) missed the load cell top plate (Z = ±10), so the switch would never have tripped. Now the roller is at Z = 3.5–6.5 and presses the plate by about 0.5 mm at the top.
- **Hook travel is 0–380 mm** (was 250), so the basket can be set down on the table. In the firmware, set `TOP_HEIGHT_MM = 380`.
- **Bottom plate:** the load cell screw hole is Ø4.2 (M4 clearance).

**Bought parts** (motor, encoder, load cell, coupler, switch, Uno, L298N, box) are simplified envelopes with the correct outer size and mounting features. Replace them with vendor CAD models if you want detailed renders.
