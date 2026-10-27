# Crane Overload Protection (MCT332s)

The full step-by-step build is in the project guide (`crane-project-guide.html` → "Implementation A–Z").

Quick start:
1. `broker/`: run `mosquitto -c mosquitto.conf -v` on the laptop (on the phone hotspot).
2. `firmware/uno/crane_uno`: set the feature flags, then upload to the Uno.
3. `firmware/nodemcu/crane_nodemcu`: set the Wi-Fi and broker IP, then upload to the NodeMCU ("NodeMCU 1.0 (ESP-12E Module)").
4. `app/`: run `flutter create . --org com.mct332s --project-name crane_monitor`, then `flutter pub get`, then `flutter run`. Set the broker IP in Settings.

Read `CLAUDE.md` first. Log daily work in `history/`.
