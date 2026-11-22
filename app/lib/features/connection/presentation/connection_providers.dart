import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../../control/presentation/control_providers.dart';
import '../data/bluetooth_gateway.dart';
import '../data/flutter_blue_port.dart';
import '../data/mqtt_service.dart';
import '../data/prefs_settings_repository.dart';
import '../data/transport_gateway.dart';
import '../domain/bluetooth_port.dart';
import '../domain/broker_settings.dart';
import '../domain/connection_state.dart';
import '../domain/mqtt_gateway.dart';
import '../domain/settings_repository.dart';

/// The HC-05 Bluetooth link (the real crane). Owned and disposed by [mqttGatewayProvider].
final bluetoothGatewayProvider = Provider<BluetoothGateway>((ref) => BluetoothGateway(FlutterBluePort()));

/// The app's single crane link: Bluetooth (HC-05) or MQTT (simulator), chosen on the connect screen.
///
/// Every repository depends on this; it speaks the MQTT contract's topics + JSON whatever the transport.
final mqttGatewayProvider = Provider<MqttGateway>((ref) {
  final gateway = TransportGateway({
    LinkTransport.bluetooth: ref.watch(bluetoothGatewayProvider),
    LinkTransport.mqtt: MqttService(),
  });
  ref.onDispose(gateway.dispose);
  return gateway;
});

/// Lists the phone's paired Bluetooth devices for the connect screen.
final pairedDeviceSourceProvider = Provider<PairedDeviceSource>((ref) => ref.watch(bluetoothGatewayProvider));

/// Paired devices (refresh with `ref.invalidate`).
final pairedDevicesProvider = FutureProvider.autoDispose<Result<List<PairedDevice>>>(
  (ref) => ref.watch(pairedDeviceSourceProvider).pairedDevices(),
);

/// Persistent connection settings.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => const PrefsSettingsRepository());

/// Settings saved by the last successful connect (or defaults).
final savedSettingsProvider = FutureProvider<BrokerSettings>((ref) => ref.watch(settingsRepositoryProvider).load());

/// Current crane link state and the connect / disconnect actions.
final connectionProvider = NotifierProvider<ConnectionController, BrokerConnection>(ConnectionController.new);

/// Exposes the gateway's link state to the UI and runs connect / disconnect.
class ConnectionController extends Notifier<BrokerConnection> {
  /// Subscribes to gateway state changes; returns the current snapshot.
  @override
  BrokerConnection build() {
    final gateway = ref.watch(mqttGatewayProvider);
    final sub = gateway.states.listen((s) => state = s);
    ref.onDispose(sub.cancel);
    return gateway.current;
  }

  /// Saves [settings] and connects.
  ///
  /// Returns [Ok] when connected, otherwise [Err] with a readable reason.
  Future<Result<void>> connect(BrokerSettings settings) async {
    final result = await ref.read(mqttGatewayProvider).connect(settings);
    if (result.isOk) {
      await ref.read(settingsRepositoryProvider).save(settings);
      ref.invalidate(savedSettingsProvider);
    }
    return result;
  }

  /// Stops any held motion (sends STOP) and disconnects.
  Future<void> disconnect() async {
    ref.read(commandRepositoryProvider).releaseHold();
    await ref.read(mqttGatewayProvider).disconnect();
  }
}
