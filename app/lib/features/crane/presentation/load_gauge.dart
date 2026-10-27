import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Half-circle gauge showing the load against the overload limit.
class LoadGauge extends StatelessWidget {
  /// Creates a gauge for [kg] out of [maxKg]; [alarm] turns it red.
  const LoadGauge({super.key, required this.kg, required this.maxKg, this.alarm = false, this.warn = false});

  final double kg;
  final double maxKg;
  final bool alarm;
  final bool warn;

  /// Builds the gauge with the value and percentage in the middle.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = maxKg <= 0 ? 0.0 : (kg / maxKg);
    final color = alarm ? scheme.error : warn ? Colors.amber.shade700 : scheme.primary;
    return SizedBox(
      height: 150,
      child: Stack(alignment: Alignment.bottomCenter, children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _GaugePainter(ratio.clamp(0.0, 1.0).toDouble(), color, scheme.surfaceContainerHighest),
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${kg.toStringAsFixed(2)} kg',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: alarm ? scheme.error : null)),
          Text('${(ratio * 100).round()}% of max ${maxKg.toStringAsFixed(2)} kg',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
        ]),
      ]),
    );
  }
}

/// Paints the gauge track and the value arc.
class _GaugePainter extends CustomPainter {
  _GaugePainter(this.ratio, this.color, this.track);

  final double ratio;
  final Color color;
  final Color track;

  /// Draws a 180° track and the filled part for [ratio].
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width / 2, size.height) - 12;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height - 4), radius: r);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, base..color = track);
    canvas.drawArc(rect, math.pi, math.pi * ratio, false, base..color = color);
  }

  /// Repaints only when the value or colours change.
  @override
  bool shouldRepaint(_GaugePainter old) => old.ratio != ratio || old.color != color || old.track != track;
}
