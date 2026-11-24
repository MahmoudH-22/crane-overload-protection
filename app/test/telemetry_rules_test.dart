import 'package:crane_monitor/features/events/domain/crane_event.dart';
import 'package:crane_monitor/features/events/presentation/events_providers.dart';
import 'package:crane_monitor/features/telemetry/domain/crane_alert.dart';
import 'package:crane_monitor/features/telemetry/domain/crane_state.dart';
import 'package:crane_monitor/features/telemetry/domain/link_health.dart';
import 'package:crane_monitor/features/telemetry/domain/load_level.dart';
import 'package:crane_monitor/features/telemetry/domain/telemetry_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 11, 15, 12);

  /// Evaluates health with the last live sample [ageMs] old.
  LinkHealth health({int? ageMs, bool connected = true, bool? online = true, int connectedAgoMs = 10000}) =>
      evaluateLinkHealth(
        brokerConnected: connected,
        craneOnline: online,
        lastLiveAt: ageMs == null ? null : t0.subtract(Duration(milliseconds: ageMs)),
        connectedAt: t0.subtract(Duration(milliseconds: connectedAgoMs)),
        now: t0,
      );

  group('link health', () {
    test('fresh within 1 s', () {
      expect(health(ageMs: 0), LinkHealth.ok);
      expect(health(ageMs: 1000), LinkHealth.ok);
    });

    test('stale after 1 s, offline after 3 s', () {
      expect(health(ageMs: 1001), LinkHealth.stale);
      expect(health(ageMs: 3000), LinkHealth.stale);
      expect(health(ageMs: 3001), LinkHealth.offline);
    });

    test('Last Will (online=false) is offline at once', () {
      expect(health(ageMs: 0, online: false), LinkHealth.offline);
    });

    test('not connected wins over everything', () {
      expect(health(ageMs: 0, connected: false), LinkHealth.disconnected);
    });

    test('no data yet: stale for 3 s after connecting, then offline', () {
      expect(health(online: null, connectedAgoMs: 500), LinkHealth.stale);
      expect(health(online: null, connectedAgoMs: 3500), LinkHealth.offline);
    });
  });

  group('load level', () {
    test('bands at 90 % and 100 % of max', () {
      expect(evaluateLoadLevel(kg: 1.0, maxKg: 1.5, state: CraneState.idle), LoadLevel.normal);
      expect(evaluateLoadLevel(kg: 1.35, maxKg: 1.5, state: CraneState.idle), LoadLevel.near);
      expect(evaluateLoadLevel(kg: 1.5, maxKg: 1.5, state: CraneState.idle), LoadLevel.near);
      expect(evaluateLoadLevel(kg: 1.51, maxKg: 1.5, state: CraneState.idle), LoadLevel.over);
    });

    test('OVERLOAD state is red even below max', () {
      expect(evaluateLoadLevel(kg: 0.2, maxKg: 1.5, state: CraneState.overload), LoadLevel.over);
    });
  });

  group('alerts', () {
    test('offline beats state', () {
      expect(evaluateAlert(health: LinkHealth.offline, state: CraneState.overload), CraneAlert.offline);
    });

    test('faults raise alerts', () {
      expect(evaluateAlert(health: LinkHealth.ok, state: CraneState.overload), CraneAlert.overload);
      expect(evaluateAlert(health: LinkHealth.ok, state: CraneState.jam), CraneAlert.jam);
      expect(evaluateAlert(health: LinkHealth.stale, state: CraneState.estop), CraneAlert.estop);
    });

    test('no alert when normal or disconnected', () {
      expect(evaluateAlert(health: LinkHealth.ok, state: CraneState.lifting), isNull);
      expect(evaluateAlert(health: LinkHealth.disconnected, state: CraneState.overload), isNull);
    });
  });

  group('history window', () {
    test('drops samples older than the window', () {
      var list = <Sample>[];
      for (var s = 0; s <= 40; s++) {
        list = appendWindowed(list, Sample(t0.add(Duration(seconds: s)), s.toDouble()), const Duration(seconds: 30));
      }
      expect(list.first.value, 10);
      expect(list.last.value, 40);
      expect(list.length, 31);
    });
  });

  group('event log', () {
    test('newest first, capped', () {
      var events = <CraneEvent>[];
      for (var i = 0; i < 5; i++) {
        events = addEvent(events, CraneEvent(millis: i, type: CraneEventType.tare), max: 3);
      }
      expect(events.map((e) => e.millis), [4, 3, 2]);
    });
  });
}
