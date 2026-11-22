import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../domain/control_availability.dart';

/// Large red STOP button; fires on finger down (no wait for release).
class StopButton extends StatelessWidget {
  /// Creates the button.
  const StopButton({super.key, required this.availability, required this.onStop});

  /// Enabled state (enabled whenever the broker is connected).
  final Availability availability;

  /// Sends STOP.
  final VoidCallback onStop;

  /// Builds the button.
  @override
  Widget build(BuildContext context) {
    final enabled = availability.enabled;
    final colors = context.status;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'STOP',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: enabled
            ? (_) {
                HapticFeedback.heavyImpact();
                onStop();
              }
            : null,
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: enabled ? colors.danger : scheme.onSurface.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(4),
          // Fixed height: shrink with large system fonts instead of overflowing.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stop_circle,
                  color: enabled ? colors.onDanger : scheme.onSurface.withValues(alpha: 0.38),
                  size: 36,
                ),
                Text(
                  'STOP',
                  style: TextStyle(
                    color: enabled ? colors.onDanger : scheme.onSurface.withValues(alpha: 0.38),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
