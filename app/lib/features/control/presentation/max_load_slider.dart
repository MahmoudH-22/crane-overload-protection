import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../domain/control_availability.dart';

/// Overload-limit slider 0.5–1.5 kg; sends SET_MAX only when released.
class MaxLoadSlider extends StatefulWidget {
  /// Creates the slider showing the crane's current [maxKg].
  const MaxLoadSlider({super.key, required this.maxKg, required this.availability, required this.onSet});

  /// Limit reported by the crane, kg.
  final double maxKg;

  /// Enabled state and reason.
  final Availability availability;

  /// Called with the new limit when the slider is released.
  final ValueChanged<double> onSet;

  @override
  State<MaxLoadSlider> createState() => _MaxLoadSliderState();
}

class _MaxLoadSliderState extends State<MaxLoadSlider> {
  /// Value while dragging; null shows the crane's value.
  double? _dragging;

  /// Builds the label and slider.
  @override
  Widget build(BuildContext context) {
    final shown = (_dragging ?? widget.maxKg).clamp(CraneLimits.minLimitKg, CraneLimits.maxLimitKg);
    final enabled = widget.availability.enabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Max load'),
            const Spacer(),
            Text('${shown.toStringAsFixed(2)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: shown.toDouble(),
          min: CraneLimits.minLimitKg,
          max: CraneLimits.maxLimitKg,
          divisions: 20,
          label: '${shown.toStringAsFixed(2)} kg',
          onChanged: enabled ? (v) => setState(() => _dragging = v) : null,
          onChangeEnd: enabled
              ? (v) {
                  setState(() => _dragging = null);
                  widget.onSet(double.parse(v.toStringAsFixed(2)));
                }
              : null,
        ),
        if (!enabled) Text(widget.availability.reason ?? '', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
