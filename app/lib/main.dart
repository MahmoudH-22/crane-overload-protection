import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/app_shell.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/logger.dart';

const _log = Log('app');

/// Starts the app inside a Riverpod scope, with global error logging.
void main() {
  // Async errors nobody awaited (e.g. from the MQTT socket after the phone was locked) are logged
  // instead of being reported as unhandled; the connection layer already reconnects by itself.
  WidgetsFlutterBinding.ensureInitialized().platformDispatcher.onError = (error, stack) {
    _log.e('uncaught async error', '$error\n$stack');
    return true;
  };
  runApp(const ProviderScope(child: CraneApp()));
}

/// Root widget: router, light / dark theme and the [AppShell].
class CraneApp extends StatefulWidget {
  /// Creates the app.
  const CraneApp({super.key});

  @override
  State<CraneApp> createState() => _CraneAppState();
}

class _CraneAppState extends State<CraneApp> {
  final GoRouter _router = buildRouter();

  /// Disposes the router.
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  /// Builds the MaterialApp.
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Crane Overload',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    routerConfig: _router,
    builder: (_, child) => AppShell(child: child ?? const SizedBox.shrink()),
  );
}
