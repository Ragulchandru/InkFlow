// lib/core/router/app_router.dart
//
// GoRouter configuration for Orynta.
//
// Why wrap GoRouter in a Riverpod provider?
//   1. Future auth guards: the redirect callback can call
//      ref.watch(authProvider) to redirect unauthenticated users.
//   2. Testability: inject a different router in tests via ProviderScope overrides.
//   3. Consistency: everything is in Riverpod's dependency graph.
//
// @Riverpod(keepAlive: true) means this provider NEVER disposes.
// The router must persist for the entire app lifecycle.
//
// The generated file (app_router.g.dart) is created by running:
//   dart run build_runner build --delete-conflicting-outputs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notes/presentation/screens/archive_screen.dart';
import '../../features/notes/presentation/screens/note_editor_screen.dart';
import '../../features/notes/presentation/screens/trash_screen.dart';
import 'route_names.dart';

// This line tells build_runner to generate app_router.g.dart.
// The generated file contains the appRouterProvider definition.
part 'app_router.g.dart';

/// A Riverpod provider that supplies the app's [GoRouter] instance.
///
/// `keepAlive: true` ensures the router is never garbage-collected
/// as long as the ProviderScope exists.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    // Print route transitions to the debug console — useful during development.
    debugLogDiagnostics: true,

    // The route the app opens on.
    initialLocation: '/',

    routes: [
      // ── Home Screen ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        name: RouteNames.home,
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),

      // ── Note Editor — Create mode ────────────────────────────────────────────
      // Path: /notes/new
      // Opened by the FAB on the Home Screen.
      // No noteId → NoteEditorScreen runs in create mode.
      GoRoute(
        path: '/notes/new',
        name: RouteNames.noteEditor,
        builder: (BuildContext context, GoRouterState state) {
          return const NoteEditorScreen();
        },
      ),

      // ── Note Editor — Edit mode ──────────────────────────────────────────────
      // Path: /notes/:id
      // Opened by tapping a NoteCard on the Home Screen.
      // noteId param → NoteEditorScreen loads the note and runs in edit mode.
      GoRoute(
        path: '/notes/:id',
        name: RouteNames.noteDetail,
        builder: (BuildContext context, GoRouterState state) {
          final noteId = state.pathParameters['id']!;
          return NoteEditorScreen(noteId: noteId);
        },
      ),

      // ── Archive Screen ───────────────────────────────────────────────────────
      // Path: /archive
      // Opened from the Home Screen's "More" popup menu.
      // Displays all archived notes; supports restore and move-to-trash actions.
      GoRoute(
        path: '/archive',
        name: RouteNames.archive,
        builder: (BuildContext context, GoRouterState state) {
          return const ArchiveScreen();
        },
      ),

      // ── Trash Screen ─────────────────────────────────────────────────────────
      // Path: /trash
      // Opened from the Home Screen's "More" popup menu.
      // Displays all trashed notes; supports restore action only (Phase 3 Step 1).
      GoRoute(
        path: '/trash',
        name: RouteNames.trash,
        builder: (BuildContext context, GoRouterState state) {
          return const TrashScreen();
        },
      ),
    ],

    // Shown when the user navigates to an unknown route.
    errorBuilder: (BuildContext context, GoRouterState state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Text(
            'No route found for: ${state.uri}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    },
  );
}
