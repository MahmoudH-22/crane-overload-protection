import 'package:crane_monitor/core/clock_providers.dart';
import 'package:crane_monitor/features/connection/presentation/connection_providers.dart';
import 'package:crane_monitor/features/control/data/command_repository.dart';
import 'package:crane_monitor/features/control/domain/crane_command.dart';
import 'package:crane_monitor/features/control/presentation/control_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_gateway.dart';

void main() {
  // testWidgets runs in a fake-async zone, so tester.pump(duration) drives the timers.
  group('MqttCommandRepository hold-to-run', () {
    testWidgets('sends LIFT now and every 250 ms, STOP on release', (tester) async {
      final gw = FakeGateway();
      final repo = MqttCommandRepository(gw);

      repo.startHold(CommandType.lift);
      expect(gw.motionCommands, ['LIFT']);
      expect(repo.activeHold, CommandType.lift);

      await tester.pump(const Duration(milliseconds: 1000));
      expect(gw.motionCommands, List.filled(5, 'LIFT'));

      repo.releaseHold();
      expect(gw.motionCommands.last, 'STOP');
      expect(repo.activeHold, isNull);

      await tester.pump(const Duration(seconds: 1));
      expect(gw.motionCommands.where((c) => c == 'LIFT'), hasLength(5), reason: 'repeat stopped');
      repo.dispose();
    });

    testWidgets('ids increment per message', (tester) async {
      final gw = FakeGateway();
      final repo = MqttCommandRepository(gw, ids: CommandIdGenerator(65534));
      repo.startHold(CommandType.lower);
      await tester.pump(const Duration(milliseconds: 250));
      repo.releaseHold();
      final ids = gw.published.map((p) => RegExp(r'"id":(\d+)').firstMatch(p.$2)!.group(1)).toList();
      expect(ids, ['65535', '0', '1']);
      repo.dispose();
    });

    testWidgets('switching direction stops the first one', (tester) async {
      final gw = FakeGateway();
      final repo = MqttCommandRepository(gw);
      repo.startHold(CommandType.lift);
      repo.startHold(CommandType.lower);
      expect(gw.motionCommands, ['LIFT', 'STOP', 'LOWER']);
      repo.dispose();
    });

    testWidgets('connection drop mid-hold stops the repeat (nothing can be sent)', (tester) async {
      final gw = FakeGateway();
      final repo = MqttCommandRepository(gw);
      repo.startHold(CommandType.lift);
      await tester.pump(const Duration(milliseconds: 300));
      gw.setConnected(false);
      expect(repo.activeHold, isNull);
      final sent = gw.motionCommands.length;

      gw.setConnected(true);
      await tester.pump(const Duration(seconds: 2));
      expect(gw.motionCommands.length, sent, reason: 'no LIFT resumes after reconnect');
      repo.dispose();
    });

    testWidgets('release while idle sends nothing unless asked', (tester) async {
      final gw = FakeGateway();
      final repo = MqttCommandRepository(gw);
      repo.releaseHold();
      expect(gw.motionCommands, isEmpty);
      repo.releaseHold(stopIfIdle: true);
      expect(gw.motionCommands, ['STOP']);
      repo.dispose();
    });

    testWidgets('heartbeat PING every second while connected', (tester) async {
      final gw = FakeGateway();
      final repo = MqttCommandRepository(gw);
      await tester.pump(const Duration(milliseconds: 3100));
      expect(gw.commands.where((c) => c == 'PING'), hasLength(3));
      gw.setConnected(false);
      await tester.pump(const Duration(seconds: 3));
      expect(gw.commands.where((c) => c == 'PING'), hasLength(3));
      repo.dispose();
    });

    testWidgets('not connected: startHold sends nothing and does not hold', (tester) async {
      final gw = FakeGateway(connected: false);
      final repo = MqttCommandRepository(gw);
      repo.startHold(CommandType.lift);
      expect(gw.published, isEmpty);
      expect(repo.activeHold, isNull);
      repo.dispose();
    });
  });

  group('ControlController', () {
    /// Runs [body] with a container on a fake gateway; disposes it inside the fake zone.
    Future<void> withController(
      WidgetTester tester,
      Future<void> Function(FakeGateway gw, ProviderContainer container) body,
    ) async {
      final gw = FakeGateway();
      final fixed = DateTime(2026, 11, 15, 12);
      final container = ProviderContainer(
        overrides: [mqttGatewayProvider.overrideWithValue(gw), clockProvider.overrideWithValue(() => fixed)],
      );
      container.listen(controlProvider, (_, _) {});
      await body(gw, container);
      container.dispose();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets(
      'app to background while holding sends STOP',
      (tester) => withController(tester, (gw, container) async {
        gw.push('crane/live', liveJson());
        await tester.pump();
        container.read(controlProvider.notifier).pressHold(CommandType.lift);
        await tester.pump(); // hold state arrives through a stream
        expect(container.read(controlProvider), CommandType.lift);

        container.read(controlProvider.notifier).onAppBackground();
        expect(gw.motionCommands, ['LIFT', 'STOP']);
        await tester.pump();
        expect(container.read(controlProvider), isNull);
      }),
    );

    testWidgets(
      'press is ignored when the control is disabled',
      (tester) => withController(tester, (gw, container) async {
        gw.push('crane/live', liveJson(st: 'OVERLOAD'));
        await tester.pump();
        container.read(controlProvider.notifier).pressHold(CommandType.lift);
        expect(gw.motionCommands, isEmpty);
        container.read(controlProvider.notifier).pressHold(CommandType.lower);
        expect(gw.motionCommands, ['LOWER']);
      }),
    );

    testWidgets(
      'hold dropped with STOP when the crane overloads mid-lift',
      (tester) => withController(tester, (gw, container) async {
        gw.push('crane/live', liveJson());
        await tester.pump();
        container.read(controlProvider.notifier).pressHold(CommandType.lift);
        gw.push('crane/live', liveJson(st: 'OVERLOAD', kg: 1.6));
        await tester.pump(const Duration(milliseconds: 10));
        expect(gw.motionCommands, ['LIFT', 'STOP']);
        expect(container.read(controlProvider), isNull);
      }),
    );

    testWidgets(
      'releasing the other button does not stop the active hold',
      (tester) => withController(tester, (gw, container) async {
        gw.push('crane/live', liveJson());
        await tester.pump();
        final c = container.read(controlProvider.notifier);
        c.pressHold(CommandType.lower);
        c.releaseHold(CommandType.lift);
        expect(gw.motionCommands, ['LOWER']);
        c.releaseHold(CommandType.lower);
        expect(gw.motionCommands, ['LOWER', 'STOP']);
      }),
    );
  });
}
