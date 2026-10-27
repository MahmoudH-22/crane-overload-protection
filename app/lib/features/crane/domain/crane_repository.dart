import 'entities.dart';

/// Contract between the UI and the crane, independent of the transport.
abstract interface class CraneRepository {
  /// Connects to the broker in [settings]. Throws when the connection fails.
  Future<void> connect(BrokerSettings settings);

  /// Emits each telemetry snapshot from crane/live.
  Stream<CraneTelemetry> watchTelemetry();

  /// Emits true/false from crane/status (MQTT Last Will), starting with the last known value.
  Stream<bool> watchOnline();

  /// Emits alarm and rejection events from crane/events as short text.
  Stream<String> watchEvents();

  /// Sends [command] to crane/cmd. Throws when not connected.
  Future<void> send(CraneCommand command);

  /// Closes the connection.
  Future<void> disconnect();
}
