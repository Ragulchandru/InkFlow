// lib/main.dart
//
// Application entry point.
//
// Startup sequence (ORDER MATTERS):
//   1. WidgetsFlutterBinding.ensureInitialized()
//      Required before any async operations that use Flutter channels
//      (e.g., path_provider, Hive).
//
//   2. Hive.initFlutter()
//      Tells Hive where to store data on this device (uses path_provider
//      internally to get the documents directory).
//
//   3. Hive.openBox<String>(AppStrings.settingsBoxName)
//      Opens the settings box BEFORE runApp() so that ThemeModeNotifier
//      can read the theme preference SYNCHRONOUSLY in its build() method.
//      (Phase 1+ will open additional boxes here as features are added.)
//
//   4. runApp(ProviderScope(child: InkFlowApp()))
//      ProviderScope is required by Riverpod — it must wrap the entire
//      widget tree. All providers live inside this scope.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/app_strings.dart';

Future<void> main() async {
  // Step 1: Must be called before any async initialization.
  WidgetsFlutterBinding.ensureInitialized();

  // Step 2: Initialize Hive with the Flutter-specific path.
  await Hive.initFlutter();

  // Step 3: Open Hive boxes needed at startup.
  // The settings box stores theme mode and other app preferences.
  // It must be open BEFORE ThemeModeNotifier.build() runs.
  await Hive.openBox<String>(AppStrings.settingsBoxName);

  // Step 4: Launch the app inside Riverpod's ProviderScope.
  runApp(
    const ProviderScope(
      child: InkFlowApp(),
    ),
  );
}
