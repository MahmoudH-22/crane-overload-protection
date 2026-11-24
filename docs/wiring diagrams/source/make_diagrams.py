"""Generates the crane wiring diagrams (SVG) in docs/wiring diagrams/.

Run from the repo root:  python "docs/wiring diagrams/source/make_diagrams.py"
Every diagram uses the same small drawing helpers so they look alike. Pins follow docs/exp/01-overview-power-and-pins.md (full-crane pin map).
"""

from pathlib import Path

OUT = Path(__file__).resolve().parent.parent

# ------------------------------------------------------------------ colours
RED, BLACK, ORANGE, YELLOW, BLUE, GREEN, WHITE, PURPLE, BROWN, TEAL, GREY = (
    "#d32f2f", "#111111", "#f57c00", "#e0b000", "#1e88e5", "#2e9d48", "#9aa0a6", "#7b1fa2", "#8d5524", "#00838f",
    "#777777")
UNO_FILL, MOD_FILL, PART_FILL = "#1f6fa8", "#1f5f2a", "#3c4043"


class Svg:
    """Collects SVG elements and writes the file."""

    def __init__(self, w, h, title, subtitle=""):
        """Starts a canvas of w x h with a title and an optional subtitle line."""
        self.w, self.h, self.parts = w, h, []
        self.parts.append(f'<rect width="{w}" height="{h}" fill="#f7f7f5"/>')
        self.text(40, 52, title, 30, "#222", bold=True)
        if subtitle:
            self.text(40, 84, subtitle, 17, "#555")

    def text(self, x, y, s, size=18, color="#222", bold=False, anchor="start", halo=False):
        """Adds text at (x, y); halo draws a light outline so it stays readable over wires."""
        weight = "bold" if bold else "normal"
        extra = ' paint-order="stroke" stroke="#f7f7f5" stroke-width="6"' if halo else ""
        s = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        self.parts.append(f'<text x="{x}" y="{y}" font-family="Arial, Helvetica, sans-serif" font-size="{size}" '
                          f'font-weight="{weight}" fill="{color}" text-anchor="{anchor}"{extra}>{s}</text>')

    def block(self, x, y, w, h, name, sub="", fill=MOD_FILL, name_at="top"):
        """Draws a module box with its name (top or middle) and an optional second line."""
        self.parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="16" fill="{fill}"/>')
        ty = y + 40 if name_at == "top" else y + h / 2
        self.text(x + w / 2, ty, name, 26, "white", bold=True, anchor="middle")
        if sub:
            self.text(x + w / 2, ty + 28, sub, 17, "#dfe6ea", anchor="middle")

    def pin(self, x, y, label, side):
        """Draws a pin square on a block edge at (x, y) with its label inside the block ('left' or 'right' edge)."""
        self.parts.append(f'<rect x="{x - 12}" y="{y - 12}" width="24" height="24" fill="#222"/>')
        if side == "right":
            self.text(x - 22, y + 7, label, 19, "white", bold=True, anchor="end")
        elif side == "left":
            self.text(x + 22, y + 7, label, 19, "white", bold=True)
        elif side == "top":
            self.text(x, y + 38, label, 16, "white", bold=True, anchor="middle")
        else:  # bottom
            self.text(x, y - 22, label, 16, "white", bold=True, anchor="middle")

    def wire(self, pts, color, width=6, label=None, at=None, lcolor="#333"):
        """Draws a polyline wire through pts; label is placed at 'at' (x, y)."""
        d = " ".join(f"{x},{y}" for x, y in pts)
        self.parts.append(f'<polyline points="{d}" fill="none" stroke="{color}" stroke-width="{width}" '
                          f'stroke-linejoin="round" stroke-linecap="round"/>')
        if label:
            x, y = at if at else pts[0]
            self.text(x, y, label, 17, lcolor, halo=True)

    def dot(self, x, y, color="#222"):
        """Junction dot."""
        self.parts.append(f'<circle cx="{x}" cy="{y}" r="8" fill="{color}"/>')

    def resistor(self, cx, cy, label, vertical=False, note="", size=80):
        """Resistor body centred on (cx, cy), drawn over a wire; size = body length."""
        w, h = (28, size) if vertical else (size, 28)
        self.parts.append(f'<rect x="{cx - w / 2}" y="{cy - h / 2}" width="{w}" height="{h}" rx="10" '
                          f'fill="#ead7a6" stroke="#8a6d3b" stroke-width="3"/>')
        if vertical:
            self.text(cx + 24, cy + 6, label, 18, "#5d4037", bold=True)
            if note:
                self.text(cx + 24, cy + 28, note, 15, "#666")
        else:
            self.text(cx, cy - 24, label, 18, "#5d4037", bold=True, anchor="middle")
            if note:
                self.text(cx, cy + 40, note, 15, "#666", anchor="middle")

    def gnd(self, x, y):
        """Ground symbol hanging from (x, y)."""
        self.parts.append(f'<line x1="{x}" y1="{y}" x2="{x}" y2="{y + 18}" stroke="#111" stroke-width="4"/>')
        for i, half in enumerate((18, 11, 4)):
            yy = y + 18 + i * 7
            self.parts.append(f'<line x1="{x - half}" y1="{yy}" x2="{x + half}" y2="{yy}" stroke="#111" '
                              f'stroke-width="4"/>')

    def gnd_up(self, x, y):
        """Ground symbol above (x, y), for a part whose ground end points up."""
        self.parts.append(f'<line x1="{x}" y1="{y}" x2="{x}" y2="{y - 18}" stroke="#111" stroke-width="4"/>')
        for i, half in enumerate((18, 11, 4)):
            yy = y - 18 - i * 7
            self.parts.append(f'<line x1="{x - half}" y1="{yy}" x2="{x + half}" y2="{yy}" stroke="#111" '
                              f'stroke-width="4"/>')

    def vflag(self, x, y, label="5V", color=RED):
        """Supply arrow pointing up from (x, y) with its label (e.g. 5V)."""
        self.parts.append(f'<line x1="{x}" y1="{y}" x2="{x}" y2="{y - 22}" stroke="{color}" stroke-width="4"/>')
        self.parts.append(f'<polygon points="{x - 10},{y - 20} {x + 10},{y - 20} {x},{y - 36}" fill="{color}"/>')
        self.text(x, y - 44, label, 17, color, bold=True, anchor="middle")

    def dflag(self, x, y, label="5V", color=RED):
        """Supply arrow pointing down from (x, y) with its label below."""
        self.parts.append(f'<line x1="{x}" y1="{y}" x2="{x}" y2="{y + 22}" stroke="{color}" stroke-width="4"/>')
        self.parts.append(f'<polygon points="{x - 10},{y + 20} {x + 10},{y + 20} {x},{y + 36}" fill="{color}"/>')
        self.text(x, y + 58, label, 17, color, bold=True, anchor="middle")

    def switch(self, x, y, label, note="", nc=False):
        """Switch between (x, y) and (x + 60, y), drawn over a wire; nc draws the closed-at-rest style."""
        self.parts.append(f'<rect x="{x - 4}" y="{y - 8}" width="68" height="16" fill="#f7f7f5"/>')
        for xx in (x, x + 60):
            self.parts.append(f'<circle cx="{xx}" cy="{y}" r="7" fill="#f7f7f5" stroke="#111" stroke-width="3"/>')
        if nc:
            self.parts.append(f'<line x1="{x}" y1="{y - 9}" x2="{x + 60}" y2="{y - 9}" stroke="#111" '
                              f'stroke-width="4"/>')
            self.parts.append(f'<line x1="{x + 30}" y1="{y - 9}" x2="{x + 30}" y2="{y - 30}" stroke="#111" '
                              f'stroke-width="4"/>')
        else:
            self.parts.append(f'<line x1="{x}" y1="{y}" x2="{x + 56}" y2="{y - 26}" stroke="#111" '
                              f'stroke-width="4"/>')
        self.text(x + 30, y - 40, label, 17, "#222", bold=True, anchor="middle")
        if note:
            self.text(x + 30, y + 32, note, 15, "#666", anchor="middle")

    def button(self, x, y, label, note=""):
        """Push button (normally open) between (x, y) and (x, y + 60), vertical."""
        self.parts.append(f'<rect x="{x - 8}" y="{y - 4}" width="16" height="68" fill="#f7f7f5"/>')
        for yy in (y, y + 60):
            self.parts.append(f'<circle cx="{x}" cy="{yy}" r="7" fill="#f7f7f5" stroke="#111" stroke-width="3"/>')
        self.parts.append(f'<line x1="{x + 14}" y1="{y - 4}" x2="{x + 14}" y2="{y + 64}" stroke="#111" '
                          f'stroke-width="4"/>')
        self.parts.append(f'<line x1="{x + 14}" y1="{y + 30}" x2="{x + 30}" y2="{y + 30}" stroke="#111" '
                          f'stroke-width="4"/>')
        self.text(x + 40, y + 26, label, 18, "#222", bold=True)
        if note:
            self.text(x + 40, y + 48, note, 15, "#666")

    def led(self, x, y, color, label):
        """LED pointing down between (x, y) and (x, y + 40) (anode on top)."""
        self.parts.append(f'<polygon points="{x - 16},{y} {x + 16},{y} {x},{y + 28}" fill="{color}" '
                          f'stroke="#111" stroke-width="3"/>')
        self.parts.append(f'<line x1="{x - 16}" y1="{y + 30}" x2="{x + 16}" y2="{y + 30}" stroke="#111" '
                          f'stroke-width="4"/>')
        self.parts.append(f'<line x1="{x + 20}" y1="{y + 8}" x2="{x + 34}" y2="{y - 6}" stroke="{color}" '
                          f'stroke-width="3"/>')
        self.text(x + 40, y + 22, label, 17, "#222", bold=True)

    def notes(self, y, lines, title="Notes"):
        """Notes box at the bottom starting at y."""
        h = 50 + 30 * len(lines)
        self.parts.append(f'<rect x="30" y="{y}" width="{self.w - 60}" height="{h}" rx="10" fill="#ffffff" '
                          f'stroke="#d9d9d9" stroke-width="2"/>')
        self.text(52, y + 34, title, 20, "#222", bold=True)
        for i, line in enumerate(lines):
            self.text(52, y + 66 + 30 * i, "• " + line, 17, "#333")

    def save(self, name):
        """Writes the SVG file."""
        body = "\n".join(self.parts)
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {self.w} {self.h}" width="{self.w}" '
               f'height="{self.h}">\n{body}\n</svg>\n')
        (OUT / name).write_text(svg, encoding="utf-8")
        print("wrote", OUT / name)


