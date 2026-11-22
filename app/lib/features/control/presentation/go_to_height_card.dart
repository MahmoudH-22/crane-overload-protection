import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../telemetry/presentation/telemetry_providers.dart';
import '../domain/control_availability.dart';
import '../domain/crane_command.dart';
import 'control_providers.dart';

/// Target-height slider and a tap-once GO button: the crane goes to the target, stops and the card resets.
class GoToHeightCard extends ConsumerWidget {
  /// Creates the card.
  const GoToHeightCard({super.key});

  /// Builds the card.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(goToTargetProvider.select((t) => t.mm));
    final height = ref.watch(telemetryProvider.select((t) => t.live?.heightMm));
    final availability = ref.watch(controlAvailabilityProvider.select((a) => a.goTo));
    final moving = ref.watch(controlProvider) == CommandType.goTo;
    final targets = ref.read(goToTargetProvider.notifier);
    final control = ref.read(controlProvider.notifier);
    final text = Theme.of(context).textTheme;

    final shown = (target ?? height ?? 100.0).clamp(CraneLimits.bottomMm, CraneLimits.topMm).toDouble();
    final direction = target == null || height == null ? null : goToDirection(heightMm: height, targetMm: target);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Go to height', style: text.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Text(
                  target == null ? 'no target' : '${target.toStringAsFixed(0)} mm',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: '−10 mm',
                  icon: const Icon(Icons.remove),
                  onPressed: () => targets.setTarget(shown - 10),
                ),
                Expanded(
                  child: Slider(
                    value: shown,
                    min: CraneLimits.bottomMm,
                    max: CraneLimits.topMm,
                    label: '${shown.toStringAsFixed(0)} mm',
                    onChanged: targets.setTarget,
                  ),
                ),
                IconButton(
                  tooltip: '+10 mm',
                  icon: const Icon(Icons.add),
                  onPressed: () => targets.setTarget(shown + 10),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _GoButton(
              label: goButtonLabel(target: target, height: height, direction: direction, moving: moving),
              icon: moving
                  ? Icons.cancel
                  : switch (direction) {
                      CommandType.lift => Icons.north,
                      CommandType.lower => Icons.south,
                      _ => Icons.my_location,
                    },
              color: moving ? context.status.warn : context.status.info,
              availability: moving ? const Availability.enabled() : availability,
              onTap: control.toggleGoTo,
            ),
            const SizedBox(height: 4),
            Text(
              moving
                  ? 'Moving… tap CANCEL or the red STOP to stop now.'
                  : 'Tap GO: the crane goes to the target and stops there. Safety rules still apply.',
              textAlign: TextAlign.center,
              style: text.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Large tap button for GO / CANCEL with the disabled reason shown on it.
class _GoButton extends StatelessWidget {
  /// Creates the button.
  const _GoButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.availability,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Availability availability;
  final VoidCallback onTap;

  /// Builds the button.
  @override
  Widget build(BuildContext context) {
    final enabled = availability.enabled;
    return SizedBox(
      height: 64,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: enabled
            ? () {
                HapticFeedback.mediumImpact();
                onTap();
              }
            : null,
        // Fixed height: shrink long labels ("CANCEL · 200 mm to go") and large fonts instead of overflowing.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              if (!enabled) Text(availability.reason ?? '', style: const TextStyle(fontSize: 11), maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label for the GO button, e.g. "GO ↑ 88 mm" or "CANCEL · 40 mm to go".
///
/// [target]: chosen height. [height]: current hook height. [direction]: needed direction.
/// [moving]: an automatic move is running. Returns the text shown on the button.
String goButtonLabel({
  required double? target,
  required double? height,
  required CommandType? direction,
  bool moving = false,
}) {
  if (moving) {
    if (target == null || height == null) return 'CANCEL';
    return 'CANCEL · ${(target - height).abs().toStringAsFixed(0)} mm to go';
  }
  if (target == null || height == null) return 'GO';
  if (direction == null) return 'AT TARGET';
  final arrow = direction == CommandType.lift ? '↑' : '↓';
  return 'GO $arrow ${(target - height).abs().toStringAsFixed(0)} mm';
}
