import 'package:go_router/go_router.dart';

import '../features/connection/presentation/connect_screen.dart';
import '../features/events/presentation/events_screen.dart';
import '../features/telemetry/presentation/dashboard_screen.dart';

/// Route paths.
abstract final class Routes {
  /// Broker settings / connect.
  static const connect = '/';

  /// Main dashboard.
  static const dashboard = '/dashboard';

  /// Event log.
  static const events = '/dashboard/events';
}

/// Builds the app router.
GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.connect,
  routes: [
    GoRoute(path: Routes.connect, builder: (_, _) => const ConnectScreen()),
    GoRoute(
      path: Routes.dashboard,
      builder: (_, _) => const DashboardScreen(),
      routes: [GoRoute(path: 'events', builder: (_, _) => const EventsScreen())],
    ),
  ],
);
