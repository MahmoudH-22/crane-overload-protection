import 'package:freezed_annotation/freezed_annotation.dart';

part 'command_ack.freezed.dart';
part 'command_ack.g.dart';

/// A `crane/ack` reply.
@freezed
abstract class CommandAck with _$CommandAck {
  /// Creates an ack for command [id].
  const factory CommandAck({required int id, required bool ok, String? reason}) = _CommandAck;

  const CommandAck._();

  /// Decodes a `crane/ack` JSON object.
  factory CommandAck.fromJson(Map<String, Object?> json) => _$CommandAckFromJson(json);

  /// Human text for a refusal reason.
  String get reasonText => switch (reason) {
    'OVERLOAD' => 'Refused: overload. Lower the load first.',
    'JAM' => 'Refused: motor jam. RESET first.',
    'TOP' => 'Refused: hook is at the top.',
    'ESTOP' => 'Refused: E-stop is pressed.',
    'LOCAL_MODE' => 'Refused: crane is in LOCAL mode (panel key).',
    'BUSY' => 'Refused: crane is busy.',
    'OBSTACLE' => 'Refused: something is under the load.',
    'NOT_FITTED' => 'Refused: that part is not connected to the crane yet.',
    'RANGE' => 'Refused: value out of range.',
    null => 'Command refused.',
    final other => 'Refused: $other.',
  };
}