def motor(with_current_sensor):
    """Motor + L298N + encoder (+ ACS712 in series with the motor when with_current_sensor)."""
    title = ("Motor GA25-370 12 V with Hall encoder + L298N" + (" + ACS712 current sensor" if with_current_sensor else "")
             + " → Arduino Uno")
    s = Svg(1640, 1240, title, "Arrows marked 5V go to the Uno 5V pin; every ground symbol joins the Uno GND and the "
                               "12 V supply −. Motor power never comes from the Uno.")
    mx = 1290 if with_current_sensor else 1210  # motor / encoder x

    # Uno
    s.block(60, 120, 320, 780, "Arduino", "UNO R3", UNO_FILL, name_at="middle")
    uno_pins = {"D5": 300, "D7": 380, "D10": 540, "D2": 700, "D3": 780}
    if with_current_sensor:
        uno_pins["A1"] = 180
    for name, y in uno_pins.items():
        s.pin(380, y, name, "right")
    s.pin(380, 860, "GND", "right")

    # L298N
    s.block(640, 220, 300, 400, "L298N", "H-bridge driver", PART_FILL)
    for name, y in {"ENA": 300, "IN1": 380, "IN2": 540}.items():
        s.pin(640, y, name, "left")
    for name, y in {"OUT1": 300, "OUT2": 540}.items():
        s.pin(940, y, name, "right")
    s.pin(720, 620, "+12V", "bottom")
    s.pin(860, 620, "GND", "bottom")
    s.text(790, 652, "remove the ENA jumper · leave the 5V terminal unconnected", 14, "#666", anchor="middle")

    # control wires
    s.wire([(380, 300), (640, 300)], ORANGE, label="D5 → ENA (PWM = speed)", at=(400, 288))
    s.wire([(380, 380), (640, 380)], YELLOW)
    s.switch(440, 380, "Top limit switch", nc=True)
    s.dot(560, 380)
    s.wire([(560, 380), (560, 410)], GREY, 4)
    s.resistor(560, 445, "10 kΩ", vertical=True, note="pull-down", size=60)
    s.wire([(560, 475), (560, 485)], GREY, 4)
    s.gnd(560, 485)
    s.wire([(380, 540), (640, 540)], BLUE, label="D10 → IN2", at=(400, 528))
    s.text(395, 420, "COM–NC", 15, "#333")
    s.text(395, 440, "D7 → switch → IN1", 15, "#333")

    # 12 V supply chain
    s.wire([(720, 620), (720, 1040)], RED)
    s.text(710, 745, "+12 V", 17, RED, bold=True, anchor="end", halo=True)
    s.parts.append('<rect x="560" y="820" width="270" height="130" rx="10" fill="#fff3e0" stroke="#f57c00" '
                   'stroke-width="2" stroke-dasharray="8 6"/>')
    s.text(695, 846, "Power switch + E-stop (NC)", 15, "#e65100", bold=True, anchor="middle")
    s.text(695, 866, "in series, on the control panel", 14, "#e65100", anchor="middle")
    s.text(695, 886, "(control_panel_wiring.svg)", 14, "#e65100", anchor="middle")
    s.switch(690, 925, "", nc=True)
    s.wire([(860, 620), (860, 1040)], BLACK)
    s.block(620, 1040, 340, 80, "12 V supply ≥ 2 A", "", "#5d4037", name_at="middle")
    s.text(705, 1030, "+", 22, RED, bold=True, anchor="middle")
    s.text(875, 1030, "−", 22, BLACK, bold=True, anchor="middle")
    s.wire([(380, 860), (470, 860), (470, 990), (860, 990)], BLACK)
    s.text(480, 1012, "Uno GND ↔ supply − (common ground)", 15, "#333")
    s.dot(860, 990)

    # motor
    s.block(mx, 180, 300, 700, "GA25-370 12 V", "gear motor + Hall encoder", PART_FILL)
    s.pin(mx, 300, "M+ (red)", "left")
    s.pin(mx, 540, "M− (white)", "left")
    s.parts.append(f'<line x1="{mx + 20}" y1="620" x2="{mx + 280}" y2="620" stroke="#888" stroke-width="2" stroke-dasharray="6 6"/>')
    s.text(mx + 150, 650, "encoder board (back of the motor)", 15, "#dfe6ea", anchor="middle")
    s.wire([(940, 540), (mx, 540)], BLACK, label="OUT2 → M−", at=(980, 528))
    if with_current_sensor:
        ax, ay = 1010, 230
        s.block(ax, ay, 210, 140, "ACS712-5A", "", "#6a1b9a")
        s.pin(ax, 300, "IP+", "left")
        s.pin(ax + 210, 300, "IP−", "right")
        s.wire([(940, 300), (ax, 300)], RED)
        s.wire([(ax + 210, 300), (mx, 300)], RED)
        for name, x in {"VCC": ax + 45, "GND": ax + 105, "OUT": ax + 165}.items():
            s.pin(x, ay + 140, name, "bottom")
        s.wire([(ax + 45, ay + 152), (ax + 45, ay + 180)], RED, 4)
        s.text(ax + 45, ay + 200, "5V", 16, RED, bold=True, anchor="middle")
        s.wire([(ax + 105, ay + 152), (ax + 105, ay + 170)], BLACK, 4)
        s.gnd(ax + 105, ay + 170)
        s.wire([(ax + 165, ay + 152), (ax + 165, ay + 220), (ax + 250, ay + 220), (ax + 250, 150),
                (420, 150), (420, 180), (380, 180)], PURPLE)
        s.text(560, 140, "ACS712 OUT → A1 (2.5 V at 0 A, ±185 mV per A)", 17, "#333", halo=True)
        s.text(ax + 105, ay - 14, "in series with the motor (OUT1 → IP+ → IP− → M+)", 14, "#6a1b9a",
               anchor="middle")
    else:
        s.wire([(940, 300), (mx, 300)], RED, label="OUT1 → M+", at=(980, 288))
    s.text(mx + 150, 910, "Lifts the wrong way? swap M+ and M−", 15, "#666", anchor="middle")

    # encoder
    s.pin(mx, 700, "C1 / A (yellow)", "left")
    s.pin(mx, 780, "C2 / B (green)", "left")
    s.text(mx + 150, 835, "blue → 5V · black → GND", 16, "#dfe6ea", anchor="middle")
    s.text(mx + 150, 860, "usual colours: check the board label", 14, "#dfe6ea", anchor="middle")
    s.wire([(mx, 700), (380, 700)], GREEN, label="A → D2 (interrupt)", at=(400, 688))
    s.wire([(mx, 780), (380, 780)], WHITE, label="B → D3 (interrupt)", at=(400, 768))
    # A pull-up goes up, B pull-up goes down, so they never cross the other wire
    s.dot(1040, 700)
    s.wire([(1040, 700), (1040, 680)], GREY, 4)
    s.resistor(1040, 650, "4.7 kΩ", vertical=True, size=60)
    s.vflag(1040, 620)
    s.dot(1110, 780)
    s.wire([(1110, 780), (1110, 800)], GREY, 4)
    s.resistor(1110, 830, "4.7 kΩ", vertical=True, size=60)
    s.dflag(1110, 860)
    s.text(1060, 950, "4.7 kΩ pull-ups to 5V (needed if the encoder board has none)", 14, "#666", anchor="middle")

    lines = [
        "L298N: D5 → ENA (PWM speed), D7 → IN1, D10 → IN2. IN1 HIGH + IN2 LOW = LIFT, IN1 LOW + IN2 HIGH = LOWER, "
        "both LOW = brake.",
        "Top limit switch (COM–NC) in the IN1 wire + 10 kΩ pull-down: at the top it opens, IN1 falls LOW and the motor "
        "cannot lift any more, even if the code is wrong.",
        "12 V supply → power switch → E-stop (NC) → L298N +12V: pressing the E-stop cuts motor power in hardware.",
        "Common ground: L298N GND, 12 V supply −, Uno GND and the encoder black wire all connected.",
        "GA25-370 encoder (on the motor shaft, 11 pulses per motor turn): blue 5V, black GND, yellow C1 → D2, "
        "green C2 → D3. Pulses per drum turn = 11 × gear ratio.",
        "D8 / D9 are kept for the HC-05 on AltSoftSerial: the fast encoder pulses would be lost with SoftwareSerial.",
    ]
    if with_current_sensor:
        lines.append("ACS712-5A in series with motor lead M+: VCC 5V, GND, OUT → A1. Jam = current above the "
                     "threshold for 0.3 s while driving.")
    s.h = 1150 + 70 + 30 * len(lines)
    s.parts[0] = f'<rect width="{s.w}" height="{s.h}" fill="#f7f7f5"/>'
    s.notes(1150, lines)
    s.save("motor_l298n_acs712_wiring_with_current_sensor.svg" if with_current_sensor else "motor_l298n_wiring.svg")


