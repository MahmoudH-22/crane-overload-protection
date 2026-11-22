/**
 * @file app_link.h
 * @brief Link to the phone app through the HC-05 (SoftwareSerial D10 / D11, 9600). Formerly the NodeMCU.
 *
 * Sends the crane_link.h lines (L live, A ack, E event, S sensors) and reads C command lines, which it hands to
 * commands::handle(). It only moves lines; the rules are in crane_state and commands.
 */
#pragma once
#include <Arduino.h>

namespace link {

extern unsigned long lastMsgMs;  ///< last command received (the app sends PING every 1 s while connected)
extern uint32_t goodLines;       ///< valid lines received
extern uint32_t badLines;        ///< lines dropped (bad checksum / noise)

/**
 * Starts the HC-05 serial port.
 * @return Nothing.
 */
void begin();

/**
 * Sends one framed line (adds "*XX\n").
 * @param body Line body without checksum.
 * @return Nothing.
 */
void send(const char* body);

/**
 * Sends an ack line.
 * @param id Command id.
 * @param ok Accepted.
 * @param reason Refusal reason ("" when ok).
 * @return Nothing.
 */
void ack(long id, bool ok, const char* reason);

/**
 * Sends an event line and prints it on USB.
 * @param type Event type (OVERLOAD, TOP, ...).
 * @param value Value for the "kg" field.
 * @return Nothing.
 */
void event(const char* type, float value);

/**
 * Sends the live sample. Fields for sensors that are not fitted are left empty (-> null in the app).
 * @return Nothing.
 */
void sendLive();

/**
 * Sends the fitted-sensor list from the HAS_* flags (the app shows the others as "not fitted").
 * @return Nothing.
 */
void sendSensors();

/**
 * Reads characters from the HC-05 and hands complete, checksum-verified C lines to commands::handle().
 * @return Nothing.
 */
void poll();

}  // namespace link
