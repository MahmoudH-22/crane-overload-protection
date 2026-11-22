import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/telemetry_snapshot.dart';

/// Line chart of [samples] over the last [window], optionally with a limit line.
///
/// Used both as the 30 s weight chart and the motor-current sparkline.
class SampleChart extends StatelessWidget {
  /// Creates the chart.
  const SampleChart({
    super.key,
    required this.samples,
    required this.window,
    required this.maxY,
    required this.color,
    this.limit,
    this.limitColor,
    this.showAxes = true,
  });

  /// Samples, oldest first.
  final List<Sample> samples;

  /// Visible time span ending at the newest sample.
  final Duration window;

  /// Top of the Y axis (grows if a sample is higher).
  final double maxY;

  /// Line colour.
  final Color color;

  /// Horizontal limit line value (e.g. max load).
  final double? limit;

  /// Colour of the limit line.
  final Color? limitColor;

  /// Show axis titles and grid (false for sparklines).
  final bool showAxes;

  /// Builds the fl_chart [LineChart].
  @override
  Widget build(BuildContext context) {
    final spots = toSpots(samples);
    final windowS = window.inMilliseconds / 1000;
    final peak = samples.fold<double>(0, (m, s) => s.value > m ? s.value : m);
    final top = peak > maxY ? (peak * 1.1) : maxY;
    final axisStyle = Theme.of(context).textTheme.labelSmall;

    return LineChart(
      LineChartData(
        minX: -windowS,
        maxX: 0,
        minY: 0,
        maxY: top,
        clipData: const FlClipData.all(),
        lineTouchData: const LineTouchData(enabled: false),
        gridData: FlGridData(show: showAxes, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: showAxes
            ? FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: top / 4,
                    getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: axisStyle),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: windowS / 3,
                    getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(0)} s', style: axisStyle),
                  ),
                ),
              )
            : const FlTitlesData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (limit != null)
              HorizontalLine(y: limit!, color: limitColor ?? Colors.red, strokeWidth: 2, dashArray: [6, 4]),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: color,
            barWidth: 2,
            isCurved: false,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}

/// Converts [samples] to chart spots with x = seconds before the newest sample.
///
/// Returns an empty list when there are no samples.
List<FlSpot> toSpots(List<Sample> samples) {
  if (samples.isEmpty) return const [];
  final newest = samples.last.at;
  return [for (final s in samples) FlSpot(s.at.difference(newest).inMilliseconds / 1000, s.value)];
}
