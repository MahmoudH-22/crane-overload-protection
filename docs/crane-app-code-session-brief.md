# Code session brief: Crane Overload phone app (Flutter + MQTT)

Paste or attach this file at the start of the Claude Code session. It is the full spec: build the app **and** a small crane simulator, so the app can be developed and demonstrated without the hardware.

---

## 1. Context

**Project:** "Crane Overload", MCT332s Engineering Measurements and Sensors (Fall 2026, Ain Shams University). A tabletop crane that weighs its load, stops before an overload (1.5 kg), stops at the top of travel and detects a jammed motor. It can be operated from a control panel or **remotely from this app**.

**Course requirement (mandatory):** actuation from the app. The app must be able to lift, lower and stop the crane, and show the sensor readings live.

**Team:** Mahmoud Hisham 2400844, Ziad Hany 2301401, Abdulrahman Mohamed 2400544, Ahmed Hany 2400311.

**System**
```
Sensors → Arduino Uno (ALL safety logic, 50 ms loop)
           ⇅ serial (9600 baud, XOR-checksum lines)
         NodeMCU ESP8266 (Wi-Fi / MQTT bridge only, no decisions)
           ⇅ MQTT over a 2.4 GHz phone hotspot
         Mosquitto broker on the laptop (port 1883)
           ⇅ MQTT
         This Flutter app
```
- The app **never** makes safety decisions. The Uno enforces overload, top stop, jam and link loss. The app only displays state and sends requests; the Uno may refuse them.
- Sensors: load cell + AD620 (weight, kg), ACS712 (motor current, A), IR module (top of travel, on/off), motor Hall encoder (hook height, mm).

---

## 2. MQTT contract (the source of truth: build exactly this)

Broker: Mosquitto on the laptop, `tcp://<laptop-ip>:1883`, no TLS, no auth (lab network). QoS 0 for live data, QoS 1 for commands and events. All payloads are UTF-8 JSON.

### `crane/live`: crane → app, about 5 Hz, QoS 0
```json
{
  "t": 123456,          // Uno millis()
  "kg": 1.234,          // weight on the hook (tared), kg, 3 decimals
  "max": 1.5,           // current overload limit, kg
  "h": 212.5,           // hook height, mm (0 = table, ≈ 346 = top)
  "a": 0.42,            // motor current, A
  "top": false,         // IR top sensor active
  "st": "LIFTING",      // IDLE | LIFTING | LOWERING | OVERLOAD | JAM | TOP | ESTOP
  "mode": "REMOTE",     // LOCAL (panel key) | REMOTE (app allowed to command)
  "src": "APP"          // who started the current motion: APP | PANEL | NONE
}
```

### `crane/cmd`: app → crane, QoS 1
```json
{ "id": 17, "cmd": "LIFT" }          // hold-to-run: repeat every 250 ms while the button is held
{ "id": 18, "cmd": "LOWER" }         // hold-to-run, same as LIFT
{ "id": 19, "cmd": "STOP" }          // sent once on release AND on any STOP tap
{ "id": 20, "cmd": "RESET" }         // clears a latched OVERLOAD/JAM (Uno only accepts it below 95 % of max)
{ "id": 21, "cmd": "TARE" }          // only when IDLE and basket empty
{ "id": 22, "cmd": "SET_MAX", "value": 1.2 }   // 0.5 … 1.5 kg; Uno clamps to 1.5
{ "id": 23, "cmd": "PING" }          // heartbeat every 1 s while connected
```
- `id` increments per message (int, wraps at 65535).
- **Hold-to-run:** the crane stops a motion if it receives no repeat of LIFT/LOWER within 600 ms, and stops app-started motion if there is no message at all for 2 s. The app must keep repeating while the finger is down, and send STOP on release, cancel, app pause or disconnect.

### `crane/ack`: crane → app, QoS 1
```json
{ "id": 17, "ok": false, "reason": "OVERLOAD" }   // reasons: OVERLOAD, JAM, TOP, ESTOP, LOCAL_MODE, BUSY, RANGE
```
Only sent for LIFT/LOWER refusals and for RESET / TARE / SET_MAX results (not for every repeat).

