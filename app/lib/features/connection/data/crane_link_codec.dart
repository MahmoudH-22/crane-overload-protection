import 'dart:convert';

import '../../../app/constants.dart';
import '../domain/mqtt_gateway.dart';

/// Dart port of `firmware/*/crane_link.h`: the Uno's checksummed serial lines, carried over the HC-05.
///
/// The app does here what the NodeMCU bridge used to do: it turns Uno lines into the same topic + JSON
/// messages the MQTT contract defines, and app commands into `C` lines. Keep the two in step.
///
/// Every line is `<body>*XX\n`, XX = XOR of the body bytes in hex. Fields are comma separated and an
/// empty field means "no value" (JSON null).
/// - Uno → app: `L,t,kg,max,h,a,top,st,mode,src,us,obs` (crane/live), `A,id,ok,reason` (crane/ack),
///   `E,t,type,kg` (crane/events), `S,<sensors>` (fitted sensors, space separated).
/// - App → Uno: `C,id,CMD[,value]`.
abstract final class CraneLinkCodec {
  /// Commands the Uno understands; anything else is never sent.
  static const knownCommands = {'LIFT', 'LOWER', 'GOTO', 'STOP', 'RESET', 'TARE', 'SET_MAX', 'PING'};

  static final _number = RegExp(r'^[+-]?(\d+\.?\d*|\.\d+)$');
  static final _word = RegExp(r'^[A-Z0-9_]+$');
  static final _sensor = RegExp(r'[^a-z0-9]');

  /// XOR checksum of [body]'s character codes.
  ///
  /// Returns the 8-bit checksum.
  static int xorSum(String body) => body.codeUnits.fold(0, (c, u) => c ^ (u & 0xFF));

  /// Builds `<body>*XX\n` for [body].
  static String frame(String body) => '$body*${xorSum(body).toRadixString(16).toUpperCase().padLeft(2, '0')}\n';

  /// Verifies and strips the `*XX` checksum (and a trailing CR) from [line] (without the `\n`).
  ///
  /// Returns the body, or null when the checksum is missing or wrong.
  static String? unframe(String line) {
    final l = line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
    if (l.length < 4 || l[l.length - 3] != '*') return null;
    final want = int.tryParse(l.substring(l.length - 2), radix: 16);
    final body = l.substring(0, l.length - 3);
    return (want != null && xorSum(body) == want) ? body : null;
  }

  /// Whether [s] is a plain decimal number ("1.234", "-0.5", "346"; not "", "nan", "1e5").
  static bool isNumber(String s) => _number.hasMatch(s);

  /// Whether [s] is a safe upper-case word ("IDLE", "LOCAL_MODE").
  static bool isWord(String s) => _word.hasMatch(s);

  /// Parses a numeric field; returns an int when it has no fraction, null when empty or invalid.
  static num? _num(String s) =>
      !isNumber(s) ? null : (s.contains('.') ? double.parse(s.endsWith('.') ? '${s}0' : s) : int.parse(s));

  /// Returns [s] if it is a safe word, otherwise null.
  static String? _wordOrNull(String s) => isWord(s) ? s : null;

  /// Converts the fields of an `L` line ([f], 12 fields) to the crane/live JSON map, or null if invalid.
  static Map<String, Object?>? liveMap(List<String> f) {
    if (f.length != 12 || f[0] != 'L' || !isNumber(f[2]) || !isWord(f[7])) return null;
    return {
      't': _num(f[1]),
      'kg': _num(f[2]),
      'max': _num(f[3]),
      'h': _num(f[4]),
      'a': _num(f[5]),
      'top': f[6] == '1',
      'st': f[7],
      'mode': _wordOrNull(f[8]),
      'src': _wordOrNull(f[9]),
      'us': _num(f[10]),
      'obs': f[11] == '1',
    };
  }

  /// Converts the fields of an `A` line ([f]: A, id, ok 1/0, reason) to the crane/ack JSON map, or null.
  static Map<String, Object?>? ackMap(List<String> f) {
    if (f.length != 4 || f[0] != 'A' || !isNumber(f[1])) return null;
    return {'id': _num(f[1]), 'ok': f[2] == '1', if (isWord(f[3])) 'reason': f[3]};
  }

  /// Converts the fields of an `E` line ([f]: E, t, type, kg) to the crane/events JSON map, or null.
  static Map<String, Object?>? eventMap(List<String> f) {
    if (f.length != 4 || f[0] != 'E' || !isWord(f[2])) return null;
    return {'t': _num(f[1]), 'type': f[2], 'kg': _num(f[3])};
  }

  /// Parses the sensor list of an `S` line ([f]: S, "kg top h") into safe lower-case names, or null.
  static List<String>? sensors(List<String> f) {
    if (f.length != 2 || f[0] != 'S') return null;
    return [
      for (final name in f[1].split(' '))
        if (name.replaceAll(_sensor, '').isNotEmpty) name.replaceAll(_sensor, ''),
    ];
  }

  /// Builds the crane/status JSON: [online], [fw] tag and the fitted [sensors] (null = unknown, key omitted).
  static String statusJson({required bool online, required String fw, List<String>? sensors}) =>
      jsonEncode({'online': online, 'fw': fw, 'sensors': ?sensors});

  /// Translates one checksum-verified line [body] (L / A / E) to a topic message.
  ///
  /// Returns null for S lines (handled by the caller) and anything unknown or invalid.
  static InboundMessage? toMessage(String body) {
    final f = body.split(',');
    final (topic, map) = switch (f[0]) {
      'L' => (Topics.live, liveMap(f)),
      'A' => (Topics.ack, ackMap(f)),
      'E' => (Topics.events, eventMap(f)),
      _ => (null, null),
    };
    return (topic == null || map == null) ? null : InboundMessage(topic, jsonEncode(map));
  }

  /// Translates a crane/cmd JSON [payload] (`{"id":17,"cmd":"GOTO","value":200}`) to a framed `C` line.
  ///
  /// Returns null for invalid JSON, an unknown command or an id outside 0…65535 (nothing is sent).
  static String? commandLine(String payload) {
    final Object? json;
    try {
      json = jsonDecode(payload);
    } on FormatException {
      return null;
    }
    if (json is! Map) return null;
    final id = json['id'];
    final cmd = json['cmd'];
    final value = json['value'];
    if (id is! int || id < 0 || id > 65535 || cmd is! String || !knownCommands.contains(cmd)) return null;
    final body = value is num ? 'C,$id,$cmd,${value.toStringAsFixed(3)}' : 'C,$id,$cmd';
    return frame(body);
  }
}

/// Splits a byte stream into lines, dropping anything longer than [maxLine] (noise or a lost newline).
class ByteLineSplitter {
  /// Creates a splitter that keeps at most [maxLine] characters per line.
  ByteLineSplitter({this.maxLine = 128});

  /// Longest line kept; a longer one is discarded up to its newline.
  final int maxLine;

  final _buf = StringBuffer();
  bool _overflow = false;

  /// Feeds [bytes] (ASCII) and returns the complete lines they finish, without the `\n`.
  List<String> add(List<int> bytes) {
    final lines = <String>[];
    for (final b in bytes) {
      if (b == 0x0A) {
        if (!_overflow) lines.add(_buf.toString());
        _buf.clear();
        _overflow = false;
      } else if (_buf.length >= maxLine) {
        _overflow = true;
        _buf.clear();
      } else if (!_overflow) {
        _buf.writeCharCode(b & 0x7F);
      }
    }
    return lines;
  }

  /// Forgets any partial line (after a reconnect).
  void reset() {
    _buf.clear();
    _overflow = false;
  }
}
