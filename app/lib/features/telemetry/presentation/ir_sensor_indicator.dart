import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Status of the IR top-of-travel sensor: amber "TOP" when it sees the hook, grey "clear" otherwise.
class IrSensorIndicator extends StatelessWidget {
  /// Creates the indicator; [active] is `crane/live.top`, null when no data yet; [fitted] false shows "n/a".
  const IrSensorIndicator({super.key, required this.active, this.fitted = true});

  /// Whether the IR sensor sees the hook (null = unknown).
  final bool? active;

  /// Whether the crane reports the IR sensor as fitted.
  final bool fitted;

  /// Builds the icon + label.
  @override
  Widget build(BuildContext context) {
    final colors = context.status;
    final (label, color) = switch (active) {
      _ when !fitted => ('n/a', colors.idle),
      true => ('TOP', colors.warn),
      false => ('clear', colors.idle),
      null => ('–', colors.idle),
    };
    // Lives in a narrow column (height card): shrink rather than overflow.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Tooltip(
        message: 'IR top-of-travel sensor',
        child: Semantics(
          label: 'IR top sensor: $label',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: active == true ? color : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors, size: 14, color: active == true ? Colors.white : color),
                const SizedBox(width: 3),
                Text(
                  'IR $label',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: active == true ? Colors.white : color,
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
