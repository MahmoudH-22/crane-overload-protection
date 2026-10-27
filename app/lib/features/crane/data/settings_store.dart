import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities.dart';

/// Saves broker settings on the phone.
class SettingsStore {
  static const _kHost = 'broker_host';
  static const _kPort = 'broker_port';

  /// Loads saved settings, or [BrokerSettings.fallback] the first time.
  Future<BrokerSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return BrokerSettings(
      host: p.getString(_kHost) ?? BrokerSettings.fallback.host,
      port: p.getInt(_kPort) ?? BrokerSettings.fallback.port,
    );
  }

  /// Persists [settings].
  Future<void> save(BrokerSettings settings) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kHost, settings.host);
    await p.setInt(_kPort, settings.port);
  }
}
