import 'package:flutter/material.dart';

import '../features/telemetry/domain/crane_state.dart';
import '../features/telemetry/domain/link_health.dart';
import '../features/telemetry/domain/load_level.dart';

/// Semantic status colours (green / amber / red / blue / grey), per brightness.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  /// Creates the palette.
  const StatusColors({
    required this.ok,
    required this.warn,
    required this.danger,
    required this.info,
    required this.idle,
    required this.onDanger,
  });

  /// Light-theme palette.
  static const light = StatusColors(
    ok: Color(0xFF2E7D32),
    warn: Color(0xFFB26A00),
    danger: Color(0xFFC62828),
    info: Color(0xFF1565C0),
    idle: Color(0xFF607D8B),
    onDanger: Colors.white,
  );

  /// Dark-theme palette.
  static const dark = StatusColors(
    ok: Color(0xFF66BB6A),
    warn: Color(0xFFFFB300),
    danger: Color(0xFFEF5350),
    info: Color(0xFF64B5F6),
    idle: Color(0xFF90A4AE),
    onDanger: Colors.white,
  );

  /// Healthy / normal.
  final Color ok;

  /// Warning / near limit / stale.
  final Color warn;

  /// Fault / overload / offline.
  final Color danger;

  /// Motion in progress.
  final Color info;

  /// Neutral idle.
  final Color idle;

  /// Text on [danger].
  final Color onDanger;

  /// Colour of the state chip for [state].
  Color forState(CraneState state) => switch (state) {
    CraneState.idle => idle,
    CraneState.lifting || CraneState.lowering => info,
    CraneState.top => warn,
    CraneState.overload || CraneState.jam || CraneState.estop => danger,
    CraneState.unknown => idle,
  };

  /// Colour of the connection badge for [health].
  Color forHealth(LinkHealth health) => switch (health) {
    LinkHealth.ok => ok,
    LinkHealth.stale => warn,
    LinkHealth.offline || LinkHealth.disconnected => danger,
  };

  /// Colour of the weight gauge for [level].
  Color forLoad(LoadLevel level) => switch (level) {
    LoadLevel.normal => ok,
    LoadLevel.near => warn,
    LoadLevel.over => danger,
  };

  @override
  StatusColors copyWith({Color? ok, Color? warn, Color? danger, Color? info, Color? idle, Color? onDanger}) =>
      StatusColors(
        ok: ok ?? this.ok,
        warn: warn ?? this.warn,
        danger: danger ?? this.danger,
        info: info ?? this.info,
        idle: idle ?? this.idle,
        onDanger: onDanger ?? this.onDanger,
      );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      ok: Color.lerp(ok, other.ok, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      idle: Color.lerp(idle, other.idle, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
    );
  }
}

/// Shortcut: `context.status` returns the theme's [StatusColors].
extension StatusColorsContext on BuildContext {
  /// The active [StatusColors].
  StatusColors get status => Theme.of(this).extension<StatusColors>() ?? StatusColors.light;
}

const _seed = Color(0xFF1C2B39);

/// Builds the light or dark theme for [brightness].
ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    extensions: [brightness == Brightness.dark ? StatusColors.dark : StatusColors.light],
    cardTheme: const CardThemeData(margin: EdgeInsets.zero),
  );
}
