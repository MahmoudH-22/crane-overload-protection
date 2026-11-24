import '../../../core/result.dart';

/// A Bluetooth device paired with the phone (the HC-05 shows up as e.g. "HC-05" or "CRANE-MCT332").
class PairedDevice {
  /// Creates a device with [name] and MAC [address].
  const PairedDevice({required this.name, required this.address});

  /// Friendly name (may be empty).
  final String name;

  /// MAC address, e.g. `98:D3:31:F5:12:34`.
  final String address;

  /// Name if known, else the address.
  String get label => name.isNotEmpty ? name : address;
}

/// One open Bluetooth serial (SPP) connection.
abstract interface class BluetoothLink {
  /// Bytes received from the crane; done when the link closes.
  Stream<List<int>> get input;

  /// Sends [bytes]; throws when the link is closed.
  void write(List<int> bytes);

  /// Closes the link.
  Future<void> close();
}

/// Platform Bluetooth Classic access; the gateway depends on this, not on the plugin.
abstract interface class BluetoothPort {
  /// Lists paired (bonded) devices.
  ///
  /// Returns [Ok] with the devices, or [Err] with a readable reason (Bluetooth off, permission denied…).
  Future<Result<List<PairedDevice>>> pairedDevices();

  /// Opens an SPP connection to the device at [address].
  ///
  /// Returns [Ok] with the link, or [Err] with a readable reason.
  Future<Result<BluetoothLink>> open(String address);
}

/// Something that can list the phone's paired Bluetooth devices (for the connect screen).
abstract interface class PairedDeviceSource {
  /// Lists paired devices; see [BluetoothPort.pairedDevices].
  Future<Result<List<PairedDevice>>> pairedDevices();
}
