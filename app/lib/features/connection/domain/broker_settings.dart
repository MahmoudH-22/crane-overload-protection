import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../app/constants.dart';

part 'broker_settings.freezed.dart';
part 'broker_settings.g.dart';

/// How the app reaches the crane.
enum LinkTransport {
  /// HC-05 on the Uno, Bluetooth Classic serial (the real crane, Android only).
  bluetooth,

  /// Mosquitto broker over Wi-Fi (the simulator `tools/crane_sim.py`, desktop development).
  mqtt,
}

/// Where to find the crane: a paired HC-05 (Bluetooth) or a Mosquitto broker (simulator).
@freezed
abstract class BrokerSettings with _$BrokerSettings {
  /// Creates settings for [transport]: Bluetooth [btAddress] / [btName], or broker [host]:[port] with [clientId].
  const factory BrokerSettings({
    @Default(LinkTransport.bluetooth) LinkTransport transport,

    /// MAC address of the paired HC-05, e.g. `98:D3:31:F5:12:34`.
    @Default('') String btAddress,

    /// Name of the paired HC-05 (shown in the UI).
    @Default('') String btName,
    required String host,
    @Default(BrokerDefaults.port) int port,
    required String clientId,
  }) = _BrokerSettings;

  const BrokerSettings._();

  /// Decodes settings saved as JSON.
  factory BrokerSettings.fromJson(Map<String, Object?> json) => _$BrokerSettingsFromJson(json);

  /// Default settings (Bluetooth, no device picked yet) with a fresh random client id.
  factory BrokerSettings.defaults() => BrokerSettings(host: BrokerDefaults.host, clientId: randomClientId());

  /// Short description of the target for messages, e.g. "HC-05" or "192.168.43.10:1883".
  String get targetLabel => switch (transport) {
    LinkTransport.bluetooth => btName.isNotEmpty ? btName : btAddress,
    LinkTransport.mqtt => '$host:$port',
  };
}

/// Returns a client id of the form `crane-app-1234`.
///
/// [random]: optional source of randomness (tests).
String randomClientId([Random? random]) {
  final r = random ?? Random();
  return 'crane-app-${(r.nextInt(9000) + 1000)}';
}
