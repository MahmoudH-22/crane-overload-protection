/// Returns the current time; replaced in tests.
typedef Now = DateTime Function();

/// Default [Now] using the wall clock.
DateTime systemNow() => DateTime.now();

/// Formats [time] as `HH:mm:ss`.
///
/// [time]: the local time to format. Returns the formatted string.
String formatClock(DateTime time) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
}
