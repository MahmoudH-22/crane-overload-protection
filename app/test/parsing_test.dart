import 'dart:convert';

import 'package:crane_monitor/features/control/data/command_repository.dart';
import 'package:crane_monitor/features/control/domain/crane_command.dart';
import 'package:crane_monitor/features/events/data/events_repository.dart';
import 'package:crane_monitor/features/events/domain/crane_event.dart';
import 'package:crane_monitor/features/telemetry/data/telemetry_repository.dart';
import 'package:crane_monitor/features/telemetry/domain/crane_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_gateway.dart';

void main() {
  group('crane/live', () {
    test('parses the contract example', () {
      final live = parseLive(
        '{"t":123456,"kg":1.234,"max":1.5,"h":212.5,"a":0.42,"top":false,'
        '"st":"LIFTING","mode":"REMOTE","src":"APP"}',
      )!;
      expect(live.millis, 123456);
      expect(live.kg, 1.234);
      expect(live.maxKg, 1.5);
      expect(live.heightMm, 212.5);
      expect(live.amps, 0.42);
      expect(live.top, isFalse);
      expect(live.state, CraneState.lifting);
      expect(live.mode, CraneMode.remote);
      expect(live.source, MotionSource.app);
    });

    test('accepts integers for doubles', () {
      final live = parseLive('{"kg":1,"max":2,"st":"IDLE"}')!;
      expect(live.kg, 1.0);
      expect(live.maxKg, 2.0);
    });

    test('maps every state', () {
      for (final (wire, state) in [
        ('IDLE', CraneState.idle),
        ('LOWERING', CraneState.lowering),
        ('OVERLOAD', CraneState.overload),
        ('JAM', CraneState.jam),
        ('TOP', CraneState.top),
        ('ESTOP', CraneState.estop),
      ]) {
        expect(parseLive(jsonEncode(liveJson(st: wire)))!.state, state, reason: wire);
      }
    });

    test('unknown enum values become unknown', () {
      final live = parseLive(jsonEncode(liveJson(st: 'DANCING', mode: 'AUTO', src: 'CLOUD')))!;
      expect(live.state, CraneState.unknown);
      expect(live.mode, CraneMode.unknown);
      expect(live.source, MotionSource.unknown);
    });

    test('malformed payloads return null', () {
      expect(parseLive('not json'), isNull);
      expect(parseLive('{"kg":"heavy","max":1.5,"st":"IDLE"}'), isNull);
      expect(parseLive('{"max":1.5,"st":"IDLE"}'), isNull);
      expect(parseLive('[]'), isNull);
    });
  });

  group('crane/status', () {
    test('online and Last Will', () {
      final on = parseStatus('{"online":true,"fw":"m2.0"}')!;
      expect(on.online, isTrue);
      expect(on.firmware, 'm2.0');
      expect(parseStatus('{"online":false}')!.online, isFalse);
    });

    test('empty retained payload counts as offline', () {
      expect(parseStatus('')!.online, isFalse);
    });

    test('malformed returns null', () => expect(parseStatus('{oops'), isNull));
  });

  group('crane/ack', () {
    test('refusal with reason', () {
      final ack = parseAck('{"id":17,"ok":false,"reason":"OVERLOAD"}')!;
      expect(ack.id, 17);
      expect(ack.ok, isFalse);
      expect(ack.reason, 'OVERLOAD');
      expect(ack.reasonText, contains('overload'));
    });

    test('success without reason', () {
      final ack = parseAck('{"id":20,"ok":true}')!;
      expect(ack.ok, isTrue);
      expect(ack.reason, isNull);
    });

    test('malformed returns null', () => expect(parseAck('{"ok":true}'), isNull));
  });

  group('crane/events', () {
    test('parses known and snake-case types', () {
      expect(parseEvent('{"t":123999,"type":"OVERLOAD","kg":1.53}')!.type, CraneEventType.overload);
      expect(parseEvent('{"t":1,"type":"OVERLOAD_CLEARED","kg":1.0}')!.type, CraneEventType.overloadCleared);
      expect(parseEvent('{"t":1,"type":"MAX_CHANGED","kg":1.2}')!.kg, 1.2);
      expect(parseEvent('{"t":1,"type":"LINK_LOST"}')!.type, CraneEventType.linkLost);
    });

    test('labels round-trip to wire names', () {
      expect(CraneEventType.estopReleased.label, 'ESTOP_RELEASED');
      expect(CraneEventType.top.label, 'TOP');
    });

    test('unknown type is kept as unknown', () {
      expect(parseEvent('{"t":1,"type":"COFFEE"}')!.type, CraneEventType.unknown);
    });
  });

  group('crane/cmd', () {
    test('payloads match the contract', () {
      expect(jsonDecode(const CraneCommand(id: 17, type: CommandType.lift).toPayload()), {'id': 17, 'cmd': 'LIFT'});
      expect(jsonDecode(const CraneCommand(id: 22, type: CommandType.setMax, value: 1.2).toPayload()), {
        'id': 22,
        'cmd': 'SET_MAX',
        'value': 1.2,
      });
    });

    test('ids increment and wrap at 65535', () {
      final ids = CommandIdGenerator(65534);
      expect(ids.next(), 65535);
      expect(ids.next(), 0);
      expect(ids.next(), 1);
    });
  });
}
