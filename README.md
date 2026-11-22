# Crane Overload Protection (MCT332s)

The full step-by-step build is in the project guide (`crane-project-guide.html` → "Implementation A–Z").

Quick start:
1. `broker/`: run `mosquitto -c mosquitto.conf -v` on the laptop (on the phone hotspot).
2. `firmware/uno/crane_uno`: set the feature flags, then upload to the Uno.
3. `firmware/nodemcu/crane_nodemcu`: set the Wi-Fi and broker IP, then upload to the NodeMCU ("NodeMCU 1.0 (ESP-12E Module)").
4. `app/`: `flutter pub get`, then `flutter run`. Enter the laptop IP on the connect screen.
5. No hardware? `mosquitto -c tools/mosquitto.conf -v` and `python tools/crane_sim.py` (needs `pip install paho-mqtt`).

Read `CLAUDE.md` first. Log daily work in `history/`.
