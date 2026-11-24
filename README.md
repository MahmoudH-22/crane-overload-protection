# Crane Overload Protection (MCT332s)

The full step-by-step build is in the project guide (`crane-project-guide.html` → "Implementation A–Z").

Quick start:
1. `firmware/uno/crane_uno_m2`: set the parts in `config.h`, then upload to the Uno (see its `README.md`).
2. Pair the HC-05 with the Android phone (Settings → Bluetooth, PIN 1234). Not found? Reset it with `firmware/uno/hc05_setup`.
3. `app/`: `flutter pub get`, then `flutter run`. Connect → Crane → pick the HC-05.
4. No hardware? `mosquitto -c tools/mosquitto.conf -v` and `python tools/crane_sim.py` (needs `pip install paho-mqtt`), then Connect → Simulator with the laptop IP.

Wiring and why: `docs/exp/`. App summary: `docs/app-design.md`.

Read `CLAUDE.md` first. Log daily work in `history/`.
