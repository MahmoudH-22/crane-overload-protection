import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../domain/crane_state.dart';

/// Colour-coded crane state, LOCAL / REMOTE badge and who started the motion.
class StateChip extends StatelessWidget {
  /// Creates the chip row.
  const StateChip({super.key, required this.state, required this.mode, required this.source});

  /// Crane state.
  final CraneState state;

  /// LOCAL / REMOTE.
  final CraneMode mode;

  /// Who started the current motion.
  final MotionSource source;

  /// Builds the chips.
  @override
  Widget build(BuildContext context) {
    final colors = context.status;
    final stateColor = colors.forState(state);
    final remote = mode == CraneMode.remote;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Pill(text: state.label, color: stateColor, filled: true),
        _Pill(text: remote ? 'REMOTE' : 'LOCAL', color: remote ? colors.ok : colors.warn),
        if (source == MotionSource.app || source == MotionSource.panel)
          Text('by ${source.name.toUpperCase()}', style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

/// Rounded label.
class _Pill extends StatelessWidget {
  /// Creates a pill with [text] in [color]; [filled] uses a solid background.
  const _Pill({required this.text, required this.color, this.filled = false});

  final String text;
  final Color color;
  final bool filled;

  /// Builds the pill.
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: filled ? color : color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color),
    ),
    child: Text(
      text,
      style: TextStyle(color: filled ? Colors.white : color, fontWeight: FontWeight.bold, letterSpacing: 0.5),
    ),
  );
}
