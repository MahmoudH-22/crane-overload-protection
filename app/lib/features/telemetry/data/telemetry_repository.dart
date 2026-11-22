import 'dart:convert';

import '../../../app/constants.dart';
import '../../../core/logger.dart';
import '../../connection/domain/mqtt_gateway.dart';
import '../domain/crane_live.dart';
import '../domain/crane_status.dart';

const _log = Log('telemetry');

/// Source of crane telemetry.
abstract interface class TelemetryRepository {
  /// Parsed `crane/live` samples.
  Stream<CraneLive> get live;

  /// Parsed `crane/status` messages (including the Last Will).
  Stream<CraneStatus> get status;
}

/// [TelemetryRepository] reading from an [MqttGateway].
class MqttTelemetryRepository implements TelemetryRepository {
  /// Creates the repository on top of [gateway].
  MqttTelemetryRepository(this._gateway);

  final MqttGateway _gateway;

  @override
  Stream<CraneLive> get live => _gateway.messages
      .where((m) => m.topic == Topics.live)
      .map((m) => parseLive(m.payload))
      .where((v) => v != null)
      .cast<CraneLive>();

  @override
  Stream<CraneStatus> get status => _gateway.messages
      .where((m) => m.topic == Topics.status)
      .map((m) => parseStatus(m.payload))
      .where((v) => v != null)
      .cast<CraneStatus>();
}

/// Parses a `crane/live` payload.
///
/// [payload]: UTF-8 JSON text. Returns the sample, or null if malformed.
CraneLive? parseLive(String payload) {
  try {
    return CraneLive.fromJson(jsonDecode(payload) as Map<String, Object?>);
  } on Object catch (e) {
    _log.e('bad crane/live payload: $payload', e);
    return null;
  }
}

/// Parses a `crane/status` payload.
///
/// [payload]: UTF-8 JSON text; an empty payload (cleared retained message)
/// counts as offline. Returns the status, or null if malformed.
CraneStatus? parseStatus(String payload) {
  if (payload.trim().isEmpty) return const CraneStatus(online: false);
  try {
    return CraneStatus.fromJson(jsonDecode(payload) as Map<String, Object?>);
  } on Object catch (e) {
    _log.e('bad crane/status payload: $payload', e);
    return null;
  }
}
