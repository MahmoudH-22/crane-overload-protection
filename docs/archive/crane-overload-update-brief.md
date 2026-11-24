# Code session brief: update the `crane-overload` folder

Attach this file and `crane-overload-update.zip` at the start of a Claude Code session opened on the project folder.

**Project folder:** `U:\My Projects\crane-overload`
**Update package:** `crane-overload-update.zip` (unzips to a `crane-overload/` folder with 70 files)

---

## Goal

Bring the project folder up to date with everything designed and built in the planning chats (14–24 Nov 2026): firmware, wiring diagrams, laser and print files, 3D models, docs, report figures, `CLAUDE.md` and the daily history, **without losing anything the team has made on the PC**.

## Rules

1. **Inspect first.** Show the current folder tree (2 levels) and say what you will add, replace, merge and archive before changing anything.
2. **Never touch `mechanical/CAD/`** (Inventor / SolidWorks files made by the team).
3. **Never delete.** Anything superseded goes to `docs/archive/` (keep its name; add the date if a name clashes).
4. **If a file already exists:** identical → skip; different → compare dates and content. If the PC copy is newer or was edited by the team, keep it, put the package copy next to it as `<name>.from-update.<ext>`, and list it for me to decide.
5. **Merge, don't overwrite, `CLAUDE.md`** if one already exists: keep the team's sections, add or update the package's sections (stack, folder structure, sensors and pins, MQTT contract, mechanical values, conventions, key decisions, links).
6. **History:** copy `history/2026-11/15-11-2026.md`, `16-11-2026.md`, `24-11-2026.md`; if a file with the same name exists, append the package's content under a `## From the planning chat` heading instead of replacing it. Then add today's entry describing this update.
7. If the folder is a **git repository**, finish with one commit: `Sync project files from planning chats (14–24 Nov 2026)`. Don't push.

## Steps

1. Unzip `crane-overload-update.zip` to a temporary folder (not over the project).
2. Inspect the project folder and report the plan (rule 1). Wait for my OK.
3. Create any missing folders: `firmware/tests`, `electronics/wiring`, `mechanical/laser`, `mechanical/print/STL`, `mechanical/print/STEP`, `models`, `purchasing`, `docs/archive`, `report/images`, `history/2026-11`.
4. Copy the files from the table below following rules 2–4.
5. Move superseded files (section below) into `docs/archive/` if they exist on the PC.
6. Merge `CLAUDE.md` (rule 5) and update `history/` (rule 6).
7. Verify:
   - Every file in the table exists in the project.
   - Arduino sketches are each in a folder with the same name as the `.ino`.
   - If `arduino-cli` is installed: `arduino-cli compile --fqbn arduino:avr:uno firmware/crane_overload_m1` and `firmware/tests/*`; and `--fqbn esp8266:esp8266:nodemcuv2 firmware/crane_nodemcu_m1` (needs the esp8266 core and PubSubClient). Report results; don't install anything without asking.
8. Show the final tree and a short summary (added / replaced / kept / archived / needs my decision).

## Files in the package

