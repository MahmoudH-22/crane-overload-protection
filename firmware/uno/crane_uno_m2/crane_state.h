/**
 * @file crane_state.h
 * @brief Crane state and the safety rules that run on their own (overload latch). Same rules as tools/crane_sim.py.
 *
 * Commands that change the state (RESET, TARE, SET_MAX...) are in commands.h.
 */
#pragma once
#include <Arduino.h>

namespace crane {

extern float maxKg;        ///< overload limit set by the app (MIN_LIMIT_KG .. MAX_LIMIT_KG)
extern float kg;           ///< latest weight
extern bool overload;      ///< OVERLOAD latched (cleared only by RESET below 95 % of max)
extern bool top;           ///< hook at the top (IR)
extern uint8_t overCount;  ///< consecutive readings above max

/**
 * State name for the live line.
 * @return OVERLOAD, TOP or IDLE (LIFTING / LOWERING / JAM / ESTOP need the motor).
 */
const char* stateName();

/**
 * Safety step, every SAFETY_MS: reads the weight and latches OVERLOAD after OVERLOAD_READINGS readings above max.
 * @return Nothing.
 */
void safetyTick();

/**
 * Reads the IR sensor and sends a TOP event when the hook reaches the top. Call every loop.
 * @return Nothing.
 */
void updateTop();

}  // namespace crane
