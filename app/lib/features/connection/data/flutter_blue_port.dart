import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';

import '../../../core/logger.dart';
import '../../../core/result.dart';
import '../domain/bluetooth_port.dart';

const _log = Log('bt-port');

/// [BluetoothPort] backed by the `flutter_blue_classic` plugin (Android only).
///
/// The plugin asks for the Android 12+ Bluetooth permissions itself the first time they are needed.
class FlutterBluePort implements BluetoothPort {
  /// Creates the port; the plugin is only touched on first use.
  FlutterBluePort();

  FlutterBlueClassic? _blue;

  /// The plugin instance, created lazily.
  FlutterBlueClassic get _plugin => _blue ??= FlutterBlueClassic();

  /// Lists bonded Bluetooth Classic devices.
  @override
  Future<Result<List<PairedDevice>>> pairedDevices() async {
    final ready = await _ready();
    if (ready != null) return Err(ready);
    try {
      final devices = await _plugin.bondedDevices ?? const <BluetoothDevice>[];
      return Ok([for (final d in devices) PairedDevice(name: d.name ?? '', address: d.address)]);
    } on PlatformException catch (e) {
      _log.e('bondedDevices', e);
      return Err(_describe(e), e);
    }
  }

  /// Opens an SPP link to [address].
  @override
  Future<Result<BluetoothLink>> open(String address) async {
    final ready = await _ready();
    if (ready != null) return Err(ready);
    try {
      final conn = await _plugin.connect(address);
      if (conn == null || !conn.isConnected) {
        return Err('Could not connect to $address. Is the crane powered and the HC-05 LED blinking?');
      }
      return Ok(_PluginLink(conn));
    } on PlatformException catch (e) {
      _log.e('connect $address', e);
      return Err(_describe(e), e);
    }
  }

  /// Checks platform support and that Bluetooth is on.
  ///
  /// Returns null when ready, otherwise a readable reason.
  Future<String?> _ready() async {
    if (kIsWeb || !Platform.isAndroid) {
      return 'Bluetooth works in the Android app only. On desktop use Wi-Fi with the simulator.';
    }
    try {
      if (!await _plugin.isSupported) return 'This phone has no Bluetooth.';
      if (!await _plugin.isEnabled) return 'Bluetooth is off. Turn it on and try again.';
    } on PlatformException catch (e) {
      return _describe(e);
    }
    return null;
  }

  /// Turns a plugin error into a message the user can act on.
  String _describe(PlatformException e) {
    final text = '${e.code} ${e.message}'.toLowerCase();
    if (text.contains('permission')) return 'Bluetooth permission denied. Allow "Nearby devices" for the app.';
    if (text.contains('socket') || text.contains('connect')) {
      return 'Could not connect. Is the crane powered, the HC-05 paired and not used by another phone?';
    }
    return 'Bluetooth error: ${e.message ?? e.code}';
  }
}

/// [BluetoothLink] wrapping a plugin connection.
class _PluginLink implements BluetoothLink {
  /// Wraps [_conn].
  _PluginLink(this._conn);

  final BluetoothConnection _conn;

  /// Received bytes (empty stream if the plugin gave none).
  @override
  Stream<List<int>> get input => _conn.input ?? const Stream<List<int>>.empty();

  /// Sends [bytes]; throws [StateError] when the link is closed.
  @override
  void write(List<int> bytes) {
    if (!_conn.isConnected) throw StateError('Bluetooth link closed');
    _conn.output.add(Uint8List.fromList(bytes));
  }

  /// Closes the link after queued writes (e.g. the STOP sent on disconnect) are out, at most 1 s later.
  @override
  Future<void> close() => _conn.finish().timeout(const Duration(seconds: 1), onTimeout: _conn.close);
}
