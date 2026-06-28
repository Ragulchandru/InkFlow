// lib/core/router/app_router.dart
//
// GoRouter configuration for InkFlow.
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
      // ── Phase 0 placeholder ────────────────────────────────────────────────
      // In Phase 1 this will be replaced with the NotesScreen ShellRoute.
      GoRoute(
        path: '/',
        name: RouteNames.home,
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),

      // ── Phase 1+ routes will be added here ────────────────────────────────
      // Example (commented out — do not uncomment until Phase 1):
      //
      // ShellRoute(
      //   builder: (context, state, child) => AppShell(child: child),
      //   routes: [
      //     GoRoute(path: '/notes', name: RouteNames.notes, ...),
      //     GoRoute(path: '/search', name: RouteNames.search, ...),
      //     GoRoute(path: '/settings', name: RouteNames.settings, ...),
      //   ],
      // ),
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
