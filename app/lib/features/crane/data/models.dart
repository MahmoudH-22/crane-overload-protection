import 'dart:convert';

import '../domain/entities.dart';

/// JSON mapping for crane/live payloads.
abstract final class TelemetryModel {
  /// Parses a crane/live [payload]; returns null when it is malformed.
  static CraneTelemetry? parse(String payload) {
    try {
      final j = jsonDecode(payload) as Map<String, dynamic>;
      double d(String k) => (j[k] as num?)?.toDouble() ?? 0;
      return CraneTelemetry(
        kg: d('kg'),
        amps: d('amps'),
        atTop: j['top'] == true,
        state: craneStateFromWire(j['state'] as String? ?? ''),
        maxKg: d('max'),
        nearLimit: j['near'] == true,
        linkLost: j['linkLost'] == true,
        homed: j['homed'] == true,
        heightMm: (j['height'] as num?)?.toDouble(),
        encoderErrors: j['encErr'] == true,
        receivedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// JSON mapping for crane/cmd payloads.
abstract final class CommandModel {
  /// Converts [command] to JSON, e.g. {"cmd":"MAX","value":2.0}.
  static String encode(CraneCommand command) => jsonEncode({
        'cmd': command.type.name.toUpperCase(),
        if (command.value != null) 'value': command.value,
      });
}

/// Turns a crane/events payload into a short message for the UI.
abstract final class EventModel {
  /// Formats an event [payload]; falls back to the raw text.
  static String describe(String payload) {
    try {
      final j = jsonDecode(payload) as Map<String, dynamic>;
      final type = j['type'] as String? ?? 'EVENT';
      if (type == 'REJECTED') return 'Command rejected: ${j['reason']}';
      final kg = j['kg'];
      return kg == null ? type : '$type at $kg kg';
    } catch (_) {
      return payload;
    }
  }
}
