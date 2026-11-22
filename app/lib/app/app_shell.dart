import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/control/presentation/control_providers.dart';
import '../features/events/presentation/events_providers.dart';
import '../features/telemetry/presentation/telemetry_providers.dart';

/// Wraps every route: keeps the data providers alive, sends STOP when the app
/// leaves the foreground, and vibrates when an alert starts.
class AppShell extends ConsumerStatefulWidget {
  /// Wraps [child] (the router's page).
  const AppShell({super.key, required this.child});

  /// Current page.
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final AppLifecycleListener _lifecycle;

  /// Registers the lifecycle listener.
  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
  }

  /// Removes the lifecycle listener.
  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Stops held motion when the app is no longer in the foreground.
  void _onLifecycle(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      ref.read(controlProvider.notifier).onAppBackground();
    }
  }

  /// Keeps providers alive and reacts to alerts; renders [AppShell.child].
  @override
  Widget build(BuildContext context) {
    ref.listen(eventsProvider, (_, _) {});
    ref.listen(telemetryProvider, (_, _) {});
    ref.listen(controlProvider, (_, _) {});
    ref.listen(alertProvider, (previous, next) {
      if (next != null && next != previous) HapticFeedback.vibrate();
    });
    return widget.child;
  }
}