def ultrasonic():
    """HC-SR04 under the basket, wired to D4 / D11, with a side view of the hook."""
    s = Svg(1500, 980, "Ultrasonic HC-SR04 (under the basket, pointing down) → Arduino Uno",
            "Measures the distance from the basket bottom to whatever is below it (table or an object).")
    s.block(60, 130, 320, 420, "Arduino", "UNO R3", UNO_FILL, name_at="middle")
    for name, y in {"5V": 200, "D4": 280, "D11": 360, "GND": 440}.items():
        s.pin(380, y, name, "right")
    s.block(820, 100, 300, 380, "HC-SR04", "ultrasonic sensor", "#1565c0")
    for name, y in {"VCC": 200, "Trig": 280, "Echo": 360, "GND": 440}.items():
        s.pin(820, y, name, "left")
    s.parts.append('<rect x="470" y="170" width="260" height="300" rx="14" fill="#e0e0e0" opacity="0.6"/>')
    s.text(600, 500, "4-core flexible cable, ≈ 0.7 m", 16, "#555", bold=True, anchor="middle")
    s.text(600, 522, "runs along the rope (see right)", 15, "#555", anchor="middle")
    s.wire([(380, 200), (820, 200)], RED, label="5V → VCC", at=(400, 188))
    s.wire([(380, 280), (820, 280)], ORANGE, label="D4 → Trig (10 µs pulse)", at=(400, 268))
    s.wire([(380, 360), (820, 360)], GREEN, label="Echo → D11 (pulse length = time)", at=(400, 348))
    s.wire([(380, 440), (820, 440)], BLACK, label="GND → GND", at=(400, 428))

    # side view
    x0 = 1210
    s.text(x0 + 90, 140, "Side view of the hook", 18, "#222", bold=True, anchor="middle")
    s.parts.append(f'<rect x="{x0 - 20}" y="160" width="230" height="22" fill="#a1887f"/>')
    s.text(x0 + 90, 176, "arm + pulley", 13, "white", anchor="middle")
    s.wire([(x0 + 90, 182), (x0 + 90, 300)], "#6d4c41", 3)
    s.wire([(x0 + 100, 182), (x0 + 100, 300)], GREY, 3)
    s.text(x0 + 110, 240, "rope + cable", 13, "#555")
    s.text(x0 + 110, 256, "(tied every 10 cm)", 13, "#555")
    s.parts.append(f'<rect x="{x0 + 50}" y="300" width="80" height="10" fill="#90a4ae"/>')
    s.text(x0 - 4, 312, "top plate", 13, "#333", anchor="end")
    s.parts.append(f'<rect x="{x0 + 40}" y="318" width="100" height="22" fill="#b0bec5" stroke="#455a64"/>')
    s.text(x0 - 4, 334, "load cell", 13, "#333", anchor="end")
    s.parts.append(f'<rect x="{x0 + 50}" y="348" width="80" height="10" fill="#90a4ae"/>')
    s.wire([(x0 + 90, 358), (x0 + 90, 380)], "#555", 3)
    s.parts.append(f'<rect x="{x0 + 45}" y="380" width="90" height="70" fill="#ffcc80" stroke="#ef6c00"/>')
    s.text(x0 + 90, 420, "basket", 14, "#333", anchor="middle")
    s.parts.append(f'<rect x="{x0 + 60}" y="452" width="60" height="18" rx="4" fill="#1565c0"/>')
    s.text(x0 - 4, 466, "HC-SR04", 13, "#1565c0", anchor="end")
    s.wire([(x0 + 100, 310), (x0 + 150, 310), (x0 + 150, 460), (x0 + 120, 460)], GREY, 3)
    s.text(x0 + 156, 380, "cable clipped to the", 12, "#555")
    s.text(x0 + 156, 395, "top plate, then down", 12, "#555")
    for dx in (-10, 0, 10):
        s.wire([(x0 + 90 + dx, 474), (x0 + 90 + dx * 3, 640)], "#90caf9", 2)
    s.parts.append(f'<rect x="{x0 - 20}" y="640" width="230" height="16" fill="#8d6e63"/>')
    s.text(x0 + 90, 680, "table", 14, "#333", anchor="middle")
    s.text(x0 + 200, 560, "us", 16, "#1565c0", bold=True)

    s.notes(740, [
        "VCC 5V, GND, Trig → D4, Echo → D11. Both are 5 V signals, so no divider is needed.",
        "Distance = echo pulse time × 343 m/s ÷ 2. 346 mm of travel = about 2 ms round trip; use a 6 ms timeout so "
        "the 50 ms loop stays fast.",
        "Obstacle rule (Uno): object if us < h − 30 mm (or no echo) while h ≥ 50 mm → LOWER refused.",
        "The sensor hangs under the load cell, so its weight is in the reading: tare with it fitted.",
        "Tie the cable to the rope and clip it to the top plate (above the load cell), so the hanging cable's weight "
        "does not change the reading as the hook moves.",
        "Keep the wires twisted / in one sheath, away from the motor wires.",
    ])
    s.save("ultrasonic_hcsr04_wiring.svg")


