#!/usr/bin/env python3
"""Crane Overload simulator: behaves like the Uno + NodeMCU on MQTT.

Implements the MQTT contract in CLAUDE.md so the app can be developed and
demoed without hardware.

Usage:
    pip install paho-mqtt
    python tools/crane_sim.py [--host 127.0.0.1] [--port 1883]

Keys (terminal):
    0-9  basket load 0.0 .. 1.8 kg (0.2 kg steps)
    j    simulate a jam (current 1.6 A -> JAM after 0.3 s while lifting)
    u    toggle an object (80 mm tall) on the table under the basket
    e    toggle E-stop
    l    toggle LOCAL / REMOTE
    q    quit (crane/status -> offline)

When stdin is not a terminal, the same keys are read line by line from stdin
(handy for scripted tests: `echo 8 | python tools/crane_sim.py`).
"""

from __future__ import annotations

import argparse
import json
import random
import sys
import threading
import time

try:
    import paho.mqtt.client as mqtt
except ImportError as exc:  # pragma: no cover
    sys.exit(
        f"paho-mqtt not importable ({exc}).\n"
        f"This Python is: {sys.executable}\n"
        f"Install it for this interpreter:  \"{sys.executable}\" -m pip install paho-mqtt"
    )

# ------------------------------------------------------------------ contract
T_LIVE = "crane/live"
T_CMD = "crane/cmd"
T_ACK = "crane/ack"
T_EVENTS = "crane/events"
T_STATUS = "crane/status"
FW = "sim-1.0"

# ------------------------------------------------------------------ physics / limits (match the Uno)
LOOP_S = 0.05            # 50 ms control loop
LIVE_PERIOD_S = 0.2      # 5 Hz telemetry
TOP_MM = 346.0
BOTTOM_MM = 5.0
TOP_SENSOR_MM = 340.0    # IR sensor sees the hook above this height
SPEED_MM_S = 50.0
GOTO_MIN_SPEED_MM_S = 8.0  # GOTO slows down near the target ...
GOTO_GAIN_PER_S = 3.0      # ... speed = gain x distance, clamped to [min, SPEED]
GOTO_TOL_MM = 3.0          # GOTO counts as arrived within this distance
HOLD_TIMEOUT_S = 0.6     # no LIFT/LOWER repeat -> stop
LINK_TIMEOUT_S = 2.0     # no message at all -> stop app motion
MAX_LIMIT_KG = 1.5
MIN_LIMIT_KG = 0.5
OVERLOAD_READINGS = 3
RESET_FRACTION = 0.95
JAM_AMPS = 1.5
JAM_TIME_S = 0.3
NOISE_KG = 0.003
ZERO_DRIFT_KG = 0.012    # untared offset, so TARE has a visible effect
US_BLIND_MM = 20.0       # HC-SR04 cannot measure closer than this -> "us": null
US_MARGIN_MM = 30.0      # obstacle if the echo is this much shorter than the expected clearance (= h)
US_MIN_CHECK_MM = 50.0   # below this hook height the table itself is too close to check
US_NOISE_MM = 2.0
OBSTACLE_SET_READINGS = 2     # consecutive obstacle readings (50 ms each) to set
OBSTACLE_CLEAR_S = 0.5        # continuous clear time to clear (auto, no RESET)
OBJECT_MM = 80.0              # height of the object placed with key 'u'
REFUSAL_ACK_GAP_S = 1.0  # do not re-ack the same refusal on every 250 ms repeat


def log(msg: str) -> None:
    """Prints a timestamped line.

    Args:
        msg: Text to print.
    """
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


