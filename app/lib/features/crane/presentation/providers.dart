import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/crane_repository_impl.dart';
import '../data/mqtt_data_source.dart';
import '../data/settings_store.dart';
import '../domain/crane_repository.dart';
import '../domain/entities.dart';

/// Phone storage for broker settings.
final settingsStoreProvider = Provider<SettingsStore>((ref) => SettingsStore());

/// The single crane repository for the app; disconnects when disposed.
final repositoryProvider = Provider<CraneRepository>((ref) {
  final repo = CraneRepositoryImpl(MqttDataSource());
  ref.onDispose(repo.disconnect);
  return repo;
});

/// Holds the broker settings and saves changes.
class SettingsNotifier extends AsyncNotifier<BrokerSettings> {
  /// Loads the saved settings at start-up.
  @override
  Future<BrokerSettings> build() => ref.read(settingsStoreProvider).load();

  /// Saves [settings]; dependent providers reconnect automatically.
  Future<void> save(BrokerSettings settings) async {
    await ref.read(settingsStoreProvider).save(settings);
    state = AsyncData(settings);
  }
}

/// Current broker settings.
final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, BrokerSettings>(SettingsNotifier.new);

/// Connects whenever the settings change. Watch it to show connecting / error states.
final connectionProvider = FutureProvider<void>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  await ref.read(repositoryProvider).connect(settings);
});

/// Live telemetry from crane/live.
final telemetryProvider = StreamProvider<CraneTelemetry>((ref) {
  ref.watch(connectionProvider);
  return ref.read(repositoryProvider).watchTelemetry();
});

/// Crane online status from crane/status.
final onlineProvider = StreamProvider<bool>((ref) {
  ref.watch(connectionProvider);
  return ref.read(repositoryProvider).watchOnline();
});

/// Alarm and rejection messages from crane/events.
final eventsProvider = StreamProvider<String>((ref) {
  ref.watch(connectionProvider);
  return ref.read(repositoryProvider).watchEvents();
});

/// Ticks every second so the UI can mark data older than 2 s as stale.
final clockProvider = StreamProvider<DateTime>(
    (ref) => Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()));
