import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../domain/crane_state.dart';
import '../domain/load_level.dart';

/// Arc gauge 0–2 kg with the overload-limit line and a big numeric readout.
class WeightGauge extends StatelessWidget {
  /// Creates the gauge for [kg] against [maxKg] in [state].
  const WeightGauge({super.key, required this.kg, required this.maxKg, required this.state});

  /// Weight on the hook, kg.
  final double kg;

  /// Overload limit, kg.
  final double maxKg;

  /// Crane state (OVERLOAD forces red).
  final CraneState state;

  /// Builds the arc and readout.
  @override
  Widget build(BuildContext context) {
    final level = evaluateLoadLevel(kg: kg, maxKg: maxKg, state: state);
    final color = context.status.forLoad(level);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return AspectRatio(
      aspectRatio: 1.5,
      child: CustomPaint(
        painter: _GaugePainter(
          fraction: kg / CraneLimits.gaugeFullScaleKg,
          maxFraction: maxKg / CraneLimits.gaugeFullScaleKg,
          color: color,
          track: scheme.surfaceContainerHighest,
          maxLine: context.status.danger,
        ),
        child: Align(
          alignment: const Alignment(0, 0.35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                child: Text(
                  '${kg.toStringAsFixed(3)} kg',
                  style: text.displaySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Text('max ${maxKg.toStringAsFixed(2)} kg', style: text.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the gauge track, value arc and limit tick.
class _GaugePainter extends CustomPainter {
  /// Creates the painter; fractions are of the gauge full scale.
  _GaugePainter({
    required this.fraction,
    required this.maxFraction,
    required this.color,
    required this.track,
    required this.maxLine,
  });

  final double fraction;
  final double maxFraction;
  final Color color;
  final Color track;
  final Color maxLine;

  static const _start = math.pi * 5 / 6; // 150°
  static const _sweep = math.pi * 4 / 3; // 240°

  /// Draws the arcs and the limit tick.
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.09;
    final radius = math.min(size.width / 2, size.height / 1.25) - stroke;
    final center = Offset(size.width / 2, radius + stroke);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _start, _sweep, false, paint..color = track);
    final f = fraction.clamp(0.0, 1.0);
    if (f > 0) canvas.drawArc(rect, _start, _sweep * f, false, paint..color = color);

    final angle = _start + _sweep * maxFraction.clamp(0.0, 1.0);
    final dir = Offset(math.cos(angle), math.sin(angle));
    canvas.drawLine(
      center + dir * (radius - stroke * 0.9),
      center + dir * (radius + stroke * 0.9),
      Paint()
        ..color = maxLine
        ..strokeWidth = 3,
    );
  }

  /// Repaints when any input changes.
  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction || old.maxFraction != maxFraction || old.color != color || old.track != track;
}
