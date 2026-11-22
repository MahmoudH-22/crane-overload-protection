import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';

/// Vertical bar 0–346 mm with the hook marker, the top-stop zone and an optional target line.
class HeightBar extends StatelessWidget {
  /// Creates the bar for hook height [heightMm] (null = no encoder: no marker, "not fitted");
  /// [atTop] highlights the zone; [targetMm] draws a dashed target line.
  const HeightBar({super.key, required this.heightMm, required this.atTop, this.targetMm});

  /// Hook height, mm.
  final double? heightMm;

  /// IR top sensor active.
  final bool atTop;

  /// Go-to-height target, mm (null = none).
  final double? targetMm;

  /// Builds the number and the bar.
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          heightMm == null ? 'n/a' : '${heightMm!.toStringAsFixed(0)} mm',
          style: text.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SizedBox(
            width: 56,
            child: CustomPaint(
              painter: _HeightPainter(
                fraction: heightMm == null ? null : heightMm! / CraneLimits.topMm,
                zoneFraction: CraneLimits.topZoneStartMm / CraneLimits.topMm,
                targetFraction: targetMm == null ? null : targetMm! / CraneLimits.topMm,
                track: Theme.of(context).colorScheme.surfaceContainerHighest,
                zone: atTop ? context.status.warn : context.status.warn.withValues(alpha: 0.35),
                hook: Theme.of(context).colorScheme.primary,
                target: context.status.info,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints the track, top zone, target line and hook marker.
class _HeightPainter extends CustomPainter {
  /// Creates the painter; fractions are of the full travel.
  _HeightPainter({
    required this.fraction,
    required this.zoneFraction,
    required this.targetFraction,
    required this.track,
    required this.zone,
    required this.hook,
    required this.target,
  });

  final double? fraction;
  final double zoneFraction;
  final double? targetFraction;
  final Color track;
  final Color zone;
  final Color hook;
  final Color target;

  /// Draws the bar.
  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 18.0;
    final left = (size.width - barWidth) / 2;
    final bar = RRect.fromLTRBR(left, 0, left + barWidth, size.height, const Radius.circular(6));
    canvas.drawRRect(bar, Paint()..color = track);

    final zoneBottom = size.height * (1 - zoneFraction);
    canvas.drawRRect(
      RRect.fromLTRBR(left, 0, left + barWidth, zoneBottom, const Radius.circular(6)),
      Paint()..color = zone,
    );

    final tf = targetFraction;
    if (tf != null) {
      final ty = size.height * (1 - tf.clamp(0.0, 1.0));
      final dash = Paint()
        ..color = target
        ..strokeWidth = 2;
      for (var x = left - 10; x < left + barWidth + 10; x += 6) {
        canvas.drawLine(Offset(x, ty), Offset(x + 3, ty), dash);
      }
    }

    final hf = fraction;
    if (hf == null) return; // no encoder: no hook marker
    final y = size.height * (1 - hf.clamp(0.0, 1.0));
    final paint = Paint()
      ..color = hook
      ..strokeWidth = 3;
    canvas.drawLine(Offset(left - 8, y), Offset(left + barWidth + 8, y), paint);
    final path = Path()
      ..moveTo(left - 8, y - 7)
      ..lineTo(left - 8, y + 7)
      ..lineTo(left + 2, y)
      ..close();
    canvas.drawPath(path, paint);
  }

  /// Repaints when the height, target or colours change.
  @override
  bool shouldRepaint(_HeightPainter old) =>
      old.fraction != fraction ||
      old.targetFraction != targetFraction ||
      old.zone != zone ||
      old.track != track ||
      old.hook != hook ||
      old.target != target;
}
