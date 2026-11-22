import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/constants.dart';
import 'time_utils.dart';

/// Current-time source; override in tests.
final clockProvider = Provider<Now>((ref) => systemNow);

/// Ticks every [Timing.uiTick] so time-based rules (staleness) re-evaluate.
final tickerProvider = StreamProvider<DateTime>((ref) {
  final now = ref.watch(clockProvider);
  return Stream.periodic(Timing.uiTick, (_) => now());
});
