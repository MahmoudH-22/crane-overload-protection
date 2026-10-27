import '../domain/crane_repository.dart';
import '../domain/entities.dart';
import 'models.dart';
import 'mqtt_data_source.dart';

/// MQTT implementation of [CraneRepository].
class CraneRepositoryImpl implements CraneRepository {
  /// Creates the repository on top of [_mqtt]; topics start with [prefix].
  CraneRepositoryImpl(this._mqtt, {this.prefix = 'crane/'}) {
    // Remember the retained status even if no widget is listening yet.
    _mqtt.messages.where((m) => m.topic == _status).listen((m) => _online = _isOnline(m.payload));
  }

  final MqttDataSource _mqtt;
  final String prefix;
  bool? _online;

  String get _live => '${prefix}live';
  String get _cmd => '${prefix}cmd';
  String get _status => '${prefix}status';
  String get _events => '${prefix}events';

  /// True when a crane/status payload means online.
  bool _isOnline(String payload) => payload.trim() == 'online';

  @override
  Future<void> connect(BrokerSettings settings) =>
      _mqtt.connect(settings.host, settings.port, [_live, _status, _events]);

  @override
  Stream<CraneTelemetry> watchTelemetry() => _mqtt.messages
      .where((m) => m.topic == _live)
      .map((m) => TelemetryModel.parse(m.payload))
      .where((t) => t != null)
      .cast<CraneTelemetry>();

  @override
  Stream<bool> watchOnline() async* {
    if (_online != null) yield _online!;
    yield* _mqtt.messages.where((m) => m.topic == _status).map((m) => _isOnline(m.payload));
  }

  @override
  Stream<String> watchEvents() =>
      _mqtt.messages.where((m) => m.topic == _events).map((m) => EventModel.describe(m.payload));

  @override
  Future<void> send(CraneCommand command) async => _mqtt.publish(_cmd, CommandModel.encode(command));

  @override
  Future<void> disconnect() => _mqtt.disconnect();
}
