import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/result.dart';
import '../domain/bluetooth_port.dart';
import '../domain/broker_settings.dart';
import '../domain/connection_state.dart';
import 'connection_providers.dart';

/// Pick the crane: a paired HC-05 (Bluetooth) or a Mosquitto broker (simulator), then Connect.
class ConnectScreen extends ConsumerWidget {
  /// Creates the screen.
  const ConnectScreen({super.key});

  /// Waits for saved settings, then shows the form.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Connect to crane')),
      body: saved.when(
        data: (s) => _ConnectForm(initial: s),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ConnectForm(initial: BrokerSettings.defaults()),
      ),
    );
  }
}

/// The form itself; keeps the chosen transport, device and text controllers.
class _ConnectForm extends ConsumerStatefulWidget {
  /// Creates the form prefilled with [initial].
  const _ConnectForm({required this.initial});

  /// Settings shown when the form opens.
  final BrokerSettings initial;

  @override
  ConsumerState<_ConnectForm> createState() => _ConnectFormState();
}

class _ConnectFormState extends ConsumerState<_ConnectForm> {
  final _formKey = GlobalKey<FormState>();
  late LinkTransport _transport = widget.initial.transport;
  late PairedDevice? _device = widget.initial.btAddress.isEmpty
      ? null
      : PairedDevice(name: widget.initial.btName, address: widget.initial.btAddress);
  late final _host = TextEditingController(text: widget.initial.host);
  late final _port = TextEditingController(text: '${widget.initial.port}');
  late final _clientId = TextEditingController(text: widget.initial.clientId);

  /// Disposes the controllers.
  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _clientId.dispose();
    super.dispose();
  }

  /// Validates, connects, and opens the dashboard on success.
  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    final device = _device;
    final settings = BrokerSettings(
      transport: _transport,
      btAddress: device?.address ?? '',
      btName: device?.name ?? '',
      host: _host.text.trim(),
      port: int.tryParse(_port.text.trim()) ?? widget.initial.port,
      clientId: _clientId.text.trim().isEmpty ? randomClientId() : _clientId.text.trim(),
    );
    final result = await ref.read(connectionProvider.notifier).connect(settings);
    if (mounted && result is Ok) context.go(Routes.dashboard);
  }

  /// Builds the form.
  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(connectionProvider);
    final busy = connection.status == BrokerStatus.connecting;
    final error = connection.status == BrokerStatus.failed ? connection.error : null;
    final bluetooth = _transport == LinkTransport.bluetooth;
    final canConnect = !busy && (!bluetooth || _device != null);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.precision_manufacturing_outlined, size: 56),
                const SizedBox(height: 16),
                SegmentedButton<LinkTransport>(
                  segments: const [
                    ButtonSegment(
                      value: LinkTransport.bluetooth,
                      icon: Icon(Icons.bluetooth),
                      label: Text('Crane', overflow: TextOverflow.ellipsis),
                    ),
                    ButtonSegment(
                      value: LinkTransport.mqtt,
                      icon: Icon(Icons.wifi),
                      label: Text('Simulator', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  selected: {_transport},
                  onSelectionChanged: busy ? null : (s) => setState(() => _transport = s.first),
                ),
                const SizedBox(height: 16),
                if (bluetooth)
                  _DevicePicker(selected: _device, onSelected: (d) => setState(() => _device = d))
                else
                  _BrokerFields(host: _host, port: _port, clientId: _clientId),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: canConnect ? _connect : null,
                  icon: busy
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(bluetooth ? Icons.bluetooth_connected : Icons.link),
                  label: Text(busy ? 'Connecting…' : 'Connect'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// List of the phone's paired Bluetooth devices; tap one to pick it.
class _DevicePicker extends ConsumerWidget {
  /// Creates the picker showing [selected]; calls [onSelected] on tap.
  const _DevicePicker({required this.selected, required this.onSelected});

  /// Currently picked device (null = none).
  final PairedDevice? selected;

  /// Called with the tapped device.
  final ValueChanged<PairedDevice> onSelected;

  /// Builds the hint, the list (or its error) and a refresh button.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(pairedDevicesProvider);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pair the crane\'s HC-05 in Android Bluetooth settings first (PIN 1234 or 0000), then pick it here.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text('Paired devices', style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
            ),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(pairedDevicesProvider),
            ),
          ],
        ),
        devices.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('$e', style: TextStyle(color: theme.colorScheme.error)),
          data: (result) => switch (result) {
            Err(:final message) => Text(message, style: TextStyle(color: theme.colorScheme.error)),
            Ok(value: final list) when list.isEmpty => const Text('No paired devices. Pair the HC-05 first.'),
            Ok(value: final list) => Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final d in list)
                    ListTile(
                      leading: Icon(
                        d.address == selected?.address ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: d.address == selected?.address ? theme.colorScheme.primary : null,
                      ),
                      title: Text(d.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(d.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => onSelected(d),
                    ),
                ],
              ),
            ),
          },
        ),
        if (selected != null && devices.value is! Ok) ...[
          const SizedBox(height: 8),
          Text('Last used: ${selected!.label}', overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }
}

/// Broker host / port / client id fields (simulator over Wi-Fi).
class _BrokerFields extends StatelessWidget {
  /// Creates the fields bound to [host], [port] and [clientId].
  const _BrokerFields({required this.host, required this.port, required this.clientId});

  /// Broker host controller.
  final TextEditingController host;

  /// Broker port controller.
  final TextEditingController port;

  /// MQTT client id controller.
  final TextEditingController clientId;

  /// Builds the three fields.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Simulator: Mosquitto + crane_sim.py on the laptop, same network as this device.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: host,
          decoration: const InputDecoration(labelText: 'Broker IP / host', border: OutlineInputBorder()),
          keyboardType: TextInputType.url,
          autocorrect: false,
          validator: validateHost,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: port,
          decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          validator: validatePort,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: clientId,
          decoration: InputDecoration(
            labelText: 'Client id',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: 'New random id',
              icon: const Icon(Icons.refresh),
              onPressed: () => clientId.text = randomClientId(),
            ),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }
}

/// Validates a broker host (IPv4 or hostname).
///
/// [value]: field text. Returns an error message, or null if valid.
String? validateHost(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Required';
  final ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$').firstMatch(v);
  if (ipv4 != null) {
    final ok = List.generate(4, (i) => int.parse(ipv4.group(i + 1)!)).every((o) => o <= 255);
    return ok ? null : 'Invalid IP address';
  }
  final host = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$');
  return host.hasMatch(v) ? null : 'Invalid host name';
}

/// Validates a TCP port.
///
/// [value]: field text. Returns an error message, or null if 1–65535.
String? validatePort(String? value) {
  final port = int.tryParse(value?.trim() ?? '');
  return (port == null || port < 1 || port > 65535) ? 'Port 1–65535' : null;
}
