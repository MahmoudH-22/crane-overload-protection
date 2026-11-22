import 'package:crane_monitor/features/connection/data/transport_gateway.dart';
import 'package:crane_monitor/features/connection/domain/broker_settings.dart';
import 'package:crane_monitor/features/connection/domain/mqtt_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_gateway.dart';

void main() {
  test('routes connect / publish / messages to the chosen transport only', () async {
    final bt = FakeGateway(connected: false);
    final mqtt = FakeGateway(connected: false);
    final router = TransportGateway({LinkTransport.bluetooth: bt, LinkTransport.mqtt: mqtt});
    final received = <InboundMessage>[];
    router.messages.listen(received.add);

    await router.connect(BrokerSettings(transport: LinkTransport.mqtt, host: 'h', clientId: 'c'));
    expect(router.active, LinkTransport.mqtt);
    expect(router.current.isConnected, isTrue);

    router.publish('crane/cmd', '{"id":1,"cmd":"PING"}');
    expect(mqtt.commands, ['PING']);
    expect(bt.published, isEmpty);

    bt.push('crane/live', {'kg': 1});
    mqtt.push('crane/live', {'kg': 2});
    await Future<void>.delayed(Duration.zero);
    expect(received.single.payload, '{"kg":2}');

    await router.connect(BrokerSettings(btAddress: 'aa', host: 'h', clientId: 'c'));
    expect(router.active, LinkTransport.bluetooth);
    expect(mqtt.current.isConnected, isFalse);
    router.dispose();
  });
}
