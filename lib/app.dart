// lib/app.dart
//
// The root widget of the InkFlow application.
//
// InkFlowApp is a ConsumerWidget (Riverpod-aware) because it needs to:
//   1. Watch the themeModeNotifierProvider to re-render when the user
//      switches between light and dark mode.
//   2. Watch the appRouterProvider to get the GoRouter instance.
//
// Why ConsumerWidget and not StatelessWidget?
//   A plain StatelessWidget cannot call ref.watch(). Riverpod's
//   ConsumerWidget gives us access to WidgetRef inside build().

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/theme_provider.dart';

/// The root widget of InkFlow.
///
/// Wires together GoRouter (navigation) + AppTheme (design) + Riverpod (state).
class InkFlowApp extends ConsumerWidget {
  const InkFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the GoRouter instance.
    // keepAlive: true ensures this provider never rebuilds unnecessarily.
    final router = ref.watch(appRouterProvider);

    // Watch the theme mode — rebuilds only when the user toggles the theme.
    final themeMode = ref.watch(themeModeNotifierProvider);

    return MaterialApp.router(
      // ── App Identity ────────────────────────────────────────────────────
      title: 'InkFlow',
      debugShowCheckedModeBanner: false,

      // ── Theme ───────────────────────────────────────────────────────────
      // Flutter picks the correct theme based on themeMode.
      // ThemeMode.system → follows the device's OS setting.
      // ThemeMode.light / ThemeMode.dark → explicit override.
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // ── Navigation ──────────────────────────────────────────────────────
      // routerConfig wires GoRouter into MaterialApp.
      // All navigation is handled declaratively through GoRouter.
      routerConfig: router,
    );
  }
}
