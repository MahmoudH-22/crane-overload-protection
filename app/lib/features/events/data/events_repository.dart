import 'dart:convert';

import '../../../app/constants.dart';
import '../../../core/logger.dart';
import '../../../core/time_utils.dart';
import '../../connection/domain/mqtt_gateway.dart';
import '../domain/crane_event.dart';

const _log = Log('events');

/// Source of crane events.
abstract interface class EventsRepository {
  /// Parsed `crane/events` messages, stamped with their arrival time.
  Stream<CraneEvent> get events;
}

/// [EventsRepository] reading from an [MqttGateway].
class MqttEventsRepository implements EventsRepository {
  /// Creates the repository on top of [_gateway]; [_now] stamps arrivals.
  MqttEventsRepository(this._gateway, [this._now = systemNow]);

  final MqttGateway _gateway;
  final Now _now;

  @override
  Stream<CraneEvent> get events => _gateway.messages
      .where((m) => m.topic == Topics.events)
      .map((m) => parseEvent(m.payload)?.copyWith(receivedAt: _now()))
      .where((e) => e != null)
      .cast<CraneEvent>();
}

/// Parses a `crane/events` payload.
///
/// [payload]: UTF-8 JSON. Returns the event, or null if malformed.
CraneEvent? parseEvent(String payload) {
  try {
    return CraneEvent.fromJson(jsonDecode(payload) as Map<String, Object?>);
  } on Object catch (e) {
    _log.e('bad crane/events payload: $payload', e);
    return null;
  }
}
