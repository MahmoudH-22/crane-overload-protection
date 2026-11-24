import 'broker_settings.dart';

/// Persists the broker settings between app runs.
abstract interface class SettingsRepository {
  /// Loads saved settings, or defaults when nothing is saved.
  Future<BrokerSettings> load();

  /// Saves [settings].
  Future<void> save(BrokerSettings settings);
}