class Crane:
    """Simulated crane state machine (the Uno's safety logic)."""

    def __init__(self, client: mqtt.Client) -> None:
        """Creates the crane in IDLE, REMOTE mode, hook at 50 mm.

        Args:
            client: Connected paho client used to publish.
        """
        self.client = client
        self.lock = threading.Lock()
        self.t0 = time.monotonic()
        self.basket_kg = 0.0
        self.tare_kg = 0.0
        self.max_kg = MAX_LIMIT_KG
        self.h = 50.0
        self.amps = 0.1
        self.kg = 0.0
        self.direction = 0          # +1 lift, -1 lower, 0 stopped
        self.goto_target: float | None = None  # mm, while a GOTO motion is running
        self.src = "NONE"
        self.mode = "REMOTE"
        self.estop = False
        self.overload = False
        self.jam = False
        self.jam_sim = False
        self.over_count = 0
        self.jam_since: float | None = None
        self.object_mm: float | None = None   # object on the table under the basket (key 'u')
        self.us_mm: float | None = None       # ultrasonic distance below the basket, mm
        self.obstacle = False
        self.obs_count = 0
        self.clear_since: float | None = None
        self.last_motion_cmd = 0.0
        self.last_msg = 0.0
        self.last_refusal: tuple[str, str, float] = ("", "", 0.0)

    # -------------------------------------------------------------- helpers
    def millis(self) -> int:
        """Returns the simulated Uno millis().

        Returns:
            Milliseconds since the simulator started.
        """
        return int((time.monotonic() - self.t0) * 1000)

    @property
    def top(self) -> bool:
        """Whether the IR top-of-travel sensor is active.

        Returns:
            True when the hook is in the top zone.
        """
        return self.h >= TOP_SENSOR_MM

    def state(self) -> str:
        """Computes the reported state, highest priority first.

        Returns:
            One of ESTOP, JAM, OVERLOAD, LIFTING, LOWERING, TOP, IDLE.
        """
        if self.estop:
            return "ESTOP"
        if self.jam:
            return "JAM"
        if self.overload:
            return "OVERLOAD"
        if self.direction > 0:
            return "LIFTING"
        if self.direction < 0:
            return "LOWERING"
        if self.top:
            return "TOP"
        return "IDLE"

    def publish(self, topic: str, payload: dict, qos: int = 0, retain: bool = False) -> None:
        """Publishes a JSON payload.

        Args:
            topic: MQTT topic.
            payload: Dict serialised to JSON.
            qos: MQTT QoS level.
            retain: Retained flag.
        """
        self.client.publish(topic, json.dumps(payload), qos=qos, retain=retain)

    def event(self, kind: str, kg: float | None = None) -> None:
        """Publishes a crane/events message and logs it.

        Args:
            kind: Event type (OVERLOAD, JAM, TOP, ...).
            kg: Value for the "kg" field; defaults to the current weight
                (MAX_CHANGED passes the new limit).
        """
        value = round(self.kg if kg is None else kg, 3)
        self.publish(T_EVENTS, {"t": self.millis(), "type": kind, "kg": value}, qos=1)
        log(f"EVENT {kind} (kg={value:.3f})")

    def ack(self, cmd_id: int, ok: bool, reason: str | None = None) -> None:
        """Publishes a crane/ack message.

        Args:
            cmd_id: Id of the command being answered.
            ok: Whether the command was accepted.
            reason: Refusal reason when ok is False.
        """
        body: dict = {"id": cmd_id, "ok": ok}
        if reason:
            body["reason"] = reason
        self.publish(T_ACK, body, qos=1)

    def stop(self, why: str) -> None:
        """Stops any motion.

        Args:
            why: Reason, printed to the console.
        """
        if self.direction != 0:
            log(f"STOP motion ({why})")
        self.direction = 0
        self.goto_target = None
        self.src = "NONE"
        self.jam_since = None

    def refuse_motion(self, cmd_id: int, cmd: str, reason: str) -> None:
        """Refuses LIFT/LOWER, acking only the first refusal of a burst.

        Args:
            cmd_id: Command id.
            cmd: LIFT or LOWER.
            reason: Refusal reason.
        """
        last_cmd, last_reason, last_t = self.last_refusal
        now = time.monotonic()
        if last_cmd != cmd or last_reason != reason or now - last_t > REFUSAL_ACK_GAP_S:
            self.ack(cmd_id, False, reason)
            log(f"  -> refused {cmd}: {reason}")
        self.last_refusal = (cmd, reason, now)

    # -------------------------------------------------------------- commands
    def on_command(self, msg: dict) -> None:
        """Handles one crane/cmd message exactly like the Uno.

        Args:
            msg: Decoded JSON command ({"id", "cmd", optional "value"}).
        """
        cmd_id = int(msg.get("id", 0))
        cmd = str(msg.get("cmd", "")).upper()
        now = time.monotonic()
        with self.lock:
            self.last_msg = now
            if cmd != "PING":
                log(f"CMD #{cmd_id} {cmd}" + (f" value={msg['value']}" if "value" in msg else ""))

            if cmd == "PING":
                return
            if cmd == "STOP":
                self.stop("app STOP")
                return
            if cmd in ("LIFT", "LOWER"):
                self._motion(cmd_id, cmd, now)
                return
            if cmd == "GOTO":
                self._goto(cmd_id, msg.get("value"), now)
                return
            if self.mode == "LOCAL":
                self.ack(cmd_id, False, "LOCAL_MODE")
                log(f"  -> refused {cmd}: LOCAL_MODE")
                return
            if cmd == "RESET":
                self._reset(cmd_id)
            elif cmd == "TARE":
                self._tare(cmd_id)
            elif cmd == "SET_MAX":
                self._set_max(cmd_id, msg.get("value"))
            else:
                self.ack(cmd_id, False, "RANGE")
                log(f"  -> unknown command {cmd}")

    def _motion(self, cmd_id: int, cmd: str, now: float) -> None:
        """Accepts or refuses a hold-to-run LIFT/LOWER (lock held).

        Args:
            cmd_id: Command id.
            cmd: LIFT or LOWER.
            now: Monotonic time of reception.
        """
        want = 1 if cmd == "LIFT" else -1
        reason = self._motion_refusal(want)
        if reason:
            self.refuse_motion(cmd_id, cmd, reason)
            return
        if want < 0 and self.h <= BOTTOM_MM:
            return  # already at the soft bottom limit: nothing to do, no ack in the contract
        if self.direction != want or self.goto_target is not None:
            log(f"  -> {'LIFTING' if want > 0 else 'LOWERING'}")
        self.goto_target = None
        self.direction = want
        self.src = "APP"
        self.last_motion_cmd = now

    def _motion_refusal(self, want: int) -> str | None:
        """Returns why a motion in direction `want` is refused, or None (lock held).

        Args:
            want: +1 up, -1 down.

        Returns:
            Refusal reason or None when allowed.
        """
        if self.mode == "LOCAL":
            return "LOCAL_MODE"
        if self.estop:
            return "ESTOP"
        if self.jam:
            return "JAM"
        if want < 0 and self.obstacle:
            return "OBSTACLE"
        if want > 0 and self.overload:
            return "OVERLOAD"
        if want > 0 and self.h >= TOP_MM:
            return "TOP"
        if self.direction != 0 and self.direction != want and self.goto_target is None:
            return "BUSY"  # a plain LIFT/LOWER is running the other way
        return None

    def _goto(self, cmd_id: int, value, now: float) -> None:
        """Hold-to-run move to a target height; the crane stops there by itself (lock held).

        Args:
            cmd_id: Command id.
            value: Target height in mm (BOTTOM_MM .. TOP_MM).
            now: Monotonic time of reception.
        """
        try:
            target = float(value)
        except (TypeError, ValueError):
            target = -1.0
        if not BOTTOM_MM <= target <= TOP_MM:
            self.refuse_motion(cmd_id, "GOTO", "RANGE")
            return
        diff = target - self.h
        if abs(diff) <= GOTO_TOL_MM:
            return  # already there: nothing to do (repeats while the button is still held)
        want = 1 if diff > 0 else -1
        reason = self._motion_refusal(want)
        if reason:
            self.refuse_motion(cmd_id, "GOTO", reason)
            return
        if self.goto_target != target or self.direction != want:
            log(f"  -> GOTO {target:.0f} mm ({'up' if want > 0 else 'down'})")
        self.goto_target = target
        self.direction = want
        self.src = "APP"
        self.last_motion_cmd = now

    def _reset(self, cmd_id: int) -> None:
        """Clears a latched OVERLOAD / JAM if allowed (lock held).

        Args:
            cmd_id: Command id.
        """
        if self.estop:
            self.ack(cmd_id, False, "ESTOP")
            log("  -> refused RESET: ESTOP")
            return
        if self.overload and self.kg >= RESET_FRACTION * self.max_kg:
            self.ack(cmd_id, False, "OVERLOAD")
            log(f"  -> refused RESET: still {self.kg:.3f} kg >= 95 % of {self.max_kg}")
            return
        had_overload = self.overload
        self.overload = False
        self.jam = False
        self.over_count = 0
        self.ack(cmd_id, True)
        if had_overload:
            self.event("OVERLOAD_CLEARED")
        self.event("RESET")

    def _tare(self, cmd_id: int) -> None:
        """Zeroes the scale when IDLE (lock held).

        Args:
            cmd_id: Command id.
        """
        if self.state() not in ("IDLE", "TOP"):
            self.ack(cmd_id, False, "BUSY")
            log(f"  -> refused TARE: state {self.state()}")
            return
        self.tare_kg = self.basket_kg + ZERO_DRIFT_KG
        self.ack(cmd_id, True)
        self.event("TARE")

    def _set_max(self, cmd_id: int, value) -> None:
        """Sets the overload limit, clamped to 1.5 kg (lock held).

        Args:
            cmd_id: Command id.
            value: Requested limit in kg.
        """
        try:
            v = float(value)
        except (TypeError, ValueError):
            v = -1.0
        if v < MIN_LIMIT_KG:
            self.ack(cmd_id, False, "RANGE")
            log(f"  -> refused SET_MAX: {value} out of range")
            return
        self.max_kg = round(min(v, MAX_LIMIT_KG), 3)
        self.ack(cmd_id, True)
        self.event("MAX_CHANGED", self.max_kg)
        log(f"  -> max = {self.max_kg} kg")

    # -------------------------------------------------------------- keys
    def on_key(self, key: str) -> bool:
        """Handles one keyboard key.

        Args:
            key: Single character.

        Returns:
            False when the simulator should quit.
        """
        with self.lock:
            if key.isdigit():
                self.basket_kg = int(key) * 0.2
                log(f"basket load = {self.basket_kg:.1f} kg")
            elif key == "j":
                self.jam_sim = True
                log("jam armed: next lift will jam")
            elif key == "e":
                self.estop = not self.estop
                self.stop("E-stop")
                self.event("ESTOP" if self.estop else "ESTOP_RELEASED")
            elif key == "u":
                self.object_mm = None if self.object_mm is not None else OBJECT_MM
                log("object under the basket" if self.object_mm else "object removed")
            elif key == "l":
                self.mode = "LOCAL" if self.mode == "REMOTE" else "REMOTE"
                if self.mode == "LOCAL" and self.src == "APP":
                    self.stop("switched to LOCAL")
                log(f"mode = {self.mode}")
            elif key == "q":
                return False
        return True

    # -------------------------------------------------------------- loop
    def tick(self, dt: float) -> None:
        """Runs one 50 ms control-loop step.

        Args:
            dt: Seconds since the previous step.
        """
        now = time.monotonic()
        with self.lock:
            raw = self.basket_kg + ZERO_DRIFT_KG + random.uniform(-NOISE_KG, NOISE_KG)
            self.kg = raw - self.tare_kg

            # overload: over max for 3 consecutive readings -> latch
            if self.kg > self.max_kg:
                self.over_count += 1
            else:
                self.over_count = 0
            if not self.overload and self.over_count >= OVERLOAD_READINGS:
                self.overload = True
                if self.direction > 0:
                    self.stop("OVERLOAD")
                self.event("OVERLOAD")

            # hold-to-run and link-loss timeouts
            if self.direction != 0 and now - self.last_motion_cmd > HOLD_TIMEOUT_S:
                self.stop("no repeat within 600 ms")
            if self.direction != 0 and self.src == "APP" and now - self.last_msg > LINK_TIMEOUT_S:
                self.stop("link lost")
                self.event("LINK_LOST")

            # ultrasonic under the basket: echo much shorter than the expected clearance -> obstacle
            self._ultrasonic(now)

            # motor current
            if self.direction > 0:
                self.amps = 1.6 if self.jam_sim else 0.2 + 0.06 * max(self.kg, 0.0)
            elif self.direction < 0:
                self.amps = 0.15 + 0.03 * max(self.kg, 0.0)
            else:
                self.amps = 0.1
            self.amps += random.uniform(-0.01, 0.01)

            # jam: over 1.5 A for 0.3 s while lifting
            if self.direction > 0 and self.amps > JAM_AMPS:
                self.jam_since = self.jam_since or now
                if now - self.jam_since >= JAM_TIME_S:
                    self.jam = True
                    self.jam_sim = False
                    self.stop("JAM")
                    self.event("JAM")
            else:
                self.jam_since = None

            # travel (GOTO slows down near its target and stops there)
            speed = SPEED_MM_S
            if self.goto_target is not None:
                dist = abs(self.goto_target - self.h)
                speed = max(GOTO_MIN_SPEED_MM_S, min(SPEED_MM_S, GOTO_GAIN_PER_S * dist))
            if self.direction > 0 and not self.jam:
                self.h = min(TOP_MM, self.h + speed * dt)
                if self.goto_target is not None and self.h >= self.goto_target - GOTO_TOL_MM / 3:
                    self.h = min(self.h, self.goto_target)
                    self.stop(f"target {self.goto_target:.0f} mm reached")
                elif self.h >= TOP_MM:
                    self.stop("top of travel")
                    self.event("TOP")
            elif self.direction < 0:
                self.h = max(BOTTOM_MM, self.h - speed * dt)
                if self.goto_target is not None and self.h <= self.goto_target + GOTO_TOL_MM / 3:
                    self.h = max(self.h, self.goto_target)
                    self.stop(f"target {self.goto_target:.0f} mm reached")
                elif self.h <= BOTTOM_MM:
                    self.stop("bottom limit")

    def _ultrasonic(self, now: float) -> None:
        """Reads the simulated HC-SR04 and updates the debounced obstacle flag (lock held).

        Stops a lowering at once when an obstacle appears; clears by itself after 0.5 s clear.

        Args:
            now: Monotonic time.
        """
        clearance = self.h  # basket bottom height above the table
        if self.object_mm is not None:
            clearance = max(0.0, self.h - self.object_mm)
        d = clearance + random.uniform(-US_NOISE_MM, US_NOISE_MM)
        self.us_mm = None if d < US_BLIND_MM else round(d, 1)
        raw = self.h >= US_MIN_CHECK_MM and (self.us_mm is None or self.us_mm < self.h - US_MARGIN_MM)

        if raw:
            self.obs_count += 1
            self.clear_since = None
            if not self.obstacle and self.obs_count >= OBSTACLE_SET_READINGS:
                self.obstacle = True
                if self.direction < 0:
                    self.stop("OBSTACLE under the load")
                self.event("OBSTACLE")
        else:
            self.obs_count = 0
            if self.obstacle:
                self.clear_since = self.clear_since or now
                if now - self.clear_since >= OBSTACLE_CLEAR_S:
                    self.obstacle = False
                    self.clear_since = None
                    self.event("OBSTACLE_CLEARED")

    def publish_live(self) -> None:
        """Publishes one crane/live sample (QoS 0)."""
        with self.lock:
            self.publish(T_LIVE, {
                "t": self.millis(),
                "kg": round(self.kg, 3),
                "max": self.max_kg,
                "h": round(self.h, 1),
                "a": round(self.amps, 2),
                "top": self.top,
                "st": self.state(),
                "mode": self.mode,
                "src": self.src,
                "us": self.us_mm,
                "obs": self.obstacle,
            })


