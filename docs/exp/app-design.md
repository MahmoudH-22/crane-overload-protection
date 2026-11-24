# Crane app: design, how it works, and how it talks to the Uno (summary)

The phone app (`app/`, Flutter, Android) shows the crane's readings live and lets the operator lift, lower, stop, send the hook to a height, tare, reset and change the max load. **It never makes safety decisions**: the Arduino Uno decides everything and may refuse any request. The app only shows the state and greys out buttons the crane would refuse.

---

## 1. Big picture

```
 Sensors ──► Arduino Uno ──serial 9600──► HC-05 ──Bluetooth──► Phone app
            (all safety)   text lines    (wireless cable)     (display + requests)

 Without the crane:  App ──Wi-Fi / MQTT──► Mosquitto (laptop) ◄── tools/crane_sim.py
```

| Who | Job |
|---|---|
| **Uno** | reads load cell + IR, applies the rules (overload latch, top stop, what is allowed), answers commands |
| **HC-05** | carries text lines both ways, unchanged; no logic |
| **App** | turns the lines into readings on screen, sends commands, keeps the link alive |
| **Simulator** | a fake full crane for development, reached over Wi-Fi (MQTT) instead of Bluetooth |

---

## 2. Screens

### Connect
- Top switch: **Crane** (Bluetooth) or **Simulator** (Wi-Fi).
- **Crane:** list of the phone's *paired* devices → tap the HC-05 → **Connect**. (Pair it first in Android Settings → Bluetooth, PIN 1234.) Android 12+ asks for "Nearby devices" once.
- **Simulator:** laptop IP, port 1883, client id.
- Remembers the last choice. Clear error messages (Bluetooth off, permission denied, could not connect…).

### Dashboard (main screen)

| Part | Shows / does |
|---|---|
| Top bar | connection badge: **Live** / **Stale** / **Crane offline** / **Reconnecting (n)…**, link to Events |
| Alert banner | red, with vibration: OVERLOAD, JAM, E-STOP, object under the load, crane offline |
| Weight card | gauge 0–2 kg with the max mark; green < 90 % of max, amber 90–100 %, red above |
| Hook card | height bar (n/a until the encoder exists) + **IR TOP / IR clear** badge |
| Go to height | slider + **GO** (tap once; becomes CANCEL while moving) |
| Under the load | ultrasonic distance, CLEAR / OBJECT BELOW (not fitted yet) |
| Motor current | amps + sparkline (not fitted yet) |
| Live chart | weight over the last 30 s |
| Actions | **RESET**, **TARE**, max-load slider (0.5–1.5 kg) |
| Bottom bar | **LOWER · STOP · LIFT** (LIFT / LOWER are press-and-hold) |

### Events
List of what the crane reported (OVERLOAD, TOP, TARE, RESET, MAX_CHANGED…), newest first, last 200.

---

## 3. How the app behaves (the rules)

**Connection health**
- **Live:** a reading arrived in the last 1 s. **Stale:** 1–3 s (data faded, controls off except STOP). **Crane offline:** > 3 s, or the Uno silent for 2 s. **Not connected:** Bluetooth link down.

**Buttons are enabled only when the crane would accept them**
- Everything off when not connected, stale, offline, LOCAL mode or E-STOP. **STOP stays on whenever the link is up.**
- LIFT off in OVERLOAD, JAM, TOP (IR) or when the weight is above max. LOWER off in JAM or with an object under the load.
- RESET only in OVERLOAD / JAM. TARE only when IDLE.
- Missing parts: no motor → LIFT / LOWER / GO show **"Motor not connected"**; no encoder → height "n/a", GO off.
- The button shows *why* it is off (e.g. "Overload", "Load above max").

**Moving the crane safely**
- **LIFT / LOWER = hold-to-run:** while the finger is down, the app repeats the command every 250 ms. The Uno stops if no repeat arrives within 600 ms. Release, slide off, app going to background, or disconnect → STOP.
- **GO = tap once:** the app itself repeats GOTO every 250 ms until arrival, CANCEL, or a blocked condition. If the phone freezes or Bluetooth drops, the repeats stop and the crane halts within 600 ms.
- **STOP** fires on finger-down, not release.
- A **PING every 1 s** tells the Uno the app is still there (the Uno stops app-started motion after 2 s of silence).
- After a lost link the app reconnects by itself (1, 2, 4, 8, 15 s) but **never resumes motion** on its own.

---

## 4. How the app connects to the Uno

### 4.1 The physical path
```
Uno D11 ─(divider)─► HC-05 RXD        HC-05 TXD ─► Uno D10        (SoftwareSerial, 9600 baud)
HC-05 ◄═════ Bluetooth Classic (SPP, "serial port profile"), ~10 m ═════► phone
```
To the app, the HC-05 is just a serial port: bytes in, bytes out. Wiring details: `docs/exp/02-hc05-bluetooth.md`.

