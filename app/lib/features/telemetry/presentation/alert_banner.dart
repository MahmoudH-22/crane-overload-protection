import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../domain/crane_alert.dart';
import 'telemetry_providers.dart';

/// Full-width red banner for OVERLOAD, JAM, ESTOP and crane offline.
class AlertBanner extends ConsumerWidget {
  /// Creates the banner (empty when there is no alert).
  const AlertBanner({super.key});

  /// Builds the banner from [alertProvider].
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(alertProvider);
    if (alert == null) return const SizedBox.shrink();
    final colors = context.status;
    return Material(
      color: colors.danger,
      child: SafeArea(
        bottom: false,
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(_icon(alert), color: colors.onDanger),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  alert.message,
                  style: TextStyle(color: colors.onDanger, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Icon for [alert].
  IconData _icon(CraneAlert alert) => switch (alert) {
    CraneAlert.overload => Icons.scale,
    CraneAlert.jam => Icons.settings_suggest,
    CraneAlert.estop => Icons.dangerous,
    CraneAlert.obstacle => Icons.back_hand,
    CraneAlert.offline => Icons.wifi_off,
  };
}
