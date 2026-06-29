// lib/main.dart
//
// Application entry point.
//
// Startup sequence (ORDER MATTERS):
//   1. WidgetsFlutterBinding.ensureInitialized()
//      Required before any async operations that use Flutter channels.
//
//   2. Hive.initFlutter()
//      Tells Hive where to store data on this device.
//
//   3. Hive.registerAdapter(...)
//      Register all TypeAdapters BEFORE opening any box.
//      Hive reads the adapter when deserializing existing data from disk —
//      if the adapter isn't registered, Hive throws HiveError at box open.
//
//   4. Hive.openBox(...)
//      Open boxes needed at startup BEFORE runApp().
//      The settings box must be open for ThemeModeNotifier (synchronous read).
//      The notes box must be open for NotesProvider (Phase 1 onward).
//
//   5. runApp(ProviderScope(child: OryntaApp()))
//      ProviderScope is Riverpod's root container.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/app_strings.dart';
import 'features/notes/data/models/note_model.dart';
import 'features/notes/data/models/note_type_adapter.dart';

Future<void> main() async {
  // Step 1
  WidgetsFlutterBinding.ensureInitialized();

  // Step 2
  await Hive.initFlutter();

  // Step 3 — Register all TypeAdapters before opening any box.
  // Add new adapters here as new features are implemented.
  Hive.registerAdapter(NoteTypeAdapter());

  // Step 4 — Open Hive boxes needed at app startup.
  await Future.wait([
    Hive.openBox<String>(AppStrings.settingsBoxName),
    Hive.openBox<NoteModel>(AppStrings.notesBoxName),
  ]);

  // Step 5 — Launch the app.
  runApp(
    const ProviderScope(
      child: OryntaApp(),
    ),
  );
}
