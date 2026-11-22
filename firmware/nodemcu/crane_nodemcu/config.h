/**
 * @file config.h
 * @brief Network settings for the NodeMCU. Edit these four lines before uploading.
 *
 * The NodeMCU only supports 2.4 GHz Wi-Fi. Use the same network as the laptop running Mosquitto
 * (the phone hotspot at the demo). MQTT_HOST is the laptop's IPv4 address on that network:
 * run `ipconfig` on the laptop and read "Wireless LAN adapter Wi-Fi -> IPv4 Address".
 *
 * Do not commit a real Wi-Fi password to a public repository.
 */
#pragma once

#define WIFI_SSID "Ziad's iPhone"     // network name (2.4 GHz)
#define WIFI_PASS "Ziadhany1"        // network password
#define MQTT_HOST "172.20.10.9"      // laptop IPv4 address (the same one you type in the app)
#define MQTT_PORT 1883