### `crane/events`: crane → app, QoS 1
```json
{ "t": 123999, "type": "OVERLOAD", "kg": 1.53 }
```
`type`: OVERLOAD, OVERLOAD_CLEARED, JAM, TOP, ESTOP, ESTOP_RELEASED, RESET, TARE, MAX_CHANGED, LINK_LOST.

### `crane/status`: crane → app, retained, QoS 1
```json
{ "online": true, "fw": "m2.0" }
```
The NodeMCU sets a **Last Will** on this topic: `{ "online": false }` retained, so the app knows at once when the crane drops off.

---

## 3. App features

### Connect screen
- Broker host (IP), port (default 1883), client id (auto `crane-app-<random4>`). Saved with `shared_preferences`.
- Connect button, clear error messages (unreachable, refused, timeout). Auto-reconnect with back-off (1, 2, 4, 8 s, max 15 s).

### Dashboard (main screen)
1. **Weight gauge**: big number `1.234 kg`, an arc or bar from 0 to 2 kg with the **max line**. Colour: normal under 90 % of max, amber 90–100 %, red over max / OVERLOAD.
2. **State chip**: IDLE / LIFTING / LOWERING / OVERLOAD / JAM / TOP / ESTOP, colour-coded, plus LOCAL/REMOTE badge and who started the motion.
3. **Hook height**: a vertical bar 0–346 mm with the hook marker and the top-stop zone; number in mm.
4. **Motor current**: value in A and a small sparkline.
5. **Live chart**: weight over the last 30 s (fl_chart), with the max line.
6. **Connection health**: green when `crane/live` arrived within 1 s; amber "stale" after 1 s; red "crane offline" from `crane/status` or after 3 s.

### Controls
- **LIFT** and **LOWER**: large **press-and-hold** buttons (hold-to-run, repeat every 250 ms; STOP on release). Haptic feedback on press.
- **STOP**: large red button, always enabled while connected, sends STOP immediately.
- **RESET** (enabled only in OVERLOAD/JAM), **TARE** (only IDLE), **Max load** slider 0.5–1.5 kg (sends SET_MAX on release).
- Controls are **disabled** when: not connected, data stale, `mode` = LOCAL, or `st` = ESTOP. Show the reason on the disabled controls.
- LIFT is disabled in OVERLOAD, JAM and TOP; LOWER stays enabled in OVERLOAD and TOP (lowering is the safe direction).
- A refused command (`crane/ack` with `ok:false`) shows a snackbar with the reason.

### Events screen
- List of `crane/events`, newest first, time, type icon, weight. Clear button. Keep the last 200 in memory.

### Alerts
- OVERLOAD, JAM, ESTOP and crane offline: full-width red banner on the dashboard and a vibration.

---

## 4. Tech stack and architecture

- **Flutter 3.x (stable)**, Dart 3, null safety. Target **Android** first (team phones); keep it runnable on Windows/Linux desktop for the demo laptop.
- Packages: `flutter_riverpod` (state), `mqtt_client` (MQTT, server client), `fl_chart` (charts), `shared_preferences` (settings), `freezed` + `json_serializable` (models), `go_router` (navigation). Ask before adding anything else.
- **Clean architecture**, feature-first:
```
lib/
  main.dart
  app/                     router, theme (light + dark), constants (topics, limits)
  core/                    result types, logger, time utils
  features/
    connection/
      data/                mqtt_service.dart (connect, subscribe, publish, reconnect, LWT handling)
      domain/              connection_state.dart, broker_settings.dart
      presentation/        connect_screen.dart, connection_badge.dart
    telemetry/
      data/                telemetry_repository.dart (parses crane/live, crane/status)
      domain/              crane_live.dart (freezed), crane_state.dart (enum), staleness logic
      presentation/        dashboard_screen.dart, weight_gauge.dart, height_bar.dart, live_chart.dart
    control/
      data/                command_repository.dart (ids, hold-to-run timer, STOP on release/pause)
      domain/              crane_command.dart, control_availability.dart (pure rules: what is enabled and why)
      presentation/        hold_button.dart, control_panel.dart, max_load_slider.dart
    events/
      data/                events_repository.dart
      domain/              crane_event.dart
      presentation/        events_screen.dart
test/                      unit tests (parsing, availability rules, hold-to-run timing), widget tests
tools/
  crane_sim.py             crane simulator (section 5)
  mosquitto.conf           listener 1883 0.0.0.0, allow_anonymous true
```
- `control_availability.dart` is a **pure function** of (connection, staleness, live state) → which buttons are enabled + the reason. Unit-test it thoroughly.
- Hold-to-run must survive edge cases: finger slides off the button, app goes to background (`AppLifecycleState.paused`), connection drops mid-hold. Each case sends STOP (if connected) and stops the repeat timer.

