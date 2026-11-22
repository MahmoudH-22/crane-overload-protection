import 'package:crane_monitor/app/app_shell.dart';
import 'package:crane_monitor/app/theme.dart';
import 'package:crane_monitor/core/clock_providers.dart';
import 'package:crane_monitor/features/connection/presentation/connection_providers.dart';
import 'package:crane_monitor/features/control/presentation/control_providers.dart';
import 'package:crane_monitor/features/events/presentation/events_screen.dart';
import 'package:crane_monitor/features/telemetry/presentation/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_gateway.dart';

/// Phone sizes (logical px): small Android, common Android, the V2570-class tall phone.
const _sizes = [Size(320, 640), Size(360, 740), Size(393, 873)];

/// Every state the crane can report, with the new sensor fields.
final _states = <String, Map<String, Object?>>{
  'idle': liveJson(),
  'lifting by app': liveJson(st: 'LIFTING', src: 'APP', a: 0.3),
  'lowering by panel': liveJson(st: 'LOWERING', src: 'PANEL'),
  'near limit': liveJson(kg: 1.4),
  'above max': liveJson(kg: 1.55),
  'overload': liveJson(st: 'OVERLOAD', kg: 1.62),
  'jam': liveJson(st: 'JAM', a: 1.6),
  'top + IR': liveJson(st: 'TOP', h: 346, top: true),
  'estop': liveJson(st: 'ESTOP'),
  'local': liveJson(mode: 'LOCAL'),
  'obstacle': {...liveJson(h: 250), 'us': 90.0, 'obs': true},
  'no echo': {...liveJson(h: 10), 'us': null, 'obs': false},
  'unknown values': liveJson(st: 'NEW_STATE', mode: 'AUTO', src: 'CLOUD'),
  'huge numbers': liveJson(kg: 12.345, h: 9999, a: 25.5),
  'negative numbers': liveJson(kg: -0.4, h: -20, a: -0.1),
};

/// Pumps the real dashboard (inside the app shell) on [gw] at [size].
Future<void> pumpDashboard(WidgetTester tester, FakeGateway gw, Size size, {Widget? home}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mqttGatewayProvider.overrideWithValue(gw),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 16, 12)),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: AppShell(child: home ?? const DashboardScreen()),
      ),
    ),
  );
}

/// Unmounts and resets the view so timers stop and the next test starts clean.
Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

/// Scrolls through the dashboard list so every card is built and laid out.
Future<void> scrollAll(WidgetTester tester) async {
  final list = find.byType(Scrollable).first;
  for (var i = 0; i < 6; i++) {
    await tester.drag(list, const Offset(0, -400));
    await tester.pump();
  }
}

void main() {
  for (final size in _sizes) {
    for (final entry in _states.entries) {
      testWidgets('dashboard renders "${entry.key}" at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        final gw = FakeGateway();
        await pumpDashboard(tester, gw, size);
        gw.push('crane/live', entry.value);
        await tester.pump();
        await scrollAll(tester);
        await finish(tester);
      });
    }

    testWidgets('GO moving + all banners at ${size.width.toInt()} wide', (tester) async {
      final gw = FakeGateway();
      await pumpDashboard(tester, gw, size);
      gw.push('crane/live', liveJson(h: 100));
      await tester.pump();
      final container = ProviderScope.containerOf(tester.element(find.byType(DashboardScreen)));
      container.read(goToTargetProvider.notifier).setTarget(300);
      container.read(controlProvider.notifier).toggleGoTo();
      gw.push('crane/live', liveJson(h: 120, st: 'LIFTING', src: 'APP'));
      await tester.pump(const Duration(milliseconds: 300));
      await scrollAll(tester);
      await finish(tester);
    });

    testWidgets('events screen with every event type at ${size.width.toInt()} wide', (tester) async {
      final gw = FakeGateway();
      await pumpDashboard(tester, gw, size, home: const EventsScreen());
      for (final type in [
        'OVERLOAD', 'OVERLOAD_CLEARED', 'JAM', 'TOP', 'ESTOP', 'ESTOP_RELEASED', 'RESET', 'TARE', //
        'MAX_CHANGED', 'LINK_LOST', 'OBSTACLE', 'OBSTACLE_CLEARED', 'SOMETHING_NEW',
      ]) {
        gw.push('crane/events', {'t': 123456, 'type': type, 'kg': 1.234});
      }
      gw.push('crane/events', {'t': 1, 'type': 'TOP'}); // no kg
      await tester.pump();
      await finish(tester);
    });
  }

  group('large system font (130 %)', () {
    for (final entry in _states.entries) {
      testWidgets('dashboard renders "${entry.key}" at 360 wide, font 1.3x', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final gw = FakeGateway();
        await pumpDashboard(tester, gw, _sizes[1]);
        gw.push('crane/live', entry.value);
        await tester.pump();
        await scrollAll(tester);
        await finish(tester);
      });
    }
  });

  group('phone locked and reopened', () {
    testWidgets('pause → connection lost → resume → reconnect, while GO was running', (tester) async {
      final gw = FakeGateway();
      await pumpDashboard(tester, gw, _sizes[1]);
      gw.push('crane/live', liveJson(h: 100));
      await tester.pump();
      final container = ProviderScope.containerOf(tester.element(find.byType(DashboardScreen)));
      container.read(goToTargetProvider.notifier).setTarget(250);
      container.read(controlProvider.notifier).toggleGoTo();
      await tester.pump(const Duration(milliseconds: 300));

      // Screen off.
      for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(gw.motionCommands.last, 'STOP');

      // Android drops Wi-Fi while locked; time passes.
      gw.setConnected(false);
      await tester.pump(const Duration(seconds: 30));

      // Screen on.
      for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pump(const Duration(seconds: 1));
      gw.setConnected(true, at: DateTime(2026, 11, 16, 12));
      gw.push('crane/status', {'online': true, 'fw': 'sim-1.0'});
      gw.push('crane/live', liveJson(h: 130, st: 'OVERLOAD', kg: 1.6));
      await tester.pump(const Duration(seconds: 1));
      await scrollAll(tester);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });

    testWidgets('resume while the dashboard is not on screen (events open)', (tester) async {
      final gw = FakeGateway();
      await pumpDashboard(tester, gw, _sizes[1], home: const EventsScreen());
      for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      gw.setConnected(false);
      await tester.pump(const Duration(seconds: 5));
      for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      gw.setConnected(true);
      gw.push('crane/events', {'t': 1, 'type': 'LINK_LOST'});
      await tester.pump(const Duration(seconds: 1));
      await finish(tester);
    });
  });
}
