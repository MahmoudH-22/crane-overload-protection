import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../telemetry/domain/link_health.dart';
import '../../telemetry/presentation/telemetry_providers.dart';
import '../domain/connection_state.dart';
import 'connection_providers.dart';

/// Coloured dot + label: Live / Stale / Crane offline / Reconnecting….
class ConnectionBadge extends ConsumerWidget {
  /// Creates the badge.
  const ConnectionBadge({super.key});

  /// Builds the badge from link health and broker state.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(linkHealthProvider);
    final connection = ref.watch(connectionProvider);
    final color = context.status.forHealth(health);
    final label = badgeLabel(health, connection);

    return Semantics(
      label: 'Connection: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text for the badge.
///
/// [health]: data freshness. [connection]: broker state.
/// Returns e.g. "Live" or "Reconnecting (2)…".
String badgeLabel(LinkHealth health, BrokerConnection connection) {
  if (connection.status == BrokerStatus.reconnecting) return 'Reconnecting (${connection.attempt})…';
  if (connection.status == BrokerStatus.connecting) return 'Connecting…';
  return health.label;
}
