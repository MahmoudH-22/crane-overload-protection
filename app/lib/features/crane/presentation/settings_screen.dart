import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities.dart';
import 'providers.dart';

/// The rated load from the stress analysis; the app never allows more.
const double kRatedMaxKg = 2.0;

/// Broker settings, overload limit and load cell calibration.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _host = TextEditingController();
  final _port = TextEditingController();
  final _known = TextEditingController(text: '1.000');
  double _maxKg = kRatedMaxKg;
  bool _loaded = false;

  /// Frees the text controllers.
  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _known.dispose();
    super.dispose();
  }

  /// Sends [command] and confirms or reports an error.
  Future<void> _send(CraneCommand command, String done) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(repositoryProvider).send(command);
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Not sent: $e')));
    }
  }

  /// Asks the user to confirm before an action that changes calibration.
  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('OK')),
          ],
        ),
      ) ??
      false;

  /// Saves the broker host and port; the app reconnects.
  Future<void> _saveBroker() async {
    final port = int.tryParse(_port.text.trim());
    if (_host.text.trim().isEmpty || port == null) return;
    await ref.read(settingsProvider.notifier).save(BrokerSettings(host: _host.text.trim(), port: port));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved, reconnecting…')));
  }

  /// Builds the form, filling it once with the saved settings and the live max load.
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final t = ref.watch(telemetryProvider).valueOrNull;
    if (!_loaded && settings != null) {
      _host.text = settings.host;
      _port.text = '${settings.port}';
      if (t != null && t.maxKg > 0) _maxKg = t.maxKg.clamp(0.5, kRatedMaxKg).toDouble();
      _loaded = true;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('MQTT broker', style: Theme.of(context).textTheme.titleMedium),
        TextField(controller: _host, decoration: const InputDecoration(labelText: 'Host (laptop IP)')),
        TextField(controller: _port, decoration: const InputDecoration(labelText: 'Port'), keyboardType: TextInputType.number),
        const SizedBox(height: 8),
        FilledButton(onPressed: _saveBroker, child: const Text('Save and reconnect')),
        const Divider(height: 32),
        Text('Overload limit: ${_maxKg.toStringAsFixed(1)} kg (rated ${kRatedMaxKg.toStringAsFixed(1)} kg)',
            style: Theme.of(context).textTheme.titleMedium),
        Slider(
          value: _maxKg,
          min: 0.5,
          max: kRatedMaxKg,
          divisions: ((kRatedMaxKg - 0.5) * 10).round(),
          label: '${_maxKg.toStringAsFixed(1)} kg',
          onChanged: (v) => setState(() => _maxKg = v),
        ),
        OutlinedButton(
          onPressed: () => _send(CraneCommand(CraneCommandType.max, _maxKg), 'Max load sent'),
          child: const Text('Apply max load'),
        ),
        const Divider(height: 32),
        Text('Calibration', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            if (await _confirm('Tare', 'Is the hook empty and still?')) {
              await _send(const CraneCommand(CraneCommandType.tare), 'Tare sent');
            }
          },
          child: const Text('Tare (empty hook = 0 kg)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _known,
          decoration: const InputDecoration(labelText: 'Known weight on the hook (kg)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            final kg = double.tryParse(_known.text.trim());
            if (kg == null || kg <= 0) return;
            if (await _confirm('Calibrate', 'Is exactly ${kg.toStringAsFixed(3)} kg hanging still?')) {
              await _send(CraneCommand(CraneCommandType.cal, kg), 'Calibration sent');
            }
          },
          child: const Text('Calibrate with known weight'),
        ),
        const SizedBox(height: 8),
        Text('Calibration is saved on the Uno (EEPROM), so it survives power cycles.',
            style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
