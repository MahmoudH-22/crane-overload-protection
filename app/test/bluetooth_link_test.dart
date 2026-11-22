import 'dart:async';
import 'dart:convert';

import 'package:crane_monitor/core/result.dart';
import 'package:crane_monitor/features/connection/data/bluetooth_gateway.dart';
import 'package:crane_monitor/features/connection/data/crane_link_codec.dart';
import 'package:crane_monitor/features/connection/domain/bluetooth_port.dart';
import 'package:crane_monitor/features/connection/domain/broker_settings.dart';
import 'package:crane_monitor/features/connection/domain/connection_state.dart';
import 'package:crane_monitor/features/connection/domain/mqtt_gateway.dart';
import 'package:crane_monitor/features/telemetry/data/telemetry_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [BluetoothLink]: tests push Uno bytes in and read what the app wrote.
class FakeLink implements BluetoothLink {
  final _input = StreamController<List<int>>();

  /// Everything the app wrote, decoded.
  final written = StringBuffer();

  /// Whether [close] was called.
  bool closed = false;

  @override
  Stream<List<int>> get input => _input.stream;

  @override
  void write(List<int> bytes) {
    if (closed) throw StateError('closed');
    written.write(ascii.decode(bytes));
  }

  @override
  Future<void> close() async => closed = true;

  /// Sends a framed Uno line [body].
  void uno(String body) => _input.add(ascii.encode(CraneLinkCodec.frame(body)));

  /// Simulates the HC-05 dropping the link.
  Future<void> drop() => _input.close();
}

/// [BluetoothPort] handing out [FakeLink]s.
class FakePort implements BluetoothPort {
  /// Links opened so far.
  final links = <FakeLink>[];

  /// When set, `open` fails with this message.
  String? failWith;

  @override
  Future<Result<List<PairedDevice>>> pairedDevices() async =>
      const Ok([PairedDevice(name: 'HC-05', address: '98:D3:31:F5:12:34')]);

  @override
  Future<Result<BluetoothLink>> open(String address) async {
    if (failWith != null) return Err(failWith!);
    final link = FakeLink();
    links.add(link);
    return Ok(link);
  }
}

final _settings = BrokerSettings(btAddress: '98:D3:31:F5:12:34', btName: 'HC-05', host: 'x', clientId: 'c');

