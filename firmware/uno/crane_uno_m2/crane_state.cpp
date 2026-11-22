/**
 * @file crane_state.cpp
 * @brief Crane state and safety: see crane_state.h.
 */
#include "crane_state.h"

#include "app_link.h"
#include "config.h"
#include "ir_sensor.h"
#include "load_cell.h"

namespace crane {

float maxKg = MAX_LIMIT_KG;
float kg = 0;
bool overload = false;
bool top = false;
uint8_t overCount = 0;

const char* stateName() {
  if (overload) return "OVERLOAD";
  if (top) return "TOP";
  return "IDLE";
}

void safetyTick() {
#if HAS_LOAD_CELL
  kg = load_cell_with_conditioning::weightKg();
#endif
  overCount = kg > maxKg ? min(overCount + 1, 255) : 0;
  if (!overload && overCount >= OVERLOAD_READINGS) {
    overload = true;
    link::event("OVERLOAD", kg);
  }
}

void updateTop() {
#if HAS_IR
  if (load_ir_detection::update()) {
    top = load_ir_detection::detected();
    if (top) link::event("TOP", kg);
  }
#endif
}

}  // namespace crane
