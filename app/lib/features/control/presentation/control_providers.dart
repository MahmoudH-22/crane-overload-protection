import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants.dart';
import '../../connection/presentation/connection_providers.dart';
import '../../telemetry/presentation/telemetry_providers.dart';
import '../data/command_repository.dart';
import '../domain/command_ack.dart';
import '../domain/control_availability.dart';
import '../domain/crane_command.dart';

/// Command sender (hold-to-run, heartbeat, one-shot commands).
final commandRepositoryProvider = Provider<CommandRepository>((ref) {
  final repo = MqttCommandRepository(ref.watch(mqttGatewayProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

/// Chosen go-to height, an arrival counter, and the height of the last arrival.
typedef GoToTarget = ({double? mm, int reached, double? lastReachedMm});

/// Go-to-height target chosen on the slider.
final goToTargetProvider = NotifierProvider<GoToTargetController, GoToTarget>(GoToTargetController.new);

/// Holds the go-to-height target; [GoToTarget.reached] increments on each arrival.
class GoToTargetController extends Notifier<GoToTarget> {
  /// Starts with no target.
  @override
  GoToTarget build() => (mm: null, reached: 0, lastReachedMm: null);

  /// Sets the target to [mm], clamped to the travel range and rounded to 1 mm.
  void setTarget(double mm) => state = (
    mm: mm.clamp(CraneLimits.bottomMm, CraneLimits.topMm).roundToDouble(),
    reached: state.reached,
    lastReachedMm: state.lastReachedMm,
  );

  /// Removes the target.
  void clear() => state = (mm: null, reached: state.reached, lastReachedMm: state.lastReachedMm);

  /// Records that the crane arrived and resets the card: the target is cleared, ready for the next one.
  void arrived() => state = (mm: null, reached: state.reached + 1, lastReachedMm: state.mm);
}

/// Which controls are enabled and why not.
final controlAvailabilityProvider = Provider<ControlAvailability>(
  (ref) => evaluateControls(
    connected: ref.watch(connectionProvider.select((c) => c.isConnected)),
    health: ref.watch(linkHealthProvider),
    live: ref.watch(telemetryProvider.select((t) => t.live)),
    targetMm: ref.watch(goToTargetProvider.select((t) => t.mm)),
    fitted: ref.watch(fittedSensorsProvider),
  ),
);

/// Replies from the crane.
final ackProvider = StreamProvider<CommandAck>((ref) => ref.watch(commandRepositoryProvider).acks);

/// Control actions; state is the motion currently held (or null).
final controlProvider = NotifierProvider<ControlController, CommandType?>(ControlController.new);

/// Turns UI gestures into commands, respecting [controlAvailabilityProvider].
class ControlController extends Notifier<CommandType?> {
  /// Tracks the repository's hold state, drops a hold whose control becomes
  /// disabled (overload, stale data, LOCAL, ...), ends GO on arrival, and
  /// retargets a running GO when the slider moves.
  @override
  CommandType? build() {
    final repo = ref.watch(commandRepositoryProvider);
    final sub = repo.holdChanges.listen((hold) => state = hold);
    ref.onDispose(sub.cancel);
    ref.listen(controlAvailabilityProvider, (_, availability) {
      final hold = repo.activeHold;
      final Availability? held = switch (hold) {
        CommandType.lift => availability.lift,
        CommandType.lower => availability.lower,
        CommandType.goTo => availability.goTo,
        _ => null,
      };
      if (held == null || held.enabled) return;
      repo.releaseHold();
      if (hold == CommandType.goTo && held.reason == DisabledReason.atTarget) {
        ref.read(goToTargetProvider.notifier).arrived();
      }
    });
    ref.listen(goToTargetProvider.select((t) => t.mm), (_, mm) {
      if (repo.activeHold == CommandType.goTo && mm != null) repo.startHold(CommandType.goTo, value: mm);
    });
    return repo.activeHold;
  }

  CommandRepository get _repo => ref.read(commandRepositoryProvider);

  /// Finger down on LIFT / LOWER ([direction]); ignored if disabled.
  void pressHold(CommandType direction) {
    final a = ref.read(controlAvailabilityProvider);
    final allowed = direction == CommandType.lift ? a.lift : a.lower;
    if (allowed.enabled) _repo.startHold(direction);
  }

  /// GO button tap: starts an automatic move to the target, or cancels (STOP) one in progress.
  ///
  /// The move needs no finger on the button: the app keeps repeating GOTO every 250 ms
  /// until arrival, a disabled condition, STOP, app background or disconnect. If the app
  /// dies, the repeats stop and the crane halts within 600 ms.
  void toggleGoTo() {
    if (_repo.activeHold == CommandType.goTo) {
      releaseHold(CommandType.goTo);
    } else {
      pressGoTo();
    }
  }

  /// Starts the move toward the chosen target; ignored if disabled.
  void pressGoTo() {
    final target = ref.read(goToTargetProvider).mm;
    if (target != null && ref.read(controlAvailabilityProvider).goTo.enabled) {
      _repo.startHold(CommandType.goTo, value: target);
    }
  }

  /// Finger up / cancelled / slid off the button for [type]: STOP.
  ///
  /// Releasing GO with the hook already at the target also counts as arrival (resets the card).
  void releaseHold(CommandType type) {
    // A HoldButton disposed while the app is shutting down may call this after the provider is gone.
    if (!ref.mounted) return;
    if (_repo.activeHold != type) return;
    _repo.releaseHold();
    if (type == CommandType.goTo && ref.read(controlAvailabilityProvider).goTo.reason == DisabledReason.atTarget) {
      ref.read(goToTargetProvider.notifier).arrived();
    }
  }

  /// App left the foreground: stop any held motion.
  void onAppBackground() => _repo.releaseHold();

  /// STOP button.
  void stop() => _repo.send(CommandType.stop);

  /// RESET button.
  void reset() => _repo.send(CommandType.reset);

  /// TARE button.
  void tare() => _repo.send(CommandType.tare);

  /// Max-load slider released at [kg].
  void setMax(double kg) => _repo.send(CommandType.setMax, value: kg);
}
