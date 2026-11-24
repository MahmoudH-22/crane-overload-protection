# Crane Overload — Milestone 1 end-to-end steps

Goal: show both Milestone 1 sensors **in the phone app**, live:
- **ON/OFF:** IR top sensor → "IR TOP / IR clear" badge
- **Analog with conditioning:** load cell → AD620 → weight in **kg**

```
IR + load cell → Uno → (serial D11/D10 ↔ D5/D6) → NodeMCU → Wi-Fi/MQTT → Mosquitto (laptop) → app
```

---

## 0. Before you start

| Item | Check |
|---|---|
| Wiring | As in `uno-nodemcu-serial-wiring.png`: Uno D11 → 1 kΩ → junction → 2 kΩ → GND; junction → NodeMCU **D5**; NodeMCU **D6** → Uno D10; Uno 5V → NodeMCU VIN; GND shared |
| Junction voltage | ≈ 3.3 V (never 5 V) while the Uno is running |
| Cables | USB-B for the Uno; a micro-USB **data** cable for the NodeMCU (a new COM port must appear when you plug it in) |
| Phone hotspot | On, set to **2.4 GHz**; the laptop and the phone are both connected to it |
| Laptop | Arduino IDE, Mosquitto installed; the app installed on the phone |

---

## 1. Upload the Uno sketch

1. Open `crane_overload_m1/crane_overload_m1.ino`.
2. Board: **Arduino Uno**, the Uno's port. Upload.
3. The NodeMCU wires can stay connected (D10/D11 are not the Uno's USB pins).
4. Optional check: Uno Serial Monitor at **115200** shows `IR: ... | weight ... kg` lines.

## 2. Prepare and upload the NodeMCU sketch

1. Arduino IDE → **File → Preferences → Additional boards manager URLs**:
   `http://arduino.esp8266.com/stable/package_esp8266com_index.json`
2. **Boards Manager** → install **esp8266** (ESP8266 Community).
3. **Library Manager** → install **PubSubClient** (Nick O'Leary).
4. Find the laptop's IP on the hotspot: run `ipconfig` (Windows) and note the IPv4 address.
5. Open `crane_nodemcu_m1/crane_nodemcu_m1.ino` and edit the settings at the top:

   ```cpp
   const char *WIFI_SSID = "CraneHotspot";     // your hotspot name
   const char *WIFI_PASS = "12345678";         // its password
   const char *MQTT_HOST = "192.168.43.100";   // the laptop IP from step 4
   ```

6. Board: **NodeMCU 1.0 (ESP-12E Module)**, the NodeMCU's port. Upload.
   - If it stays on "Connecting…", hold the **FLASH** button while the upload starts.

## 3. Check the Uno → NodeMCU link

1. Open the **NodeMCU's** Serial Monitor at **115200**.
2. About once a second you should see a line like:

   ```
   <- uno D,0.003,0*4A
   ```

3. Cover the IR sensor: the last number becomes `1`.

| What you see | Meaning / fix |
|---|---|
| `<- uno D,...` lines | Link wiring is correct ✅ |
| Nothing | Check junction → **D5**, D11 → 1 kΩ, and the shared GND |
| `bad checksum` | Loose wire, or the junction is not ≈ 3.3 V |
| `Wi-Fi ok, IP ...` never appears | Wrong SSID/password, or the hotspot is 5 GHz |

## 4. Start the broker on the laptop

```
mosquitto -v
```

- Allow port **1883** if Windows Firewall asks (private network).
- The NodeMCU monitor should now print `MQTT connect to ... ok`.
- If it prints `failed, state -2`: wrong `MQTT_HOST`, broker not running, or the firewall is blocking 1883.

Optional check with MQTT Explorer (laptop): connect to `localhost:1883`, and `crane/live` should update 5 times a second; `crane/status` should show `{"online":true,"fw":"m1.0"}`.

## 5. Open the app

1. Phone on the same hotspot. Open the app.
2. Connect screen: broker = the laptop IP, port **1883**. Connect.
3. Check:

| Test | Expected in the app |
|---|---|
| Badge | **Live** (green) |
| Empty basket | Weight ≈ 0.000 kg |
| Press the load cell's free end gently | Weight rises, returns to ≈ 0 on release |
| Cover the IR sensor | **IR TOP** badge; an event in the Events screen |
| Uncover it | **IR clear** |
| Tap **TARE** | Weight returns to 0.000 kg; "accepted" |
| Unplug the NodeMCU | **Crane offline** within a few seconds (Last Will) |

LIFT / LOWER / GO show **"Refused"**: expected, the motor is not fitted until Milestone 2.

## 6. Calibrate and record for the report

1. Uno Serial Monitor (115200, line ending **Newline**), empty basket: type `t`.
2. Hang a **1.000 kg** bottle (checked on a kitchen scale), wait until still: type `c 1000`.
3. Type `s` and note the **cell sensitivity (mV/V)**.
4. Hang 0.5 kg and 1.5 kg and note each reading shown in the **app**. Target: within ± 0.05 kg.
5. Fill Table 8 of the Milestone 1 report.

## 7. Screenshots for the report

| Figure | Screen |
|---|---|
| Figure 4 | App Connect screen |
| Figure 5 | App Dashboard showing the weight in kg and the IR badge (cover the sensor for IR TOP) |

Also useful: a short video of covering the IR sensor and adding a weight, with the app updating.

---

## Quick troubleshooting

| Problem | Likely cause | Fix |
|---|---|---|
| App stays "Not connected" | Phone on a different network, wrong IP | Same hotspot for all; re-check `ipconfig` |
| App "Stale" / "Crane offline" | NodeMCU not on MQTT | Check the NodeMCU monitor for `MQTT connect ... ok` |
| Weight frozen in the app, Uno monitor changing | Link wiring | Step 3 checks |
| Weight jumps a lot | Loose breadboard wire or missing 100 nF | Re-seat wires; 100 nF at AD620 pins 7–4 |
| Weight negative when loaded | Green / white swapped | Swap them, then `t` again |
| NodeMCU keeps rebooting | Weak 5 V supply | Power the Uno from USB; check the 5V → VIN wire |
