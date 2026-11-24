import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants.dart';
import '../../connection/presentation/connection_providers.dart';
import '../data/events_repository.dart';
import '../domain/crane_event.dart';

/// Event source.
final eventsRepositoryProvider = Provider<EventsRepository>(
  (ref) => MqttEventsRepository(ref.watch(mqttGatewayProvider)),
);

/// Received events, newest first, at most [kMaxEvents].
final eventsProvider = NotifierProvider<EventsController, List<CraneEvent>>(EventsController.new);

/// Keeps the in-memory event log.
class EventsController extends Notifier<List<CraneEvent>> {
  /// Subscribes to the repository; starts empty.
  @override
  List<CraneEvent> build() {
    final sub = ref.watch(eventsRepositoryProvider).events.listen(_add);
    ref.onDispose(sub.cancel);
    return const [];
  }

  /// Prepends [event], keeping at most [kMaxEvents].
  void _add(CraneEvent event) => state = addEvent(state, event);

  /// Empties the log.
  void clear() => state = const [];
}

/// Returns [events] with [event] prepended, capped at [max].
///
/// [events]: newest first. Returns a new list.
List<CraneEvent> addEvent(List<CraneEvent> events, CraneEvent event, {int max = kMaxEvents}) => [
  event,
  ...events.take(max - 1),
];
