/// End-to-end check against a real broker and `tools/crane_sim.py`.
///
/// Skipped unless CRANE_SIM is set. Run with:
///   mosquitto -c tools/mosquitto.conf          (repo root)
///   python tools/crane_sim.py
///   CRANE_SIM=1 flutter test test/live          (in app/)
@Tags(['live'])
library;

import 'dart:io';

import 'package:crane_monitor/features/connection/data/mqtt_service.dart';
import 'package:crane_monitor/features/connection/domain/broker_settings.dart';
import 'package:crane_monitor/features/control/data/command_repository.dart';
import 'package:crane_monitor/features/control/domain/crane_command.dart';
import 'package:crane_monitor/features/telemetry/data/telemetry_repository.dart';
import 'package:crane_monitor/features/telemetry/domain/crane_live.dart';
import 'package:crane_monitor/features/telemetry/domain/crane_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final enabled = Platform.environment['CRANE_SIM'] != null;
  final host = Platform.environment['CRANE_HOST'] ?? '127.0.0.1';

  test(
    'connect, read live, hold LIFT moves the hook, release stops it',
    () async {
      final mqtt = MqttService();
      final telemetry = MqttTelemetryRepository(mqtt);
      final commands = MqttCommandRepository(mqtt);
      CraneLive? last;
      final sub = telemetry.live.listen((l) => last = l);

      final result = await mqtt.connect(BrokerSettings(host: host, clientId: 'crane-app-test'));
      expect(result.isOk, isTrue);
      await Future<void>.delayed(const Duration(seconds: 1));
      expect(last, isNotNull, reason: 'crane/live received');
      expect(last!.mode, CraneMode.remote);
      final h0 = last!.heightMm!;

      commands.startHold(CommandType.lift);
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(last!.state, anyOf(CraneState.lifting, CraneState.top));
      expect(last!.source, MotionSource.app);
      commands.releaseHold();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(last!.state, anyOf(CraneState.idle, CraneState.top));
      expect(last!.heightMm, greaterThan(h0 + 40));

      commands.startHold(CommandType.lower);
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      commands.releaseHold();

      await sub.cancel();
      commands.dispose();
      await mqtt.disconnect();
      mqtt.dispose();
    },
    skip: !enabled,
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'holding GOTO stops at the target by itself',
    () async {
      final mqtt = MqttService();
      final telemetry = MqttTelemetryRepository(mqtt);
      final commands = MqttCommandRepository(mqtt);
      CraneLive? last;
      final sub = telemetry.live.listen((l) => last = l);
      expect((await mqtt.connect(BrokerSettings(host: host, clientId: 'crane-app-test'))).isOk, isTrue);
      await Future<void>.delayed(const Duration(seconds: 1));

      for (final target in [180.0, 60.0]) {
        commands.startHold(CommandType.goTo, value: target);
        // Keep holding well past arrival: the crane must stop on its own and stay there.
        await Future<void>.delayed(const Duration(seconds: 6));
        expect(last!.heightMm, closeTo(target, 3), reason: 'reached $target');
        expect(last!.state, CraneState.idle);
        final settled = last!.heightMm;
        await Future<void>.delayed(const Duration(milliseconds: 600));
        expect(last!.heightMm, settled, reason: 'no drift while still holding');
        commands.releaseHold();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }

      await sub.cancel();
      commands.dispose();
      await mqtt.disconnect();
      mqtt.dispose();
    },
    skip: !enabled,
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test('wrong port gives a "refused" error', () async {
    final mqtt = MqttService();
    final result = await mqtt.connect(BrokerSettings(host: host, port: 1, clientId: 'crane-app-test'));
    expect(result.isOk, isFalse);
    expect(mqtt.current.error, contains('refused'));
    mqtt.dispose();
  }, skip: !enabled);
}