### 4.2 The language: text lines with a checksum (`crane_link.h`)
Every message is one line: `<fields separated by commas>*XX` + newline, where `XX` is a checksum (XOR of all characters, in hex). An empty field means "no value" (sensor not fitted).

| Line | Direction | When | Example |
|---|---|---|---|
| **L** live | Uno → app | every 200 ms | `L,123456,0.512,1.50,,,0,IDLE,REMOTE,NONE,,0*3C` |
| **S** sensors | Uno → app | every 2 s | `S,kg top` |
| **E** event | Uno → app | when it happens | `E,1001,TOP,0.512` |
| **A** ack | Uno → app | reply to a command | `A,42,0,BUSY` |
| **C** command | app → Uno | on a tap / every 250 ms while held / PING 1 s | `C,42,TARE`, `C,7,SET_MAX,1.200` |

L fields in order: time, **kg**, **max**, height, current, **top** (1/0), **state**, mode, source, ultrasonic, obstacle.

Lines with a wrong checksum or bad fields are **dropped** on both sides, so electrical noise can never turn into a wrong reading or a wrong command.

### 4.3 What happens inside the app
```
 HC-05 bytes ─► FlutterBluePort ─► BluetoothGateway ─────────────► repositories ─► screens
                (plugin adapter)   • split into lines              telemetry   (live, status)
                                   • check checksum                control     (acks)
                                   • L/A/E/S → messages            events
                                   • make "online / offline"

 screens ─► control repository ─► BluetoothGateway ─► "C,id,CMD*XX" ─► HC-05
```
- **`CraneLinkCodec`** is the Dart copy of the Uno's `crane_link.h` (same checks, same tests).
- **`BluetoothGateway`** turns each line into a named message (`crane/live`, `crane/ack`, `crane/events`, `crane/status`) with JSON content, the same messages the simulator sends over MQTT. So the rest of the app doesn't know or care whether Bluetooth or Wi-Fi is used.
- It decides **online / offline**: online while valid lines arrive, offline after 2 s without one.
- **`TransportGateway`** picks Bluetooth (crane) or MQTT (simulator) according to the Connect screen.

### 4.4 Two examples end to end

**A weight reading**
1. Uno, every 200 ms: `L,123456,0.512,1.50,,,0,IDLE,REMOTE,NONE,,0*3C`
2. HC-05 → phone, unchanged.
3. App checks `*3C`, reads kg 0.512, max 1.50, top 0, state IDLE; height / current / ultrasonic are empty → "not fitted".
4. Gauge shows **0.512 kg** (green), Hook card shows **IR clear**, badge **Live**.

**Tapping TARE**
1. App sends `C,42,TARE*xx`.
2. Uno: state is IDLE → zeroes the scale → replies `A,42,1,` and `E,…,TARE,0.000`.
3. App shows 0.000 kg and adds a TARE event. Had the crane been in OVERLOAD, the reply would be `A,42,0,BUSY` and the app shows "Refused: crane is busy".

---

## 5. Code structure (clean architecture, feature-first)

```
lib/
  app/        constants (limits, timing), theme, routes, app shell (STOP on background, alert vibration)
  core/       Result type, logger, clock
  features/
    connection/  Bluetooth + MQTT links, line codec, settings, Connect screen, badge
    telemetry/   live data, health / gauge / alert rules, dashboard cards
    control/     commands, enable rules, hold-to-run + GO timing, buttons
    events/      event list and screen
```

Each feature has three layers:

| Layer | Contains | Rule |
|---|---|---|
| **domain** | data models and pure rules (e.g. which buttons are enabled and why) | no Flutter, fully unit-tested |
| **data** | gateways and repositories (Bluetooth, MQTT, storage) | behind interfaces, so tests use fakes |
| **presentation** | Riverpod providers + small widgets | no business logic in widgets |

**Packages:** flutter_riverpod (state), flutter_blue_classic (HC-05), mqtt_client (simulator), fl_chart (charts), go_router (screens), freezed / json_serializable (models), shared_preferences (saved settings).

**Tests (~120):** parsing, every rule, hold-to-run / GO timing, the Bluetooth codec and gateway with a fake HC-05, and every crane state drawn at three phone widths with large font (no overflow).

---

## 6. Running it

```
cd app && flutter run            # Android phone on USB; then Connect → Crane → HC-05
```
Without the crane: `mosquitto -c tools/mosquitto.conf -v` and `python tools/crane_sim.py` on the laptop, then **Connect → Simulator** with the laptop's IP.

**Limits of the Bluetooth link:** Android only (iPhones can't use the HC-05), one phone at a time, about 10 m range.

Full technical contract: `CLAUDE.md`. Firmware side: `firmware/uno/crane_uno_m2/README.md`. Wiring: `docs/exp/`.