# ------------------------------------------------------------------ keyboard
def start_key_reader(crane: Crane, stop_flag: threading.Event) -> None:
    """Starts a daemon thread that feeds keys to the crane.

    Uses msvcrt on Windows, cbreak mode on POSIX terminals, and line input
    when stdin is not a terminal.

    Args:
        crane: Crane receiving the keys.
        stop_flag: Set when the user quits.
    """

    def feed(key: str) -> None:
        """Passes one key to the crane and handles quit.

        Args:
            key: Single character.
        """
        if not crane.on_key(key.lower()):
            stop_flag.set()

    def run() -> None:
        """Key reader thread body."""
        if not sys.stdin.isatty():
            for line in sys.stdin:
                for ch in line.strip():
                    feed(ch)
                if stop_flag.is_set():
                    return
            return
        if sys.platform == "win32":
            import msvcrt
            while not stop_flag.is_set():
                if msvcrt.kbhit():
                    feed(msvcrt.getwch())
                else:
                    time.sleep(0.02)
        else:
            import select
            import termios
            import tty
            fd = sys.stdin.fileno()
            old = termios.tcgetattr(fd)
            try:
                tty.setcbreak(fd)
                while not stop_flag.is_set():
                    ready, _, _ = select.select([sys.stdin], [], [], 0.05)
                    if ready:
                        feed(sys.stdin.read(1))
            finally:
                termios.tcsetattr(fd, termios.TCSADRAIN, old)

    threading.Thread(target=run, daemon=True).start()


