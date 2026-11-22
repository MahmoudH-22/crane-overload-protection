/**
 * @file commands.cpp
 * @brief App commands and their safety rules: see commands.h.
 */
#include "commands.h"

#include "app_link.h"
#include "config.h"
#include "crane_link.h"
#include "crane_state.h"
#include "load_cell.h"

namespace commands {

namespace {
unsigned long lastRefusalMs = 0;  ///< NOT_FITTED acks at most once per second per burst
char lastRefusedCmd[8] = "";

/**
 * Refuses a motion command while the motor is not fitted (acked once per second per command).
 * @param id Command id.
 * @param cmd Command name.
 * @return Nothing.
 */
void refuseMotion(long id, const char* cmd) {
  if (strcmp(cmd, lastRefusedCmd) != 0 || millis() - lastRefusalMs > 1000) {
    link::ack(id, false, "NOT_FITTED");
    strncpy(lastRefusedCmd, cmd, sizeof lastRefusedCmd - 1);
  }
  lastRefusalMs = millis();
}

/**
 * RESET: clears OVERLOAD, but only below RESET_FRACTION of max.
 * @param id Command id.
 * @return Nothing.
 */
void reset(long id) {
  if (crane::overload && crane::kg >= RESET_FRACTION * crane::maxKg) {
    link::ack(id, false, "OVERLOAD");
    return;
  }
  const bool had = crane::overload;
  crane::overload = false;
  crane::overCount = 0;
  link::ack(id, true, "");
  if (had) link::event("OVERLOAD_CLEARED", crane::kg);
  link::event("RESET", crane::kg);
}

/**
 * TARE: zeroes the scale, only when IDLE.
 * @param id Command id.
 * @return Nothing.
 */
void tare(long id) {
  if (strcmp(crane::stateName(), "IDLE") != 0) {
    link::ack(id, false, "BUSY");
    return;
  }
#if HAS_LOAD_CELL
  load_cell_with_conditioning::tareQuick();
#endif
  link::ack(id, true, "");
  link::event("TARE", 0);
}

/**
 * SET_MAX: new overload limit, MIN_LIMIT_KG..MAX_LIMIT_KG (above is clamped, below is refused).
 * @param id Command id.
 * @param valueText Limit in kg.
 * @return Nothing.
 */
void setMax(long id, const char* valueText) {
  if (!crane_link::isNumber(valueText) || atof(valueText) < MIN_LIMIT_KG) {
    link::ack(id, false, "RANGE");
    return;
  }
  crane::maxKg = min((float)atof(valueText), MAX_LIMIT_KG);
  link::ack(id, true, "");
  link::event("MAX_CHANGED", crane::maxKg);
}
}  // namespace

void handle(long id, const char* cmd, const char* valueText) {
  if (strcmp(cmd, "PING") == 0 || strcmp(cmd, "STOP") == 0) return;
  Serial.print(F("CMD "));
  Serial.print(id);
  Serial.print(' ');
  Serial.println(cmd);

  if (strcmp(cmd, "LIFT") == 0 || strcmp(cmd, "LOWER") == 0 || strcmp(cmd, "GOTO") == 0) {
#if !HAS_MOTOR
    refuseMotion(id, cmd);
#endif
    return;
  }
  if (strcmp(cmd, "RESET") == 0) return reset(id);
  if (strcmp(cmd, "TARE") == 0) return tare(id);
  if (strcmp(cmd, "SET_MAX") == 0) return setMax(id, valueText);
  link::ack(id, false, "RANGE");  // unknown command
}

}  // namespace commands