---

## 5. Crane simulator (`tools/crane_sim.py`)

So the app can be built and demoed with no hardware. Python 3, `paho-mqtt`.
- Publishes `crane/live` at 5 Hz, `crane/status` retained (and sets the same Last Will).
- Obeys `crane/cmd` exactly like the Uno: hold-to-run with the 600 ms timeout, 2 s link loss, LIFT at 50 mm/s up to 346 mm (then TOP), LOWER down to 5 mm.
- Weight: keyboard keys in the terminal to set the basket load (`0`–`9` → 0.0–1.8 kg in 0.2 kg steps), with small noise (±3 g). Over max for 3 readings → OVERLOAD latch, event, refuse LIFT with ack.
- Current: 0.1 A idle, 0.2 A + 0.06 A/kg while lifting; key `j` simulates a jam (current 1.6 A → JAM after 0.3 s).
- Key `e` toggles ESTOP, `l` toggles LOCAL/REMOTE, `q` quits (status → offline).
- Prints every command it receives and its decision.

---

## 6. Conventions (from the team's preferences)

- **Clean code, clean architecture**: small widgets, no business logic in widgets, repositories behind interfaces.
- **A doc comment (`///`) before every function and class**, saying what it does, its parameters and its return value, so it can be edited easily later.
- Keep replies concise and technical.
- **Project documentation (required):**
  - Keep a `CLAUDE.md` at the project root, always up to date: stack, structure, conventions, MQTT contract summary, key decisions.
  - Keep a `history/` folder at the root with a subfolder per month (`history/2026-11/`) and a daily file named `DD-MM-YYYY.md` (e.g. `15-11-2026.md`) listing what was built, changed or decided that day. Update it during the session.
  - After any significant work, update **both** `CLAUDE.md` and today's history file before finishing.

---

## 7. Definition of done

- [ ] `flutter analyze` clean, `flutter test` green (parsing, availability rules, hold-to-run including the background/disconnect cases).
- [ ] With `mosquitto -c tools/mosquitto.conf` and `python tools/crane_sim.py` running, the app on a phone (same hotspot) connects, shows live weight/height/current, and lifts/lowers/stops the simulated crane with hold-to-run.
- [ ] Overload: setting 1.6 kg in the simulator turns the gauge red, shows the banner, disables LIFT, keeps LOWER, and RESET works after lowering the load.
- [ ] Killing the simulator shows "crane offline" within 3 s (Last Will) and disables all controls.
- [ ] App to background while holding LIFT → the simulator receives STOP.
- [ ] `CLAUDE.md` and `history/2026-11/<today>.md` written.

## 8. Out of scope for this session
- The NodeMCU and Uno firmware (they will implement this same MQTT contract; keep the contract in `CLAUDE.md` so both sides match).
- Login, cloud brokers, TLS.

## 9. Start here
1. Read this file, then create `CLAUDE.md` and `history/` with today's entry.
2. Scaffold the Flutter project and folders; add packages.
3. Write `tools/crane_sim.py` + `tools/mosquitto.conf` first, so every later step can be tested live.
4. Build connection → telemetry → dashboard → controls (hold-to-run) → events → alerts, testing against the simulator after each.
