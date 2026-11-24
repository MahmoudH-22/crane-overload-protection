import 'dart:convert';

import 'package:crane_monitor/app/theme.dart';
import 'package:crane_monitor/core/clock_providers.dart';
import 'package:crane_monitor/features/connection/presentation/connection_providers.dart';
import 'package:crane_monitor/features/control/domain/control_availability.dart';
import 'package:crane_monitor/features/control/domain/crane_command.dart';
import 'package:crane_monitor/features/control/presentation/control_providers.dart';
import 'package:crane_monitor/features/events/data/events_repository.dart';
import 'package:crane_monitor/features/events/domain/crane_event.dart';
import 'package:crane_monitor/features/telemetry/data/telemetry_repository.dart';
import 'package:crane_monitor/features/telemetry/domain/crane_alert.dart';
import 'package:crane_monitor/features/telemetry/domain/crane_live.dart';
import 'package:crane_monitor/features/telemetry/domain/crane_state.dart';
import 'package:crane_monitor/features/telemetry/domain/link_health.dart';
import 'package:crane_monitor/features/telemetry/presentation/alert_banner.dart';
import 'package:crane_monitor/features/telemetry/presentation/dashboard_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_gateway.dart';

/// A REMOTE sample at [h] mm with the obstacle flag [obs].
CraneLive sample({double h = 200, bool obs = true, CraneState state = CraneState.idle, bool top = false}) =>
    CraneLive(kg: 0.5, maxKg: 1.5, heightMm: h, state: state, mode: CraneMode.remote, top: top, obstacle: obs);

/// Availability with a healthy link for [live] and optional GO [target].
ControlAvailability eval(CraneLive live, {double? target}) =>
    evaluateControls(connected: true, health: LinkHealth.ok, live: live, targetMm: target);

void main() {
  group('parsing', () {
    test('us and obs fields', () {
      final live = parseLive(jsonEncode({...liveJson(), 'us': 120.5, 'obs': true}))!;
      expect(live.ultrasonicMm, 120.5);
      expect(live.obstacle, isTrue);
    });

    test('missing / null fields default to no obstacle', () {
      final live = parseLive(jsonEncode({...liveJson(), 'us': null}))!;
      expect(live.ultrasonicMm, isNull);
      expect(live.obstacle, isFalse);
      expect(parseLive(jsonEncode(liveJson()))!.obstacle, isFalse);
    });

    test('OBSTACLE events', () {
      expect(parseEvent('{"t":1,"type":"OBSTACLE","kg":0.5}')!.type, CraneEventType.obstacle);
      expect(parseEvent('{"t":1,"type":"OBSTACLE_CLEARED"}')!.type, CraneEventType.obstacleCleared);
      expect(CraneEventType.obstacleCleared.label, 'OBSTACLE_CLEARED');
      expect(CraneEventType.obstacle.isAlarm, isTrue);
    });
  });

  group('availability', () {
    test('obstacle blocks LOWER only; LIFT stays', () {
      final a = eval(sample());
      expect(a.lower, const Availability.disabled(DisabledReason.obstacle));
      expect(a.lift.enabled, isTrue);
      expect(a.stop.enabled, isTrue);
    });

    test('at the top with an obstacle: no LIFT (top) and no LOWER (obstacle)', () {
      final a = eval(sample(h: 346, state: CraneState.top, top: true));
      expect(a.lift, const Availability.disabled(DisabledReason.top));
      expect(a.lower, const Availability.disabled(DisabledReason.obstacle));
    });

    test('GO: downward blocked, upward allowed', () {
      expect(eval(sample(h: 200), target: 50).goTo, const Availability.disabled(DisabledReason.obstacle));
      expect(eval(sample(h: 200), target: 300).goTo.enabled, isTrue);
    });

    test('no obstacle: LOWER enabled again', () {
      expect(eval(sample(obs: false)).lower.enabled, isTrue);
    });
  });

  group('alert', () {
    test('obstacle raises the banner', () {
      expect(evaluateAlert(health: LinkHealth.ok, state: CraneState.idle, obstacle: true), CraneAlert.obstacle);
    });

    test('latched faults and offline still win', () {
      expect(evaluateAlert(health: LinkHealth.ok, state: CraneState.overload, obstacle: true), CraneAlert.overload);
      expect(evaluateAlert(health: LinkHealth.offline, state: CraneState.idle, obstacle: true), CraneAlert.offline);
    });
  });

  group('controller', () {
    /// Runs [body] with a container on a fake gateway; disposes it inside the fake zone.
    Future<void> withController(
      WidgetTester tester,
      Future<void> Function(FakeGateway gw, ProviderContainer container) body,
    ) async {
      final gw = FakeGateway();
      final fixed = DateTime(2026, 11, 16, 12);
      final container = ProviderContainer(
        overrides: [mqttGatewayProvider.overrideWithValue(gw), clockProvider.overrideWithValue(() => fixed)],
      );
      container.listen(controlProvider, (_, _) {});
      await body(gw, container);
      container.dispose();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets(
      'object appears while holding LOWER: hold dropped with STOP',
      (tester) => withController(tester, (gw, container) async {
        gw.push('crane/live', liveJson(h: 200));
        await tester.pump();
        container.read(controlProvider.notifier).pressHold(CommandType.lower);
        gw.push('crane/live', {...liveJson(h: 190, st: 'LOWERING', src: 'APP'), 'us': 100.0, 'obs': true});
        await tester.pump(const Duration(milliseconds: 10));
        expect(gw.motionCommands, ['LOWER', 'STOP']);
        expect(container.read(controlProvider), isNull);
      }),
    );

    testWidgets(
      'object below does not stop a LIFT',
      (tester) => withController(tester, (gw, container) async {
        gw.push('crane/live', liveJson(h: 200));
        await tester.pump();
        container.read(controlProvider.notifier).pressHold(CommandType.lift);
        gw.push('crane/live', {...liveJson(h: 210, st: 'LIFTING', src: 'APP'), 'us': 100.0, 'obs': true});
        await tester.pump(const Duration(milliseconds: 300));
        expect(gw.motionCommands, ['LIFT', 'LIFT']);
        container.read(controlProvider.notifier).releaseHold(CommandType.lift);
      }),
    );
  });

  group('widgets', () {
    /// Pumps the banner and clearance card on [gw].
    Future<void> pump(WidgetTester tester, FakeGateway gw) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          mqttGatewayProvider.overrideWithValue(gw),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 16, 12)),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const Scaffold(body: Column(children: [AlertBanner(), ClearanceCard()])),
        ),
      ),
    );

    testWidgets('object below: banner and OBJECT BELOW with distance', (tester) async {
      final gw = FakeGateway();
      await pump(tester, gw);
      gw.push('crane/live', {...liveJson(h: 200), 'us': 120.0, 'obs': true});
      await tester.pump();
      expect(find.textContaining('OBJECT UNDER THE LOAD'), findsOneWidget);
      expect(find.text('OBJECT BELOW'), findsOneWidget);
      expect(find.text('120 mm'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('clear: CLEAR, no banner; null distance shows < 20 mm', (tester) async {
      final gw = FakeGateway();
      await pump(tester, gw);
      gw.push('crane/live', {...liveJson(h: 10), 'us': null, 'obs': false});
      await tester.pump();
      expect(find.text('CLEAR'), findsOneWidget);
      expect(find.text('< 20 mm'), findsOneWidget);
      expect(find.textContaining('OBJECT UNDER THE LOAD'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
