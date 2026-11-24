import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../telemetry/presentation/telemetry_providers.dart';
import '../domain/control_availability.dart';
import '../domain/crane_command.dart';
import 'control_providers.dart';
import 'hold_button.dart';
import 'max_load_slider.dart';
import 'stop_button.dart';

/// LOWER · STOP · LIFT row, pinned at the bottom of the dashboard.
class MotionControls extends ConsumerWidget {
  /// Creates the row.
  const MotionControls({super.key});

  /// Builds the three big buttons.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(controlAvailabilityProvider);
    final held = ref.watch(controlProvider);
    final control = ref.read(controlProvider.notifier);
    final colors = context.status;

    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: HoldButton(
                  label: 'LOWER',
                  icon: Icons.arrow_downward,
                  color: colors.info,
                  availability: availability.lower,
                  held: held == CommandType.lower,
                  onPress: () => control.pressHold(CommandType.lower),
                  onRelease: () => control.releaseHold(CommandType.lower),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StopButton(availability: availability.stop, onStop: control.stop),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HoldButton(
                  label: 'LIFT',
                  icon: Icons.arrow_upward,
                  color: colors.ok,
                  availability: availability.lift,
                  held: held == CommandType.lift,
                  onPress: () => control.pressHold(CommandType.lift),
                  onRelease: () => control.releaseHold(CommandType.lift),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// RESET, TARE and the max-load slider.
class ActionsCard extends ConsumerWidget {
  /// Creates the card.
  const ActionsCard({super.key});

  /// Builds the card.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(controlAvailabilityProvider);
    final maxKg = ref.watch(telemetryProvider.select((t) => t.live?.maxKg)) ?? 1.5;
    final control = ref.read(controlProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'RESET',
                    icon: Icons.restart_alt,
                    availability: availability.reset,
                    onPressed: control.reset,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'TARE',
                    icon: Icons.exposure_zero,
                    availability: availability.tare,
                    onPressed: control.tare,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            MaxLoadSlider(maxKg: maxKg, availability: availability.setMax, onSet: control.setMax),
          ],
        ),
      ),
    );
  }
}

/// Outlined button with its disabled reason underneath.
class _ActionButton extends StatelessWidget {
  /// Creates the button.
  const _ActionButton({required this.label, required this.icon, required this.availability, required this.onPressed});

  final String label;
  final IconData icon;
  final Availability availability;
  final VoidCallback onPressed;

  /// Builds the button and reason.
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OutlinedButton.icon(onPressed: availability.enabled ? onPressed : null, icon: Icon(icon), label: Text(label)),
      const SizedBox(height: 4),
      Text(
        availability.reason ?? ' ',
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    ],
  );
}
