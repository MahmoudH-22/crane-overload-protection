import 'dart:convert';

import 'package:crane_monitor/core/clock_providers.dart';
import 'package:crane_monitor/features/connection/presentation/connection_providers.dart';
import 'package:crane_monitor/features/control/data/command_repository.dart';
import 'package:crane_monitor/features/control/domain/control_availability.dart';
import 'package:crane_monitor/features/control/domain/crane_command.dart';
import 'package:crane_monitor/features/control/presentation/control_providers.dart';
import 'package:crane_monitor/features/control/presentation/go_to_height_card.dart';
import 'package:crane_monitor/features/telemetry/domain/crane_live.dart';
import 'package:crane_monitor/features/telemetry/domain/crane_state.dart';
import 'package:crane_monitor/features/telemetry/domain/link_health.dart';
import 'package:crane_monitor/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_gateway.dart';

/// A REMOTE sample at [h] mm in [state].
CraneLive at(double h, {CraneState state = CraneState.idle, bool top = false}) =>
    CraneLive(kg: 0.5, maxKg: 1.5, heightMm: h, state: state, mode: CraneMode.remote, top: top);

/// GO availability for hook at [h] and [target].
Availability goTo(double h, double? target, {CraneState state = CraneState.idle, bool top = false}) => evaluateControls(
  connected: true,
  health: LinkHealth.ok,
  live: at(h, state: state, top: top),
  targetMm: target,
).goTo;

/// Values of the "value" field of every GOTO published.
List<num> gotoValues(FakeGateway gw) => [
  for (final (topic, payload) in gw.published)
    if (topic == 'crane/cmd' && payload.contains('GOTO')) (jsonDecode(payload) as Map)['value'] as num,
];

