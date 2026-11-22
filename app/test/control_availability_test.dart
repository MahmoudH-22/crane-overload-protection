import 'package:crane_monitor/features/control/domain/control_availability.dart';
import 'package:crane_monitor/features/telemetry/domain/crane_live.dart';
import 'package:crane_monitor/features/telemetry/domain/crane_state.dart';
import 'package:crane_monitor/features/telemetry/domain/link_health.dart';
import 'package:flutter_test/flutter_test.dart';

/// A live sample in [state] / [mode].
CraneLive live(CraneState state, {CraneMode mode = CraneMode.remote, bool top = false}) =>
    CraneLive(kg: 0.5, maxKg: 1.5, state: state, mode: mode, top: top);

/// Evaluates with a healthy connection unless overridden.
ControlAvailability eval(CraneLive? sample, {bool connected = true, LinkHealth health = LinkHealth.ok}) =>
    evaluateControls(connected: connected, health: health, live: sample);

/// The six controls as a list, for "all" assertions.
List<Availability> all(ControlAvailability a) => [a.lift, a.lower, a.stop, a.reset, a.tare, a.setMax];

void main() {
  group('global blockers', () {
    test('not connected disables everything, including STOP', () {
      final a = eval(live(CraneState.idle), connected: false);
      for (final c in all(a)) {
        expect(c.enabled, isFalse);
        expect(c.reason, DisabledReason.notConnected);
      }
    });

    test('health "disconnected" also counts as not connected', () {
      expect(eval(live(CraneState.idle), health: LinkHealth.disconnected).stop.enabled, isFalse);
    });

    for (final (health, reason) in [
      (LinkHealth.stale, DisabledReason.stale),
      (LinkHealth.offline, DisabledReason.offline),
    ]) {
      test('$health disables all but STOP', () {
        final a = eval(live(CraneState.idle), health: health);
        expect(a.stop.enabled, isTrue);
        for (final c in [a.lift, a.lower, a.reset, a.tare, a.setMax]) {
          expect(c, Availability.disabled(reason));
        }
      });
    }

    test('no sample yet', () {
      final a = eval(null);
      expect(a.lift, const Availability.disabled(DisabledReason.waiting));
      expect(a.stop.enabled, isTrue);
    });

    test('LOCAL mode disables all but STOP', () {
      final a = eval(live(CraneState.idle, mode: CraneMode.local));
      expect(a.stop.enabled, isTrue);
      for (final c in [a.lift, a.lower, a.reset, a.tare, a.setMax]) {
        expect(c, const Availability.disabled(DisabledReason.local));
      }
    });

    test('ESTOP disables all but STOP', () {
      final a = eval(live(CraneState.estop));
      expect(a.stop.enabled, isTrue);
      expect(a.lower, const Availability.disabled(DisabledReason.estop));
      expect(a.reset, const Availability.disabled(DisabledReason.estop));
    });
  });

  group('per state', () {
    test('IDLE: everything except RESET', () {
      final a = eval(live(CraneState.idle));
      expect(a.lift.enabled, isTrue);
      expect(a.lower.enabled, isTrue);
      expect(a.tare.enabled, isTrue);
      expect(a.setMax.enabled, isTrue);
      expect(a.reset, const Availability.disabled(DisabledReason.nothingToReset));
    });

    test('OVERLOAD: no LIFT, LOWER ok, RESET ok', () {
      final a = eval(live(CraneState.overload));
      expect(a.lift, const Availability.disabled(DisabledReason.overload));
      expect(a.lower.enabled, isTrue);
      expect(a.reset.enabled, isTrue);
      expect(a.tare, const Availability.disabled(DisabledReason.tareIdleOnly));
    });

    test('JAM: no LIFT, no LOWER, RESET ok', () {
      final a = eval(live(CraneState.jam));
      expect(a.lift, const Availability.disabled(DisabledReason.jam));
      expect(a.lower, const Availability.disabled(DisabledReason.jam));
      expect(a.reset.enabled, isTrue);
    });

    test('TOP: no LIFT, LOWER ok', () {
      final a = eval(live(CraneState.top));
      expect(a.lift, const Availability.disabled(DisabledReason.top));
      expect(a.lower.enabled, isTrue);
      expect(a.tare, const Availability.disabled(DisabledReason.tareIdleOnly));
    });

    test('top sensor active while lowering still blocks LIFT', () {
      final a = eval(live(CraneState.lowering, top: true));
      expect(a.lift, const Availability.disabled(DisabledReason.top));
      expect(a.lower.enabled, isTrue);
    });

    test('LIFTING / LOWERING keep both directions, no TARE', () {
      for (final s in [CraneState.lifting, CraneState.lowering]) {
        final a = eval(live(s));
        expect(a.lift.enabled, isTrue, reason: '$s');
        expect(a.lower.enabled, isTrue, reason: '$s');
        expect(a.tare.enabled, isFalse, reason: '$s');
        expect(a.stop.enabled, isTrue, reason: '$s');
      }
    });

    test('STOP is enabled in every state while connected', () {
      for (final s in CraneState.values) {
        expect(eval(live(s)).stop.enabled, isTrue, reason: '$s');
      }
    });
  });
}
