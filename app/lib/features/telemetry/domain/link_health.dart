import '../../../app/constants.dart';

/// How fresh the crane data is.
enum LinkHealth {
  /// `crane/live` arrived within 1 s.
  ok,

  /// No `crane/live` for 1–3 s.
  stale,

  /// Crane reported offline (Last Will) or silent for over 3 s.
  offline,

  /// The app is not connected to the broker.
  disconnected;

  /// Short label for the connection badge.
  String get label => switch (this) {
    ok => 'Live',
    stale => 'Stale',
    offline => 'Crane offline',
    disconnected => 'Not connected',
  };
}

/// Pure staleness rule.
///
/// [brokerConnected]: the app is connected to the broker.
/// [craneOnline]: last `crane/status.online` (null if none received yet).
/// [lastLiveAt]: arrival time of the last `crane/live` since connecting.
/// [connectedAt]: when the broker connection came up (baseline if no live yet).
/// [now]: current time.
/// Returns the [LinkHealth] to show.
LinkHealth evaluateLinkHealth({
  required bool brokerConnected,
  required bool? craneOnline,
  required DateTime? lastLiveAt,
  required DateTime? connectedAt,
  required DateTime now,
}) {
  if (!brokerConnected) return LinkHealth.disconnected;
  if (craneOnline == false) return LinkHealth.offline;
  final since = lastLiveAt ?? connectedAt;
  if (since == null) return LinkHealth.offline;
  final age = now.difference(since);
  if (lastLiveAt != null && age <= Timing.staleAfter) return LinkHealth.ok;
  if (age <= Timing.offlineAfter) return LinkHealth.stale;
  return LinkHealth.offline;
}
