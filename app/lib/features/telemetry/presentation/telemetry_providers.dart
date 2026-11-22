import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock_providers.dart';
import '../../connection/domain/connection_state.dart';
import '../../connection/presentation/connection_providers.dart';
import '../data/telemetry_repository.dart';
import '../domain/crane_alert.dart';
import '../domain/link_health.dart';
import '../domain/telemetry_snapshot.dart';

/// Telemetry source.
final telemetryRepositoryProvider = Provider<TelemetryRepository>(
  (ref) => MqttTelemetryRepository(ref.watch(mqttGatewayProvider)),
);

/// Latest telemetry plus chart history.
final telemetryProvider = NotifierProvider<TelemetryController, TelemetrySnapshot>(TelemetryController.new);

/// Collects `crane/live` and `crane/status` into a [TelemetrySnapshot].
class TelemetryController extends Notifier<TelemetrySnapshot> {
  /// Subscribes to the repository; resets freshness on every new connection.
  @override
  TelemetrySnapshot build() {
    final repo = ref.watch(telemetryRepositoryProvider);
    final now = ref.watch(clockProvider);
    final liveSub = repo.live.listen((sample) => state = state.withLive(sample, now()));
    final statusSub = repo.status.listen((status) => state = state.copyWith(status: status));
    ref.onDispose(liveSub.cancel);
    ref.onDispose(statusSub.cancel);
    ref.listen(connectionProvider.select((c) => c.status), (previous, next) {
      if (next == BrokerStatus.connected && previous != BrokerStatus.connected) {
        // New session: freshness counts from the connection, status comes retained.
        state = state.copyWith(lastLiveAt: null, status: null);
      }
    });
    return const TelemetrySnapshot();
  }
}

/// Sensors the crane reports as fitted (`crane/status.sensors`); null = not reported, assume all.
final fittedSensorsProvider = Provider<Set<String>?>((ref) {
  final list = ref.watch(telemetryProvider.select((t) => t.status?.sensors));
  return list?.toSet();
});

/// Freshness of crane data, re-evaluated every UI tick.
final linkHealthProvider = Provider<LinkHealth>((ref) {
  ref.watch(tickerProvider);
  final connection = ref.watch(connectionProvider);
  final telemetry = ref.watch(telemetryProvider);
  return evaluateLinkHealth(
    brokerConnected: connection.isConnected,
    craneOnline: telemetry.status?.online,
    lastLiveAt: telemetry.lastLiveAt,
    connectedAt: connection.connectedAt,
    now: ref.read(clockProvider)(),
  );
});

/// Alert to show on the banner (null when none).
final alertProvider = Provider<CraneAlert?>(
  (ref) => evaluateAlert(
    health: ref.watch(linkHealthProvider),
    state: ref.watch(telemetryProvider.select((t) => t.live?.state)),
    obstacle: ref.watch(telemetryProvider.select((t) => t.live?.obstacle ?? false)),
  ),
);
