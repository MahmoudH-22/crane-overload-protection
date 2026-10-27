import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/crane/presentation/dashboard_screen.dart';

/// Starts the app inside a Riverpod scope.
void main() => runApp(const ProviderScope(child: CraneApp()));

/// Root widget: Material 3 light and dark themes, dashboard as home.
class CraneApp extends StatelessWidget {
  /// Creates the app.
  const CraneApp({super.key});

  /// Builds the MaterialApp.
  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1C2B39);
    return MaterialApp(
      title: 'Crane monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark, useMaterial3: true),
      home: const DashboardScreen(),
    );
  }
}
