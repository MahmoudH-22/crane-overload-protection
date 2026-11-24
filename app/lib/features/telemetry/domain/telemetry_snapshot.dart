import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../app/constants.dart';
import 'crane_live.dart';
import 'crane_status.dart';

part 'telemetry_snapshot.freezed.dart';

/// One timestamped value for charts.
class Sample {
  /// Creates a sample of [value] received at [at].
  const Sample(this.at, this.value);

  /// Arrival time.
  final DateTime at;

  /// Value (kg or A).
  final double value;
}

/// Everything the dashboard knows about the crane.
@freezed
abstract class TelemetrySnapshot with _$TelemetrySnapshot {
  /// Creates a snapshot.
  const factory TelemetrySnapshot({
    /// Last live sample (kept while stale so the UI can still show it greyed).
    CraneLive? live,

    /// Arrival time of [live].
    DateTime? lastLiveAt,

    /// Last `crane/status`.
    CraneStatus? status,

    /// Weight over [Timing.chartWindow], oldest first.
    @Default(<Sample>[]) List<Sample> weightHistory,

    /// Motor current over [Timing.sparklineWindow], oldest first.
    @Default(<Sample>[]) List<Sample> currentHistory,
  }) = _TelemetrySnapshot;

  const TelemetrySnapshot._();

  /// Returns a copy with [sample] (arrived at [at]) appended and old points trimmed.
  TelemetrySnapshot withLive(CraneLive sample, DateTime at) => copyWith(
    live: sample,
    lastLiveAt: at,
    weightHistory: appendWindowed(weightHistory, Sample(at, sample.kg), Timing.chartWindow),
    currentHistory: sample.amps == null
        ? currentHistory
        : appendWindowed(currentHistory, Sample(at, sample.amps!), Timing.sparklineWindow),
  );
}

/// Returns [list] + [sample], dropping samples older than [window] before it.
///
/// [list]: existing samples, oldest first. [sample]: newest sample.
/// [window]: how far back to keep.
List<Sample> appendWindowed(List<Sample> list, Sample sample, Duration window) {
  final cutoff = sample.at.subtract(window);
  return [...list.where((s) => !s.at.isBefore(cutoff)), sample];
}
