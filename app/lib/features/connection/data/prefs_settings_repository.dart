import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logger.dart';
import '../domain/broker_settings.dart';
import '../domain/settings_repository.dart';

const _key = 'broker_settings';
const _log = Log('settings');

/// [SettingsRepository] stored as JSON in `shared_preferences`.
class PrefsSettingsRepository implements SettingsRepository {
  /// Creates the repository.
  const PrefsSettingsRepository();

  /// Loads saved settings; returns defaults if missing or corrupt.
  @override
  Future<BrokerSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return BrokerSettings.defaults();
    try {
      return BrokerSettings.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object catch (e) {
      _log.e('corrupt settings, using defaults', e);
      return BrokerSettings.defaults();
    }
  }

  /// Saves [settings] as JSON.
  @override
  Future<void> save(BrokerSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
