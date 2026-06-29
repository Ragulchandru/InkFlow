// lib/features/notes/di/notes_data_providers.dart
//
// Infrastructure dependency injection for the Notes feature.
//
// This file wires the lowest three layers of the dependency graph:
//
//   notesBoxProvider          ← reads the already-opened Hive box
//        ↓
//   noteLocalDataSourceProvider ← HiveNoteLocalDataSource
//        ↓
//   noteRepositoryProvider    ← NoteRepositoryImpl
//
// Design decisions:
//
// 1. MANUAL Provider<T> (not @riverpod code-gen).
//    These are pure wiring providers — they create an object once, inject its
//    dependencies, and never change. Code generation adds no value here and
//    would require an extra build_runner step. Manual providers are simpler,
//    more readable, and self-documenting.
//
// 2. Provider<T> (not FutureProvider<T>).
//    The Hive box is opened synchronously in main.dart before runApp, so
//    Hive.box<T>() is a synchronous call that never throws. No async handling
//    needed at the provider level.
//
// 3. ref.watch (not ref.read) inside providers.
//    ref.watch correctly tracks inter-provider dependencies in Riverpod's
//    dependency graph. Although these providers never change at runtime,
//    ref.watch is the idiomatic choice for provider-to-provider dependencies.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_strings.dart';
import '../data/datasources/hive_note_local_data_source.dart';
import '../data/datasources/note_local_data_source.dart';
import '../data/models/note_model.dart';
import '../data/repositories/note_repository_impl.dart';
import '../domain/repositories/note_repository.dart';

/// Provides the open [Box]<[NoteModel]> from Hive's global registry.
///
/// The box must already be opened before [ProviderScope] is created.
/// This happens in `main.dart`:
/// ```dart
/// await Hive.openBox<NoteModel>(AppStrings.notesBoxName);
/// runApp(const ProviderScope(child: OryntaApp()));
/// ```
///
/// [Hive.box] is synchronous and safe to call here because the box
/// is guaranteed to be open by the time any provider is first read.
final notesBoxProvider = Provider<Box<NoteModel>>(
  (ref) => Hive.box<NoteModel>(AppStrings.notesBoxName),
  name: 'notesBoxProvider',
);

/// Provides the [NoteLocalDataSource] backed by the Hive notes box.
///
/// Injects [notesBoxProvider] via constructor — [HiveNoteLocalDataSource]
/// never accesses Hive directly; it only uses the injected box.
///
/// Swapping to a different storage backend (e.g., Isar) only requires
/// replacing this provider's implementation — nothing else changes.
final noteLocalDataSourceProvider = Provider<NoteLocalDataSource>(
  (ref) => HiveNoteLocalDataSource(box: ref.watch(notesBoxProvider)),
  name: 'noteLocalDataSourceProvider',
);

/// Provides the [NoteRepository] backed by [HiveNoteLocalDataSource].
///
/// [NoteRepositoryImpl] depends only on the [NoteLocalDataSource] interface —
/// it has no knowledge of Hive, Box, or any infrastructure concern.
///
/// Use cases and notifiers read this provider, never the data source directly.
final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepositoryImpl(
    dataSource: ref.watch(noteLocalDataSourceProvider),
  ),
  name: 'noteRepositoryProvider',
);
