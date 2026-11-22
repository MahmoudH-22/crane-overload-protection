/// The real crane right now: Uno with only the load cell and the IR sensor, behind the NodeMCU.
///
/// The JSON below is exactly what firmware/nodemcu/crane_nodemcu publishes for that setup
/// (the same strings are checked on the C++ side in firmware/test/link_test.cpp).
library;

import 'package:crane_monitor/app/app_shell.dart';
import 'package:crane_monitor/app/theme.dart';
import 'package:crane_monitor/core/clock_providers.dart';
import 'package:crane_monitor/features/connection/presentation/connection_providers.dart';
import 'package:crane_monitor/features/control/domain/control_availability.dart';
import 'package:crane_monitor/features/telemetry/data/telemetry_repository.dart';
import 'package:crane_monitor/features/telemetry/domain/crane_state.dart';
import 'package:crane_monitor/features/telemetry/domain/crane_status.dart';
import 'package:crane_monitor/features/telemetry/domain/link_health.dart';
import 'package:crane_monitor/features/telemetry/presentation/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_gateway.dart';

/// crane/live from the bridge with only kg + IR fitted (IR active here).
const twoSensorLive =
    '{"t":123456,"kg":1.234,"max":1.500,"h":null,"a":null,"top":true,"st":"TOP",'
    '"mode":"REMOTE","src":"NONE","us":null,"obs":false}';

/// Same, IR clear and IDLE.
const twoSensorIdle =
    '{"t":123656,"kg":0.512,"max":1.500,"h":null,"a":null,"top":false,"st":"IDLE",'
    '"mode":"REMOTE","src":"NONE","us":null,"obs":false}';

/// crane/status from the bridge.
const twoSensorStatus = '{"online":true,"fw":"m2.0","sensors":["kg","top"]}';

void main() {
  test('bridge JSON parses: weight and IR present, other sensors null', () {
    final live = parseLive(twoSensorLive)!;
    expect(live.kg, 1.234);
    expect(live.maxKg, 1.5);
    expect(live.top, isTrue);
    expect(live.state, CraneState.top);
    expect(live.heightMm, isNull);
    expect(live.amps, isNull);
    expect(live.ultrasonicMm, isNull);
    final status = parseStatus(twoSensorStatus)!;
    expect(status.online, isTrue);
    expect(status.sensors, ['kg', 'top']);
  });

  test('no motor reported: LIFT / LOWER / GO disabled with the reason; TARE, RESET rules unchanged', () {
    final a = evaluateControls(
      connected: true,
      health: LinkHealth.ok,
      live: parseLive(twoSensorIdle),
      targetMm: 200,
      fitted: {Sensor.kg, Sensor.top},
    );
    expect(a.lift, const Availability.disabled(DisabledReason.noMotor));
    expect(a.lower, const Availability.disabled(DisabledReason.noMotor));
    expect(a.goTo, const Availability.disabled(DisabledReason.noMotor));
    expect(a.stop.enabled, isTrue);
    expect(a.tare.enabled, isTrue);
    expect(a.setMax.enabled, isTrue);
  });

  test('simulator (no sensors list) keeps everything enabled', () {
    final a = evaluateControls(connected: true, health: LinkHealth.ok, live: parseLive(twoSensorIdle));
    expect(a.lift.enabled, isTrue);
    expect(a.goTo, const Availability.disabled(DisabledReason.noHeight), reason: 'no height in this sample');
  });

  testWidgets('dashboard with the two-sensor crane: weight, IR TOP, not-fitted cards, motor reason', (tester) async {
    tester.view.physicalSize = const Size(360, 740) * 3;
    tester.view.devicePixelRatio = 3;
    final gw = FakeGateway();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mqttGatewayProvider.overrideWithValue(gw),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 16, 12)),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: const AppShell(child: DashboardScreen()),
        ),
      ),
    );
    gw.push('crane/status', twoSensorStatus);
    gw.push('crane/live', twoSensorLive);
    await tester.pump();

    expect(find.text('1.234 kg'), findsOneWidget);
    expect(find.text('IR TOP'), findsOneWidget);
    expect(find.text('n/a'), findsOneWidget, reason: 'height bar without encoder');
    expect(find.text('Motor not connected'), findsNWidgets(3), reason: 'on LIFT, LOWER and GO');

    // Pressing LIFT sends nothing.
    await tester.tap(find.text('LIFT'));
    await tester.pump();
    expect(gw.motionCommands, isEmpty);

    // IR clears (height card still on screen).
    gw.push('crane/live', twoSensorIdle);
    await tester.pump();
    expect(find.text('IR clear'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pump();
    expect(find.text('not fitted'), findsWidgets, reason: 'ultrasonic and current cards');

    // TARE works from the app.
    await tester.scrollUntilVisible(find.text('TARE'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('TARE'));
    await tester.pump();
    expect(gw.motionCommands, ['TARE']);

    // Unplugged Uno: the bridge publishes online:false -> crane offline banner.
    gw.push('crane/status', '{"online":false,"fw":"m2.0","sensors":["kg","top"]}');
    await tester.pump();
    expect(find.textContaining('Crane offline'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
