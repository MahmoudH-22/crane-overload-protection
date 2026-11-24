import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/time_utils.dart';
import '../domain/crane_event.dart';
import 'events_providers.dart';

/// List of crane events, newest first, with a Clear button.
class EventsScreen extends ConsumerWidget {
  /// Creates the screen.
  const EventsScreen({super.key});

  /// Builds the list.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Events (${events.length})'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: events.isEmpty ? null : ref.read(eventsProvider.notifier).clear,
          ),
        ],
      ),
      body: events.isEmpty
          ? const Center(child: Text('No events yet.'))
          : ListView.separated(
              itemCount: events.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => EventTile(event: events[i]),
            ),
    );
  }
}

/// One row: icon, type, time and weight.
class EventTile extends StatelessWidget {
  /// Creates the row for [event].
  const EventTile({super.key, required this.event});

  /// The event shown.
  final CraneEvent event;

  /// Builds the row.
  @override
  Widget build(BuildContext context) {
    final colors = context.status;
    final color = event.type.isAlarm ? colors.danger : colors.info;
    final received = event.receivedAt;
    return ListTile(
      leading: Icon(eventIcon(event.type), color: color),
      title: Text(
        event.type.label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${received == null ? '' : formatClock(received)} · crane t = ${(event.millis / 1000).toStringAsFixed(1)} s',
      ),
      trailing: event.kg == null
          ? null
          : Text(
              event.type == CraneEventType.maxChanged
                  ? 'max ${event.kg!.toStringAsFixed(2)} kg'
                  : '${event.kg!.toStringAsFixed(3)} kg',
              style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
            ),
    );
  }
}

/// Icon for an event [type].
IconData eventIcon(CraneEventType type) => switch (type) {
  CraneEventType.overload => Icons.scale,
  CraneEventType.overloadCleared => Icons.check_circle_outline,
  CraneEventType.jam => Icons.settings_suggest,
  CraneEventType.top => Icons.vertical_align_top,
  CraneEventType.estop => Icons.dangerous,
  CraneEventType.estopReleased => Icons.play_circle_outline,
  CraneEventType.reset => Icons.restart_alt,
  CraneEventType.tare => Icons.exposure_zero,
  CraneEventType.maxChanged => Icons.tune,
  CraneEventType.linkLost => Icons.link_off,
  CraneEventType.obstacle => Icons.back_hand,
  CraneEventType.obstacleCleared => Icons.check_circle_outline,
  CraneEventType.unknown => Icons.help_outline,
};