void main() {
  group('goToDirection', () {
    test('up, down, or arrived within 3 mm', () {
      expect(goToDirection(heightMm: 100, targetMm: 200), CommandType.lift);
      expect(goToDirection(heightMm: 200, targetMm: 100), CommandType.lower);
      expect(goToDirection(heightMm: 100, targetMm: 103), isNull);
      expect(goToDirection(heightMm: 100, targetMm: 97), isNull);
      expect(goToDirection(heightMm: 100, targetMm: 103.5), CommandType.lift);
    });
  });

  group('GO availability', () {
    test('needs a target', () => expect(goTo(100, null), const Availability.disabled(DisabledReason.pickTarget)));

    test('disabled at the target', () => expect(goTo(100, 101), const Availability.disabled(DisabledReason.atTarget)));

    test('enabled up or down when IDLE', () {
      expect(goTo(100, 250).enabled, isTrue);
      expect(goTo(250, 100).enabled, isTrue);
    });

    test('OVERLOAD: only downward targets', () {
      expect(goTo(200, 300, state: CraneState.overload), const Availability.disabled(DisabledReason.overload));
      expect(goTo(200, 50, state: CraneState.overload).enabled, isTrue);
    });

    test('TOP: only downward targets', () {
      expect(goTo(346, 340, state: CraneState.top).enabled, isTrue);
      expect(goTo(300, 340, top: true), const Availability.disabled(DisabledReason.top));
    });

    test('JAM: disabled both ways', () {
      expect(goTo(200, 300, state: CraneState.jam).enabled, isFalse);
      expect(goTo(200, 50, state: CraneState.jam).enabled, isFalse);
    });

    test('global blockers apply (LOCAL, stale)', () {
      final local = evaluateControls(
        connected: true,
        health: LinkHealth.ok,
        live: const CraneLive(kg: 0, maxKg: 1.5, state: CraneState.idle, mode: CraneMode.local),
        targetMm: 200,
      );
      expect(local.goTo, const Availability.disabled(DisabledReason.local));
      final stale = evaluateControls(connected: true, health: LinkHealth.stale, live: at(100), targetMm: 200);
      expect(stale.goTo, const Availability.disabled(DisabledReason.stale));
    });
  });

  test('GOTO payload carries the target', () {
    expect(jsonDecode(const CraneCommand(id: 5, type: CommandType.goTo, value: 200).toPayload()), {
      'id': 5,
      'cmd': 'GOTO',
      'value': 200.0,
    });
  });

  test('GO button labels', () {
    expect(goButtonLabel(target: null, height: 100, direction: null), 'GO');
    expect(goButtonLabel(target: 200, height: 112, direction: CommandType.lift), 'GO ↑ 88 mm');
    expect(goButtonLabel(target: 50, height: 112, direction: CommandType.lower), 'GO ↓ 62 mm');
    expect(goButtonLabel(target: 112, height: 112, direction: null), 'AT TARGET');
  });

  group('repository GOTO hold', () {
    testWidgets('repeats GOTO with the target every 250 ms, STOP on release', (tester) async {
      final gw = FakeGateway();
      final repo = MqttCommandRepository(gw);
      repo.startHold(CommandType.goTo, value: 200);
      await tester.pump(const Duration(milliseconds: 500));
      expect(gotoValues(gw), [200, 200, 200]);
      repo.releaseHold();
      expect(gw.motionCommands.last, 'STOP');
      repo.dispose();
    });

    testWidgets('retarget while holding sends the new value without STOP', (tester) async {
      final gw = FakeGateway();
      final repo = MqttCommandRepository(gw);
      repo.startHold(CommandType.goTo, value: 200);
      repo.startHold(CommandType.goTo, value: 150);
      await tester.pump(const Duration(milliseconds: 250));
      expect(gotoValues(gw), [200, 150, 150]);
      expect(gw.motionCommands, isNot(contains('STOP')));
      repo.dispose();
    });
  });

  group('ControlController GO', () {
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
      'arrival releases the hold (STOP) and counts as reached',
      (tester) => withController(tester, (gw, container) async {
        gw.push('crane/live', liveJson(h: 100));
        await tester.pump();
        container.read(goToTargetProvider.notifier).setTarget(200);
        container.read(controlProvider.notifier).pressGoTo();
        await tester.pump(const Duration(milliseconds: 300));
        expect(gw.motionCommands.first, 'GOTO');

        gw.push('crane/live', liveJson(h: 150, st: 'LIFTING', src: 'APP'));
        await tester.pump(const Duration(milliseconds: 10));
        expect(container.read(controlProvider), CommandType.goTo, reason: 'still moving');

        gw.push('crane/live', liveJson(h: 199));
        await tester.pump(const Duration(milliseconds: 10));
        expect(gw.motionCommands.last, 'STOP');
        expect(container.read(controlProvider), isNull);
        final after = container.read(goToTargetProvider);
        expect(after.reached, 1);
        expect(after.mm, isNull, reason: 'card reset after arrival');
        expect(after.lastReachedMm, 200);
        expect(
          container.read(controlAvailabilityProvider).goTo,
          const Availability.disabled(DisabledReason.pickTarget),
        );

        // A new target works straight away.
        container.read(goToTargetProvider.notifier).setTarget(120);
        container.read(controlProvider.notifier).pressGoTo();
        expect(gw.motionCommands.last, 'GOTO');
        container.read(controlProvider.notifier).releaseHold(CommandType.goTo);
      }),
    );

    testWidgets(
      'releasing GO right at the target also resets the card',
      (tester) => withController(tester, (gw, container) async {
        gw.push('crane/live', liveJson(h: 100));
        await tester.pump();
        container.read(goToTargetProvider.notifier).setTarget(200);
        container.read(controlProvider.notifier).pressGoTo();
        // Arrival sample and finger-up land in the same frame.
        gw.push('crane/live', liveJson(h: 201));
        container.read(controlProvider.notifier).releaseHold(CommandType.goTo);
        await tester.pump(const Duration(milliseconds: 10));
        expect(container.read(goToTargetProvider).mm, isNull);
        expect(container.read(goToTargetProvider).reached, 1);
        expect(gw.motionCommands.where((c) => c == 'STOP'), hasLength(1));
      }),
    );

    testWidgets(
      'releasing GO early keeps the target',
      (tester) => withController(tester, (gw, container) async {
        gw.push('crane/live', liveJson(h: 100));
        await tester.pump();
        container.read(goToTargetProvider.notifier).setTarget(200);
        container.read(controlProvider.notifier).pressGoTo();
        gw.push('crane/live', liveJson(h: 150, st: 'LIFTING', src: 'APP'));
        await tester.pump(const Duration(milliseconds: 10));
        container.read(controlProvider.notifier).releaseHold(CommandType.goTo);
        expect(container.read(goToTargetProvider).mm, 200);
        expect(container.read(goToTargetProvider).reached, 0);
      }),
    );

    testWidgets(
      'no target: GO does nothing',
      (tester) => withController(tester, (gw, container) async {
        gw.push('crane/live', liveJson(h: 100));
        await tester.pump();
        container.read(controlProvider.notifier).pressGoTo();
        expect(gw.motionCommands, isEmpty);
      }),
    );

    testWidgets(
      'overload during an upward GO stops it without counting as reached',
      (tester) => withController(tester, (gw, container) async {
        gw.push('crane/live', liveJson(h: 100));
        await tester.pump();
        container.read(goToTargetProvider.notifier).setTarget(300);
        container.read(controlProvider.notifier).pressGoTo();
        gw.push('crane/live', liveJson(h: 120, st: 'OVERLOAD', kg: 1.6));
        await tester.pump(const Duration(milliseconds: 10));
        expect(gw.motionCommands, ['GOTO', 'STOP']);
        expect(container.read(goToTargetProvider).reached, 0);
        expect(container.read(goToTargetProvider).mm, 300, reason: 'target kept when stopped for another reason');
      }),
    );

    testWidgets(
      'moving the slider during GO retargets',
      (tester) => withController(tester, (gw, container) async {
        gw.push('crane/live', liveJson(h: 100));
        await tester.pump();
        final targets = container.read(goToTargetProvider.notifier);
        targets.setTarget(300);
        container.read(controlProvider.notifier).pressGoTo();
        targets.setTarget(250.4);
        await tester.pump(const Duration(milliseconds: 10));
        expect(gotoValues(gw), [300, 250]);
      }),
    );

    test('target is clamped to the travel range and rounded', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(goToTargetProvider.notifier).setTarget(1000);
      expect(c.read(goToTargetProvider).mm, 346);
      c.read(goToTargetProvider.notifier).setTarget(-5);
      expect(c.read(goToTargetProvider).mm, 5);
      c.read(goToTargetProvider.notifier).setTarget(123.6);
      expect(c.read(goToTargetProvider).mm, 124);
    });
  });

  group('load above max', () {
    test('blocks LIFT and upward GO before the crane latches OVERLOAD; LOWER stays', () {
      const heavy = CraneLive(kg: 1.55, maxKg: 1.5, heightMm: 200, state: CraneState.idle, mode: CraneMode.remote);
      final a = evaluateControls(connected: true, health: LinkHealth.ok, live: heavy, targetMm: 300);
      expect(a.lift, const Availability.disabled(DisabledReason.overMax));
      expect(a.goTo, const Availability.disabled(DisabledReason.overMax));
      expect(a.lower.enabled, isTrue);
      final down = evaluateControls(connected: true, health: LinkHealth.ok, live: heavy, targetMm: 50);
      expect(down.goTo.enabled, isTrue);
    });
  });

  group('tap-once GO card', () {
    /// Pumps the card on [gw] with the hook at [h].
    Future<void> pumpCard(WidgetTester tester, FakeGateway gw, {double h = 100}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mqttGatewayProvider.overrideWithValue(gw),
            clockProvider.overrideWithValue(() => DateTime(2026, 11, 16, 12)),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const Scaffold(body: SingleChildScrollView(child: GoToHeightCard())),
          ),
        ),
      );
      gw.push('crane/live', liveJson(h: h));
      await tester.pump();
    }

    /// Unmounts so provider timers stop.
    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('one tap: keeps sending GOTO with no finger down, stops and resets on arrival', (tester) async {
      final gw = FakeGateway();
      await pumpCard(tester, gw);
      await tester.tap(find.byTooltip('+10 mm'));
      await tester.tap(find.byTooltip('+10 mm'));
      await tester.pump();
      expect(find.text('110 mm'), findsOneWidget, reason: 'first tap sets the target from the current height');

      await tester.tap(find.textContaining('GO ↑'));
      await tester.pump(const Duration(seconds: 1));
      expect(gotoValues(gw).length, greaterThanOrEqualTo(4), reason: 'repeats continue after the tap');
      expect(find.textContaining('mm to go'), findsOneWidget);

      gw.push('crane/live', liveJson(h: 110));
      await tester.pump(const Duration(milliseconds: 10));
      expect(gw.motionCommands.last, 'STOP');
      expect(find.text('no target'), findsOneWidget);
      final sent = gw.motionCommands.length;
      await tester.pump(const Duration(seconds: 1));
      expect(gw.motionCommands.length, sent, reason: 'nothing more after arrival');
      await unmount(tester);
    });

    testWidgets('second tap cancels with STOP and keeps the target', (tester) async {
      final gw = FakeGateway();
      await pumpCard(tester, gw);
      await tester.tap(find.byTooltip('+10 mm'));
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byTooltip('+10 mm'));
        await tester.pump();
      }
      await tester.pump();
      await tester.tap(find.textContaining('GO ↑'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.textContaining('mm to go'));
      await tester.pump();
      expect(gw.motionCommands.last, 'STOP');
      expect(find.text('160 mm'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('object under the load: downward GO disabled with the reason', (tester) async {
      final gw = FakeGateway();
      await pumpCard(tester, gw, h: 200);
      gw.push('crane/live', {...liveJson(h: 200), 'us': 90.0, 'obs': true});
      await tester.pump();
      await tester.tap(find.byTooltip('−10 mm'));
      await tester.pump();
      expect(find.text('Object under the load'), findsOneWidget);
      await tester.tap(find.textContaining('GO ↓'));
      await tester.pump();
      expect(gw.motionCommands, isEmpty);
      await unmount(tester);
    });
  });
}
