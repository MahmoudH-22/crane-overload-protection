import '../../../app/constants.dart';
import 'crane_state.dart';

/// Colour band of the weight gauge.
enum LoadLevel {
  /// Under 90 % of max.
  normal,

  /// 90–100 % of max.
  near,

  /// Over max, or OVERLOAD latched.
  over,
}

/// Pure gauge colour rule.
///
/// [kg]: current weight. [maxKg]: overload limit. [state]: crane state.
/// Returns the [LoadLevel] band.
LoadLevel evaluateLoadLevel({required double kg, required double maxKg, required CraneState state}) {
  if (state == CraneState.overload || kg > maxKg) return LoadLevel.over;
  if (kg >= CraneLimits.nearFraction * maxKg) return LoadLevel.near;
  return LoadLevel.normal;
}
