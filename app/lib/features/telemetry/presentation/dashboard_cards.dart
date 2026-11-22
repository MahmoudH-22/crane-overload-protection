import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../control/presentation/control_providers.dart';
import '../domain/crane_status.dart';
import '../domain/link_health.dart';
import 'height_bar.dart';
import 'ir_sensor_indicator.dart';
import 'sample_chart.dart';
import 'state_chip.dart';
import 'telemetry_providers.dart';
import 'weight_gauge.dart';

/// Dims [child] while the data is not fresh.
class _FreshnessDim extends ConsumerWidget {
  /// Wraps [child].
  const _FreshnessDim({required this.child});

  final Widget child;

  /// Builds the faded / full-opacity child.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fresh = ref.watch(linkHealthProvider) == LinkHealth.ok;
    return AnimatedOpacity(opacity: fresh ? 1 : 0.45, duration: const Duration(milliseconds: 200), child: child);
  }
}

/// Placeholder shown before the first sample.
class _NoData extends StatelessWidget {
  /// Creates the placeholder.
  const _NoData();

  /// Builds the text.
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Center(child: Text('Waiting for crane data…')),
  );
}

/// Weight gauge with the state chip on top.
class WeightCard extends ConsumerWidget {
  /// Creates the card.
  const WeightCard({super.key});

  /// Builds the card.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(telemetryProvider.select((t) => t.live));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: live == null
            ? const _NoData()
            : _FreshnessDim(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StateChip(state: live.state, mode: live.mode, source: live.source),
                    const SizedBox(height: 8),
                    WeightGauge(kg: live.kg, maxKg: live.maxKg, state: live.state),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Hook height bar.
class HeightCard extends ConsumerWidget {
  /// Creates the card.
  const HeightCard({super.key});

  /// Builds the card.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(telemetryProvider.select((t) => t.live));
    final target = ref.watch(goToTargetProvider.select((t) => t.mm));
    final fitted = ref.watch(fittedSensorsProvider);
    final hasHeight = isFitted(fitted, Sensor.height) && live?.heightMm != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text('Hook', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Expanded(
              child: _FreshnessDim(
                child: HeightBar(
                  heightMm: hasHeight ? live?.heightMm : null,
                  atTop: live?.top ?? false,
                  targetMm: hasHeight ? target : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _FreshnessDim(
              child: IrSensorIndicator(active: live?.top, fitted: isFitted(fitted, Sensor.top)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Motor current value with a 10 s sparkline.
class CurrentCard extends ConsumerWidget {
  /// Creates the card.
  const CurrentCard({super.key});

  /// Builds the card.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amps = ref.watch(telemetryProvider.select((t) => t.live?.amps));
    final history = ref.watch(telemetryProvider.select((t) => t.currentHistory));
    final fitted = isFitted(ref.watch(fittedSensorsProvider), Sensor.current);
    final hasData = ref.watch(telemetryProvider.select((t) => t.live != null));
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _FreshnessDim(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Motor current', style: text.labelLarge),
                  Text(
                    !fitted
                        ? 'not fitted'
                        : amps == null
                        ? (hasData ? 'no reading' : '– A')
                        : '${amps.toStringAsFixed(2)} A',
                    style: text.headlineSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: SampleChart(
                    samples: history,
                    window: Timing.sparklineWindow,
                    maxY: 2.0,
                    color: context.status.info,
                    showAxes: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Weight over the last 30 s with the max line.
class LiveChartCard extends ConsumerWidget {
  /// Creates the card.
  const LiveChartCard({super.key});

  /// Builds the card.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(telemetryProvider.select((t) => t.weightHistory));
    final maxKg = ref.watch(telemetryProvider.select((t) => t.live?.maxKg));
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Text('Weight, last 30 s', style: Theme.of(context).textTheme.labelLarge),
            ),
            SizedBox(
              height: 180,
              child: SampleChart(
                samples: history,
                window: Timing.chartWindow,
                maxY: CraneLimits.gaugeFullScaleKg,
                color: Theme.of(context).colorScheme.primary,
                limit: maxKg,
                limitColor: context.status.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ultrasonic sensor under the basket: distance to whatever is below, and CLEAR / OBJECT BELOW.
class ClearanceCard extends ConsumerWidget {
  /// Creates the card.
  const ClearanceCard({super.key});

  /// Builds the card.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasData = ref.watch(telemetryProvider.select((t) => t.live != null));
    final distance = ref.watch(telemetryProvider.select((t) => t.live?.ultrasonicMm));
    final obstacle = ref.watch(telemetryProvider.select((t) => t.live?.obstacle ?? false));
    final fitted = isFitted(ref.watch(fittedSensorsProvider), Sensor.ultrasonic);
    final colors = context.status;
    final text = Theme.of(context).textTheme;
    final color = obstacle ? colors.danger : colors.ok;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _FreshnessDim(
          child: Row(
            children: [
              Icon(obstacle ? Icons.back_hand : Icons.sensors, color: hasData ? color : colors.idle),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Under the load', style: text.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        !fitted
                            ? 'not fitted'
                            : !hasData
                            ? '– mm'
                            : distance == null
                            ? '< 20 mm'
                            : '${distance.toStringAsFixed(0)} mm',
                        style: text.headlineSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasData && fitted)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: obstacle ? color : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color),
                      ),
                      child: Text(
                        obstacle ? 'OBJECT BELOW' : 'CLEAR',
                        style: TextStyle(color: obstacle ? Colors.white : color, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