void main() {
  group('CraneLinkCodec (same cases as firmware/test/link_test.cpp)', () {
    test('frame / unframe', () {
      expect(CraneLinkCodec.frame('H'), 'H*48\n');
      expect(CraneLinkCodec.unframe('H*48'), 'H');
      expect(CraneLinkCodec.unframe('H*48\r'), 'H');
      expect(CraneLinkCodec.unframe('H*49'), isNull);
      expect(CraneLinkCodec.unframe('H48'), isNull);
      expect(CraneLinkCodec.unframe('H*ZZ'), isNull);
      expect(CraneLinkCodec.unframe('*4'), isNull);
      final framed = CraneLinkCodec.frame('C,17,LIFT');
      expect(CraneLinkCodec.unframe(framed.trimRight()), 'C,17,LIFT');
    });

    test('isNumber / isWord', () {
      for (final s in ['1.234', '-0.5', '346', '+2']) {
        expect(CraneLinkCodec.isNumber(s), isTrue, reason: s);
      }
      for (final s in ['', '-', 'nan', '1e5', '1.2.3', '.']) {
        expect(CraneLinkCodec.isNumber(s), isFalse, reason: s);
      }
      expect(['IDLE', 'LOCAL_MODE', 'A1'].every(CraneLinkCodec.isWord), isTrue);
      expect(['', 'idle', 'A"B', 'A B'].any(CraneLinkCodec.isWord), isFalse);
    });

    test('L line (two-sensor crane) -> crane/live with nulls', () {
      final msg = CraneLinkCodec.toMessage('L,123456,1.234,1.500,,,1,TOP,REMOTE,NONE,,0')!;
      expect(msg.topic, 'crane/live');
      expect(jsonDecode(msg.payload), {
        't': 123456,
        'kg': 1.234,
        'max': 1.5,
        'h': null,
        'a': null,
        'top': true,
        'st': 'TOP',
        'mode': 'REMOTE',
        'src': 'NONE',
        'us': null,
        'obs': false,
      });
      final live = parseLive(msg.payload)!;
      expect(live.kg, 1.234);
      expect(live.heightMm, isNull);
    });

    test('invalid L lines are dropped', () {
      expect(CraneLinkCodec.toMessage('L,1,abc,1.5,,,0,IDLE,REMOTE,NONE,,0'), isNull); // weight not a number
      expect(CraneLinkCodec.toMessage('L,1,1.0,1.5'), isNull); // too few fields
      expect(CraneLinkCodec.toMessage('L,1,1.0,1.5,,,0,ID"LE,REMOTE,NONE,,0'), isNull); // unsafe state
    });

    test('A and E lines', () {
      expect(jsonDecode(CraneLinkCodec.toMessage('A,17,0,OVERLOAD')!.payload), {
        'id': 17,
        'ok': false,
        'reason': 'OVERLOAD',
      });
      expect(jsonDecode(CraneLinkCodec.toMessage('A,20,1,')!.payload), {'id': 20, 'ok': true});
      final e = CraneLinkCodec.toMessage('E,123999,OVERLOAD,1.530')!;
      expect(e.topic, 'crane/events');
      expect(jsonDecode(e.payload), {'t': 123999, 'type': 'OVERLOAD', 'kg': 1.53});
      expect(jsonDecode(CraneLinkCodec.toMessage('E,5,TOP,')!.payload)['kg'], isNull);
    });

    test('S line -> safe sensor names; status JSON', () {
      expect(CraneLinkCodec.sensors(['S', 'kg top']), ['kg', 'top']);
      expect(CraneLinkCodec.sensors(['S', 'kg  "x" TOP']), ['kg', 'x']);
      expect(jsonDecode(CraneLinkCodec.statusJson(online: true, fw: 'f', sensors: ['kg'])), {
        'online': true,
        'fw': 'f',
        'sensors': ['kg'],
      });
      expect(jsonDecode(CraneLinkCodec.statusJson(online: false, fw: 'f')), {'online': false, 'fw': 'f'});
    });

    test('commands -> C lines; unknown or bad ones are not sent', () {
      expect(CraneLinkCodec.commandLine('{"id":17,"cmd":"LIFT"}'), CraneLinkCodec.frame('C,17,LIFT'));
      expect(CraneLinkCodec.commandLine('{"id":3,"cmd":"GOTO","value":200}'), CraneLinkCodec.frame('C,3,GOTO,200.000'));
      expect(
        CraneLinkCodec.commandLine('{"id":4,"cmd":"SET_MAX","value":1.2}'),
        CraneLinkCodec.frame('C,4,SET_MAX,1.200'),
      );
      expect(CraneLinkCodec.commandLine('{"id":1,"cmd":"FLY"}'), isNull);
      expect(CraneLinkCodec.commandLine('{"id":70000,"cmd":"STOP"}'), isNull);
      expect(CraneLinkCodec.commandLine('{"cmd":"STOP"}'), isNull);
      expect(CraneLinkCodec.commandLine('not json'), isNull);
    });

    test('ByteLineSplitter joins chunks and drops over-long lines', () {
      final s = ByteLineSplitter(maxLine: 8);
      expect(s.add(ascii.encode('AB')), isEmpty);
      expect(s.add(ascii.encode('C\nDE\n')), ['ABC', 'DE']);
      expect(s.add(ascii.encode('0123456789xyz\nOK\n')), ['OK']);
    });
  });

  group('BluetoothGateway', () {
    late FakePort port;
    late DateTime now;
    late BluetoothGateway gw;
    late List<InboundMessage> received;

    /// Creates the fake port, clock and gateway inside the test's fake-time zone.
    void start() {
      port = FakePort();
      now = DateTime(2026, 11, 21, 10);
      gw = BluetoothGateway(port, clock: () => now);
      received = [];
      gw.messages.listen(received.add);
    }

    testWidgets('connects, turns Uno lines into topic messages and status', (tester) async {
      start();
      expect((await gw.connect(_settings)).isOk, isTrue);
      expect(gw.current.status, BrokerStatus.connected);
      final link = port.links.single;

      link.uno('S,kg top');
      link.uno('L,1000,0.250,1.500,,,0,IDLE,REMOTE,NONE,,0');
      link.uno('E,1001,TARE,');
      await tester.pump();

      expect(received.map((m) => m.topic), ['crane/status', 'crane/live', 'crane/events']);
      final status = parseStatus(received.first.payload)!;
      expect(status.online, isTrue);
      expect(status.sensors, ['kg', 'top']);
      gw.dispose();
    });

    testWidgets('bad checksum lines are ignored', (tester) async {
      start();
      await gw.connect(_settings);
      port.links.single._input.add(ascii.encode('L,1,0.1,1.5,,,0,IDLE,REMOTE,NONE,,0*00\n'));
      await tester.pump();
      expect(received, isEmpty);
      gw.dispose();
    });

    testWidgets('Uno silent for 2 s -> status offline, back online on the next line', (tester) async {
      start();
      await gw.connect(_settings);
      final link = port.links.single..uno('L,1,0.1,1.5,,,0,IDLE,REMOTE,NONE,,0');
      await tester.pump();
      received.clear();

      now = now.add(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 600));
      expect(received.single.topic, 'crane/status');
      expect(parseStatus(received.single.payload)!.online, isFalse);

      link.uno('L,2,0.1,1.5,,,0,IDLE,REMOTE,NONE,,0');
      await tester.pump();
      expect(parseStatus(received[1].payload)!.online, isTrue);
      expect(received[2].topic, 'crane/live');
      gw.dispose();
    });

    testWidgets('publishes commands as C lines', (tester) async {
      start();
      await gw.connect(_settings);
      expect(gw.publish('crane/cmd', '{"id":5,"cmd":"STOP"}'), isTrue);
      expect(gw.publish('crane/cmd', '{"id":6,"cmd":"BAD"}'), isFalse);
      expect(gw.publish('crane/other', '{"id":7,"cmd":"STOP"}'), isFalse);
      expect(port.links.single.written.toString(), CraneLinkCodec.frame('C,5,STOP'));
      gw.dispose();
    });

    testWidgets('nothing is sent when not connected', (tester) async {
      start();
      expect(gw.publish('crane/cmd', '{"id":5,"cmd":"STOP"}'), isFalse);
      gw.dispose();
    });

    testWidgets('open failure is reported, no retry', (tester) async {
      start();
      port.failWith = 'Bluetooth is off. Turn it on and try again.';
      final result = await gw.connect(_settings);
      expect(result, isA<Err<void>>());
      expect(gw.current.status, BrokerStatus.failed);
      expect(gw.current.error, contains('Bluetooth is off'));
      await tester.pump(const Duration(seconds: 5));
      expect(port.links, isEmpty);
      gw.dispose();
    });

    testWidgets('no device picked -> error', (tester) async {
      start();
      final result = await gw.connect(BrokerSettings(host: 'x', clientId: 'c'));
      expect(result, isA<Err<void>>());
      gw.dispose();
    });

    testWidgets('link drop -> reconnects with back-off', (tester) async {
      start();
      await gw.connect(_settings);
      await port.links.single.drop();
      await tester.pump();
      expect(gw.current.status, BrokerStatus.reconnecting);
      expect(gw.current.attempt, 1);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(port.links, hasLength(2));
      expect(gw.current.status, BrokerStatus.connected);
      gw.dispose();
    });

    testWidgets('disconnect closes the link and does not reconnect', (tester) async {
      start();
      await gw.connect(_settings);
      await gw.disconnect();
      expect(port.links.single.closed, isTrue);
      expect(gw.current.status, BrokerStatus.disconnected);
      await tester.pump(const Duration(seconds: 5));
      expect(port.links, hasLength(1));
      gw.dispose();
    });
  });
}