| Path in the project |
| --- |
| `CLAUDE.md` |
| `docs/M1-end-to-end-steps.md` |
| `docs/archive/Crane-Overload-Protection-Handbook.pdf` |
| `docs/archive/crane-project-chat-summary.md` |
| `docs/archive/crane-project-guide.html` |
| `docs/crane-app-code-session-brief.md` |
| `docs/crane-load-design-spec.md` |
| `docs/reports-and-links.md` |
| `electronics/wiring/load-cell-AD620-wiring.png` |
| `electronics/wiring/milestone1-wiring-ir-loadcell.png` |
| `electronics/wiring/uno-nodemcu-serial-wiring.png` |
| `firmware/crane_nodemcu_m1/crane_nodemcu_m1.ino` |
| `firmware/crane_overload_m1/crane_overload_m1.ino` |
| `firmware/tests/ad620_probe_voltmeter/ad620_probe_voltmeter.ino` |
| `firmware/tests/load_cell_ad620_test/load_cell_ad620_test.ino` |
| `history/2026-11/15-11-2026.md` |
| `history/2026-11/16-11-2026.md` |
| `history/2026-11/24-11-2026.md` |
| `mechanical/laser/crane-overload-SEND-TO-SHOP.zip` |
| `mechanical/laser/crane-overload-laser-cost.xlsx` |
| `mechanical/laser/crane-overload-laser-cut.zip` |
| `mechanical/print/README-motor-drive.md` |
| `mechanical/print/README-printed-parts.md` |
| `mechanical/print/STEP/drum_outboard_support.step` |
| `mechanical/print/STEP/load_cell_z_part.step` |
| `mechanical/print/STEP/motor_bracket_base.step` |
| `mechanical/print/STEP/pulley_sleeve.step` |
| `mechanical/print/STEP/pulley_spacer.step` |
| `mechanical/print/STEP/pulley_u_bracket.step` |
| `mechanical/print/STEP/pulley_wheel.step` |
| `mechanical/print/STEP/rope_drum.step` |
| `mechanical/print/STEP/tolerance_test.step` |
| `mechanical/print/STL/00_tolerance_test_PRINT_FIRST.stl` |
| `mechanical/print/STL/01_load_cell_z_part_PRINT_x2.stl` |
| `mechanical/print/STL/02_pulley_wheel.stl` |
| `mechanical/print/STL/03_pulley_sleeve.stl` |
| `mechanical/print/STL/04_pulley_spacers_x2.stl` |
| `mechanical/print/STL/05_pulley_u_bracket.stl` |
| `mechanical/print/STL/06_motor_bracket_base.stl` |
| `mechanical/print/STL/07_rope_drum.stl` |
| `mechanical/print/STL/08_drum_outboard_support.stl` |
| `mechanical/print/STL/PRINT-NOTES.txt` |
| `models/crane-printed-parts-check.html` |
| `models/crane-structure-3d.html` |
| `models/hoist-drive-simulation.html` |
| `models/load-cell-z-mount-assembly.html` |
| `purchasing/Crane-Overload-Shopping-List.pdf` |
| `purchasing/crane-shopping-checklist.html` |
| `report/images/acs712_board.png` |
| `report/images/ad620_pinout.jpg` |
| `report/images/hcsr04.png` |
| `report/images/ir_module_photo.jpg` |
| `report/images/ir_module_pins.jpg` |
| `report/images/lm358_pinout.jpg` |
| `report/images/load_cell_breadboard.jpg` |
| `report/images/load_cell_datasheet.jpg` |
| `report/images/load_cell_photo.jpg` |
| `report/images/load_cell_wiring.jpg` |
| `report/images/model_exploded.png` |
| `report/images/model_exploded_crop.png` |
| `report/images/model_hoist.png` |
| `report/images/model_iso.png` |
| `report/images/model_iso_labels.png` |
| `report/images/model_iso_labels_crop.png` |
| `report/images/model_side.png` |
| `report/images/model_tip.png` |
| `report/images/motor_encoder_board.jpg` |
| `report/images/motor_outline.png` |
| `report/images/motor_photo.jpg` |
| `report/images/motor_product.jpg` |

## Superseded files (move to `docs/archive/` if found)

| File or folder | Replaced by |
| --- | --- |
| `crane-3d-model.html` (Oct) | `models/crane-structure-3d.html` |
| `crane-overload-starter.zip` and any old starter firmware folders (e.g. `crane_uno`, `crane_nodemcu` from October) | `firmware/crane_overload_m1`, `firmware/crane_nodemcu_m1` |
| `crane-7mm-mdf-laser-cut.zip` | `mechanical/laser/crane-overload-laser-cut.zip` |
| `crane-3d-print-parts.zip`, `crane-motor-drive-parts.zip`, `crane-SEND-TO-3D-PRINTER.zip` | `mechanical/print/STL` + `mechanical/print/STEP` |
| `crane-firmware-m1.zip`, a separate `crane-firmware/` folder and its own `CLAUDE.md` | `firmware/` + root `CLAUDE.md` |
| Older STEP/STL of the pulley wheel with raised hubs or a 624ZZ bearing pocket | `pulley_wheel.step` (6.0 mm thick, flat faces) + `pulley_spacer.step` |
| `crane-project-guide.html`, `Crane-Overload-Protection-Handbook.pdf`, `crane-project-chat-summary.md` (October/early-November) | Already placed in `docs/archive/` by the package |

## What changed (for the history entry)

- **Firmware:** Uno sketch with IR + load cell + NodeMCU link (D10/D11, checksummed lines); NodeMCU MQTT bridge in the app's message format; test sketches for calibration and node voltages.
- **Electronics:** wiring diagrams for Milestone 1 (IR → D2, load cell → AD620 → A0, REF 2.2 kΩ/1 kΩ), the Uno ⇄ NodeMCU link, and the load cell chain.
- **Mechanical:** print pack 00–08 (tolerance test, Z-parts, pulley wheel/sleeve/spacers/U-bracket, motor bracket, Ø10 drum, outboard support) with STEP sources; laser pack and shop files unchanged.
- **Models:** structure model (IR top sensor, 25GA370 drive, printed pulley and Z-parts), printed parts check, hoist drive simulation, Z-mount assembly.
- **Docs:** load design spec, app code-session brief, Milestone 1 end-to-end steps, report links; report figures in `report/images/`.

## Out of scope

- The Flutter app's code (its own folder/repo; follow `docs/crane-app-code-session-brief.md` there).
- Editing the online reports.
