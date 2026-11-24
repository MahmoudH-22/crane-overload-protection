import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../connection/presentation/connection_badge.dart';
import '../../connection/presentation/connection_providers.dart';
import '../../control/domain/command_ack.dart';
import '../../control/presentation/control_panel.dart';
import '../../control/presentation/control_providers.dart';
import '../../control/presentation/go_to_height_card.dart';
import 'alert_banner.dart';
import 'dashboard_cards.dart';

/// Main screen: alerts, live readings, actions and the motion controls.
class DashboardScreen extends ConsumerWidget {
  /// Creates the screen.
  const DashboardScreen({super.key});

  /// Shows a snackbar for a refused command.
  void _onAck(BuildContext context, CommandAck ack) {
    if (ack.ok) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(ack.reasonText), duration: const Duration(seconds: 3)));
  }

  /// Confirms that GO reached the target height [mm].
  void _onArrived(BuildContext context, double? mm) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Reached ${mm?.toStringAsFixed(0) ?? ''} mm'), duration: const Duration(seconds: 2)),
      );
  }

  /// Disconnects and returns to the connect screen.
  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    await ref.read(connectionProvider.notifier).disconnect();
    if (context.mounted) context.go(Routes.connect);
  }

  /// Builds the layout (one column on phones, two on wide screens).
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(ackProvider, (_, next) {
      if (next case AsyncData(:final value)) _onAck(context, value);
    });
    ref.listen(goToTargetProvider, (previous, next) {
      if (previous != null && next.reached > previous.reached) _onArrived(context, next.lastReachedMm);
    });

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(fit: BoxFit.scaleDown, child: Text('Crane Overload')),
        actions: [
          const ConnectionBadge(),
          IconButton(tooltip: 'Events', icon: const Icon(Icons.list_alt), onPressed: () => context.push(Routes.events)),
          IconButton(
            tooltip: 'Disconnect',
            icon: const Icon(Icons.link_off),
            onPressed: () => _disconnect(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          const AlertBanner(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  constraints.maxWidth >= 840 ? const _WideLayout() : const _NarrowLayout(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MotionControls(),
    );
  }
}

/// Phone layout: one scrolling column.
class _NarrowLayout extends StatelessWidget {
  /// Creates the layout.
  const _NarrowLayout();

  /// Builds the column.
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: const [
      SizedBox(
        height: 300,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: WeightCard()),
            SizedBox(width: 12),
            SizedBox(width: 96, child: HeightCard()),
          ],
        ),
      ),
      SizedBox(height: 12),
      GoToHeightCard(),
      SizedBox(height: 12),
      ClearanceCard(),
      SizedBox(height: 12),
      CurrentCard(),
      SizedBox(height: 12),
      LiveChartCard(),
      SizedBox(height: 12),
      ActionsCard(),
    ],
  );
}

/// Desktop / tablet layout: two columns.
class _WideLayout extends StatelessWidget {
  /// Creates the layout.
  const _WideLayout();

  /// Builds the two columns.
  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SizedBox(
            height: 380,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: WeightCard()),
                SizedBox(width: 16),
                SizedBox(width: 110, child: HeightCard()),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              GoToHeightCard(),
              SizedBox(height: 16),
              ClearanceCard(),
              SizedBox(height: 16),
              CurrentCard(),
              SizedBox(height: 16),
              LiveChartCard(),
              SizedBox(height: 16),
              ActionsCard(),
            ],
          ),
        ),
      ],
    ),
  );
}
