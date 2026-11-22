import 'package:crane_monitor/app/app_shell.dart';
import 'package:crane_monitor/app/theme.dart';
import 'package:crane_monitor/core/clock_providers.dart';
import 'package:crane_monitor/features/connection/presentation/connection_providers.dart';
import 'package:crane_monitor/features/control/presentation/control_panel.dart';
import 'package:crane_monitor/features/telemetry/presentation/alert_banner.dart';
import 'package:crane_monitor/features/telemetry/presentation/ir_sensor_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_gateway.dart';

/// Pumps the shell + motion controls + alert banner on top of [gw].
Future<void> pumpPanel(WidgetTester tester, FakeGateway gw) async {
  final fixed = DateTime(2026, 11, 15, 12);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [mqttGatewayProvider.overrideWithValue(gw), clockProvider.overrideWithValue(() => fixed)],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const AppShell(
          child: Scaffold(
            body: Column(children: [AlertBanner(), Spacer(), ActionsCard()]),
            bottomNavigationBar: MotionControls(),
          ),
        ),
      ),
    ),
  );
}

/// Unmounts everything so provider timers are cancelled.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('holding LIFT repeats; releasing sends STOP', (tester) async {
    final gw = FakeGateway();
    await pumpPanel(tester, gw);
    gw.push('crane/live', liveJson());
    await tester.pump();

    final gesture = await tester.startGesture(tester.getCenter(find.text('LIFT')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(gw.motionCommands, ['LIFT', 'LIFT', 'LIFT']);

    await gesture.up();
    await tester.pump();
    expect(gw.motionCommands.last, 'STOP');
    await unmount(tester);
  });

  testWidgets('finger sliding off LIFT sends STOP', (tester) async {
    final gw = FakeGateway();
    await pumpPanel(tester, gw);
    gw.push('crane/live', liveJson());
    await tester.pump();

    final gesture = await tester.startGesture(tester.getCenter(find.text('LIFT')));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(const Offset(5, 5)); // far outside the button
    await tester.pump();
    expect(gw.motionCommands, ['LIFT', 'STOP']);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 500));
    expect(gw.motionCommands, ['LIFT', 'STOP'], reason: 'no second STOP, no more LIFT');
    await unmount(tester);
  });

  testWidgets('app paused while holding LIFT sends STOP', (tester) async {
    final gw = FakeGateway();
    await pumpPanel(tester, gw);
    gw.push('crane/live', liveJson());
    await tester.pump();

    final gesture = await tester.startGesture(tester.getCenter(find.text('LIFT')));
    await tester.pump(const Duration(milliseconds: 300));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 500));
    expect(gw.motionCommands, ['LIFT', 'LIFT', 'STOP']);

    await gesture.up();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await unmount(tester);
  });

  testWidgets('overload: banner shown, LIFT disabled with reason, LOWER and RESET enabled', (tester) async {
    final gw = FakeGateway();
    await pumpPanel(tester, gw);
    gw.push('crane/live', liveJson(st: 'OVERLOAD', kg: 1.6));
    await tester.pump();

    expect(find.textContaining('OVERLOAD:'), findsOneWidget);
    expect(find.text('Overload: lower only'), findsOneWidget);

    await tester.tap(find.text('LIFT'));
    await tester.pump();
    expect(gw.motionCommands, isEmpty);

    final lower = await tester.startGesture(tester.getCenter(find.text('LOWER')));
    await tester.pump(const Duration(milliseconds: 100));
    await lower.up();
    await tester.pump();
    expect(gw.motionCommands, ['LOWER', 'STOP']);

    await tester.tap(find.text('RESET'));
    await tester.pump();
    expect(gw.motionCommands.last, 'RESET');
    await unmount(tester);
  });

  testWidgets('LOCAL mode disables LIFT with the reason shown', (tester) async {
    final gw = FakeGateway();
    await pumpPanel(tester, gw);
    gw.push('crane/live', liveJson(mode: 'LOCAL'));
    await tester.pump();
    expect(find.textContaining('LOCAL mode'), findsWidgets);
    await tester.tap(find.text('LIFT'));
    await tester.pump();
    expect(gw.motionCommands, isEmpty);
    await unmount(tester);
  });

  testWidgets('IR indicator shows TOP when the sensor is active, clear otherwise', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const Scaffold(
          body: Column(children: [IrSensorIndicator(active: true), IrSensorIndicator(active: false)]),
        ),
      ),
    );
    expect(find.text('IR TOP'), findsOneWidget);
    expect(find.text('IR clear'), findsOneWidget);
  });

  testWidgets('crane Last Will shows the offline banner', (tester) async {
    final gw = FakeGateway();
    await pumpPanel(tester, gw);
    gw.push('crane/live', liveJson());
    gw.push('crane/status', {'online': false});
    await tester.pump();
    expect(find.textContaining('Crane offline'), findsWidgets);
    await unmount(tester);
  });
}
