import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities.dart';
import 'load_gauge.dart';
import 'providers.dart';
import 'settings_screen.dart';

/// Main screen: live load, status, and Lift / Lower / Stop / Reset controls.
class DashboardScreen extends ConsumerWidget {
  /// Creates the dashboard.
  const DashboardScreen({super.key});

  /// Builds the connection states and, when connected, the live dashboard.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionProvider);
    final online = ref.watch(onlineProvider).valueOrNull ?? false;
    final t = ref.watch(telemetryProvider).valueOrNull;
    final now = ref.watch(clockProvider).valueOrNull ?? DateTime.now();
    final stale = t == null || now.difference(t.receivedAt).inMilliseconds > 2000;

    ref.listen(eventsProvider, (_, next) {
      final msg = next.valueOrNull;
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crane monitor'),
        actions: [
          _StatusChip(online: online && !stale),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: connection.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: '$e', onRetry: () => ref.invalidate(connectionProvider)),
        data: (_) => t == null
            ? const Center(child: Text('Connected. Waiting for crane data…'))
            : _Body(t: t, stale: stale),
      ),
    );
  }
}

/// Live content: alert banner, gauge, status cards and controls.
class _Body extends ConsumerWidget {
  const _Body({required this.t, required this.stale});

  final CraneTelemetry t;
  final bool stale;

  /// Sends [command] and shows a snackbar if it could not be sent.
  Future<void> _send(BuildContext context, WidgetRef ref, CraneCommand command) async {
    try {
      await ref.read(repositoryProvider).send(command);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not sent: $e')));
      }
    }
  }

  /// Builds the dashboard body from the latest telemetry [t].
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final state = t.state.name.toUpperCase();
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (t.isFault) _Banner(text: _faultText(t), color: scheme.error),
      if (stale) const _Banner(text: 'No data for 2 s: check the crane and Wi-Fi', color: Colors.orange),
      LoadGauge(kg: t.kg, maxKg: t.maxKg, alarm: t.isFault, warn: t.nearLimit),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          _InfoCard(label: 'Status', value: state, color: t.isFault ? scheme.error : scheme.primary),
          _InfoCard(label: 'Hook height', value: _hookText(t)),
          _InfoCard(label: 'Motor current', value: '${t.amps.toStringAsFixed(2)} A'),
          _InfoCard(label: 'Near limit', value: t.nearLimit ? 'YES (≥ 90%)' : 'no'),
          _InfoCard(
            label: 'Encoder',
            value: !t.homed ? 'lift to top to home' : t.encoderErrors ? 'CHECK (noisy edges)' : 'OK',
            color: t.encoderErrors ? Colors.orange : null,
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: t.liftBlocked || stale ? null : () => _send(context, ref, const CraneCommand(CraneCommandType.up)),
            icon: const Icon(Icons.arrow_upward),
            label: const Text('LIFT'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: t.state == CraneState.jam || t.state == CraneState.eStop || stale
                ? null
                : () => _send(context, ref, const CraneCommand(CraneCommandType.down)),
            icon: const Icon(Icons.arrow_downward),
            label: const Text('LOWER'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
            onPressed: () => _send(context, ref, const CraneCommand(CraneCommandType.stop)),
            icon: const Icon(Icons.stop),
            label: const Text('STOP'),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: t.isFault ? () => _send(context, ref, const CraneCommand(CraneCommandType.reset)) : null,
        child: const Text('Reset alarm'),
      ),
    ]);
  }

  /// Hook position text: AT TOP, height in mm once homed, or a homing hint.
  String _hookText(CraneTelemetry t) {
    if (t.atTop) return 'AT TOP';
    final h = t.heightMm;
    return t.homed && h != null ? '${h.round()} mm' : 'not homed';
  }

  /// Explains the active fault in plain words.
  String _faultText(CraneTelemetry t) => switch (t.state) {
        CraneState.overload =>
          'OVERLOAD: ${t.kg.toStringAsFixed(2)} kg > ${t.maxKg.toStringAsFixed(2)} kg. Lower the load, then reset.',
        CraneState.jam => 'MOTOR JAM (high current or no encoder motion): check the rope and drum, then reset.',
        CraneState.eStop => 'E-STOP pressed: release it, then reset.',
        _ => 'Fault',
      };
}

/// Green ONLINE / red OFFLINE chip for the app bar.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.online});

  final bool online;

  /// Builds the chip.
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Chip(
          label: Text(online ? 'ONLINE' : 'OFFLINE'),
          backgroundColor: online ? Colors.green.shade600 : Colors.red.shade600,
          labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          side: BorderSide.none,
        ),
      );
}

/// Coloured full-width message.
class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});

  final String text;
  final Color color;

  /// Builds the banner.
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      );
}

/// Small label/value card.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  /// Builds the card.
  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

/// Connection error with a retry button.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  /// Builds the error view.
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
        ),
      );
}