def panel():
    """Control panel: LCD + PCF8574 (buttons, key, LEDs) on I2C, STOP, buzzer, E-stop + power switch."""
    s = Svg(1700, 1320, "Control panel (box lid) → Arduino Uno",
            "LCD and PCF8574 expander share the I2C bus (A4 / A5). STOP, buzzer and E-stop sense use their own pins.")
    s.block(60, 120, 320, 920, "Arduino", "UNO R3", UNO_FILL, name_at="middle")
    for name, y in {"A4 SDA": 170, "A5 SCL": 240, "D12": 880, "D6": 950, "A3": 1010}.items():
        s.pin(380, y, name, "right")

    # LCD
    s.block(700, 110, 300, 170, "LCD 16×2", "I2C backpack 0x27", "#004d40")
    s.pin(700, 170, "SDA", "left")
    s.pin(700, 240, "SCL", "left")
    s.wire([(1000, 160), (1050, 160)], RED, 4)
    s.vflag(1050, 160)
    s.wire([(1000, 240), (1050, 240)], BLACK, 4)
    s.gnd(1050, 240)
    s.text(1080, 205, "VCC 5V / GND", 14, "#666")
    s.wire([(380, 170), (700, 170)], BLUE, label="SDA", at=(430, 158))
    s.wire([(380, 240), (700, 240)], YELLOW, label="SCL", at=(430, 228))

    # PCF8574
    px, py = 700, 330
    s.block(px, py, 300, 480, "PCF8574", "I/O expander 0x20", "#4e342e")
    s.pin(px, py + 70, "SDA", "left")
    s.pin(px, py + 130, "SCL", "left")
    s.dot(560, 170)
    s.dot(620, 240)
    s.wire([(560, 170), (560, py + 70), (px, py + 70)], BLUE)
    s.wire([(620, 240), (620, py + 130), (px, py + 130)], YELLOW)
    s.text(px + 150, py + 300, "VCC 5V · GND", 15, "#d7ccc8", anchor="middle")
    s.text(px + 150, py + 322, "A0–A2 to GND → 0x20", 15, "#d7ccc8", anchor="middle")

    rows = [("P0", "LIFT"), ("P1", "LOWER"), ("P2", "RESET"), ("P3", "MODE key: closed = REMOTE, open = LOCAL")]
    for i, (pn, name) in enumerate(rows):
        y = py + 60 + 60 * i
        s.pin(px + 300, y, pn, "right")
        s.wire([(px + 300, y), (1100, y)], GREY, 4)
        s.switch(1100, y, "")
        s.wire([(1160, y), (1200, y)], GREY, 4)
        s.gnd(1200, y)
        s.text(1235, y + 6, name, 16, "#222", bold=True)

    leds = [("P4", GREEN, "green: ready / link OK"), ("P5", "#ffb300", "amber: moving / near max"),
            ("P6", RED, "red: OVERLOAD / JAM / E-STOP")]
    for i, (pn, col, label) in enumerate(leds):
        y = py + 330 + 50 * i
        s.pin(px + 300, y, pn, "right")
        s.wire([(px + 300, y), (1060, y)], GREY, 4)
        s.resistor(1100, y, "330 Ω" if i == 0 else "")
        s.wire([(1140, y), (1200, y)], GREY, 4)
        s.parts.append(f'<circle cx="1216" cy="{y}" r="16" fill="{col}" stroke="#111" stroke-width="3"/>')
        s.wire([(1232, y), (1290, y)], GREY, 4)
        s.text(1320, y + 6, label, 15, "#222")
    s.wire([(1290, py + 330), (1290, py + 430)], RED, 4)
    s.vflag(1290, py + 330)
    s.text(1030, py + 485, "5V → LED → 330 Ω → pin: pin LOW = LED on (~9 mA)", 14, "#666")

    # STOP button on D12
    s.wire([(380, 880), (600, 880)], ORANGE, label="D12 (INPUT_PULLUP)", at=(400, 868))
    s.switch(600, 880, "STOP (NC)", "opens when pressed", nc=True)
    s.wire([(660, 880), (700, 880), (700, 900)], ORANGE)
    s.gnd(700, 900)

    # Buzzer
    s.wire([(380, 950), (760, 950)], PURPLE, label="D6 → buzzer I/O", at=(400, 938))
    s.block(760, 915, 200, 80, "Buzzer", "active module", "#37474f", name_at="middle")
    s.text(1060, 960, "VCC 5V · GND · I/O", 14, "#666")

    # E-stop + power switch + divider (divider above the 12 V line, so the A3 wire never crosses it)
    ey = 1200
    s.block(60, ey - 45, 240, 90, "12 V supply", "≥ 2 A", "#5d4037", name_at="middle")
    s.wire([(300, ey), (1500, ey)], RED)
    s.switch(360, ey, "Power switch", "whole crane")
    s.dot(470, ey)
    s.wire([(470, ey), (470, ey + 80), (520, ey + 80)], RED, 4)
    s.text(530, ey + 86, "→ Uno power (barrel jack, or a 12 V → 5 V buck)", 15, RED)
    s.switch(620, ey, "E-STOP (NC)", "mushroom, latching", nc=True)
    s.text(1100, ey - 14, "→ L298N +12V (motor power only)", 17, RED, bold=True, halo=True)
    dx = 1000
    s.dot(dx, ey)
    s.wire([(dx, ey), (dx, ey - 20)], GREY, 4)
    s.resistor(dx, ey - 55, "10 kΩ", vertical=True, size=60)
    s.wire([(dx, ey - 85), (dx, ey - 110)], GREY, 4)
    s.dot(dx, ey - 110)
    s.wire([(dx, ey - 110), (dx, ey - 130)], GREY, 4)
    s.resistor(dx, ey - 160, "4.7 kΩ", vertical=True, size=60)
    s.wire([(dx, ey - 190), (dx, ey - 200)], GREY, 4)
    s.gnd_up(dx, ey - 200)
    s.wire([(380, 1010), (420, 1010), (420, ey - 110), (dx, ey - 110)], TEAL)
    s.text(440, ey - 120, "A3 ← 3.8 V = E-stop released · 0 V = pressed (or wire broken)", 16, "#333", halo=True)
    s.save("control_panel_wiring.svg")


if __name__ == "__main__":
    motor(False)
    motor(True)
    ultrasonic()
    panel()
