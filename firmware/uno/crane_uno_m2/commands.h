/**
 * @file commands.h
 * @brief App commands (LIFT, LOWER, GOTO, STOP, RESET, TARE, SET_MAX, PING) and the safety rules that accept or
 *        refuse them. Replies go out through app_link (ack + events).
 *
 * Rules: RESET only below 95 % of max; TARE only when IDLE; SET_MAX 0.5..1.5 kg (clamped to 1.5, below 0.5 RANGE);
 * LIFT / LOWER / GOTO refused with NOT_FITTED while HAS_MOTOR is 0 (acked at most once per second per command).
 */
#pragma once
#include <Arduino.h>

namespace commands {

/**
 * Runs one app command.
 * @param id Command id.
 * @param cmd Command name.
 * @param valueText Value field ("" if none).
 * @return Nothing.
 */
void handle(long id, const char* cmd, const char* valueText);

}  // namespace commands