# ------------------------------------------------------------------ main
def main() -> None:
    """Connects to the broker and runs the simulator until 'q'."""
    ap = argparse.ArgumentParser(description="Crane Overload MQTT simulator")
    ap.add_argument("--host", default="127.0.0.1", help="broker host (default 127.0.0.1)")
    ap.add_argument("--port", type=int, default=1883, help="broker port (default 1883)")
    args = ap.parse_args()

    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id=f"crane-sim-{random.randint(1000, 9999)}")
    client.will_set(T_STATUS, json.dumps({"online": False}), qos=1, retain=True)
    crane = Crane(client)

    def on_connect(c, _userdata, _flags, reason_code, _props):
        """Subscribes and announces online after each (re)connect."""
        if reason_code.is_failure:
            log(f"broker refused connection: {reason_code}")
            return
        c.subscribe(T_CMD, qos=1)
        c.publish(T_STATUS, json.dumps({"online": True, "fw": FW}), qos=1, retain=True)
        log(f"connected to {args.host}:{args.port}, status online")

    def on_message(_c, _userdata, msg):
        """Decodes crane/cmd and hands it to the crane."""
        try:
            crane.on_command(json.loads(msg.payload.decode("utf-8")))
        except (ValueError, UnicodeDecodeError) as exc:
            log(f"bad command payload {msg.payload!r}: {exc}")

    client.on_connect = on_connect
    client.on_message = on_message
    client.reconnect_delay_set(1, 8)
    try:
        # keepalive 2 s -> broker publishes the Last Will ~3 s after a hard kill
        client.connect(args.host, args.port, keepalive=2)
    except OSError as exc:
        sys.exit(f"cannot reach broker {args.host}:{args.port}: {exc}")
    client.loop_start()

    print(__doc__.split("Keys (terminal):")[1].split("When stdin")[0])
    stop_flag = threading.Event()
    start_key_reader(crane, stop_flag)

    last = time.monotonic()
    next_live = last
    try:
        while not stop_flag.is_set():
            time.sleep(LOOP_S)
            now = time.monotonic()
            crane.tick(now - last)
            last = now
            if now >= next_live:
                crane.publish_live()
                next_live = now + LIVE_PERIOD_S
    except KeyboardInterrupt:
        pass
    finally:
        info = client.publish(T_STATUS, json.dumps({"online": False}), qos=1, retain=True)
        info.wait_for_publish(timeout=2)
        client.loop_stop()
        client.disconnect()
        log("status offline, bye")


if __name__ == "__main__":
    main()
