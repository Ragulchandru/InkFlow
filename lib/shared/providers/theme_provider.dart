// lib/shared/providers/theme_provider.dart
//
// ThemeModeNotifier — Riverpod provider that manages the app's ThemeMode.
//
// Key design decisions:
//   1. Persists the user's choice to Hive (settings_box) so it survives
//      app restarts without needing any async loading on the UI side.
//   2. Uses @Riverpod(keepAlive: true) so the state is never disposed
//      while the app is running — the theme must always be available.
//   3. The box is opened in main() BEFORE runApp(), so it is always
//      available synchronously when build() is called.
//
// Usage in a widget:
//   // Read current mode
//   final mode = ref.watch(themeModeNotifierProvider);
//
//   // Toggle dark/light
//   ref.read(themeModeNotifierProvider.notifier).toggle();
//
//   // Set a specific mode
//   ref.read(themeModeNotifierProvider.notifier).setMode(ThemeMode.dark);

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/app_strings.dart';

// build_runner generates the _$ThemeModeNotifier mixin in this file:
part 'theme_provider.g.dart';

/// Manages and persists the app's [ThemeMode].
///
/// State: the currently active [ThemeMode] (light, dark, or system).
/// Persistence: saved to the Hive `settings_box` under key `theme_mode`.
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  // Convenience getter — the box is already open from main().
  Box<String> get _box => Hive.box<String>(AppStrings.settingsBoxName);

  @override
  ThemeMode build() {
    // Read the persisted preference. If none exists, default to system.
    final saved = _box.get(AppStrings.themeModeSetting);
    return _fromString(saved);
  }

  /// Toggles between [ThemeMode.light] and [ThemeMode.dark].
  /// If currently on system mode, it switches to light.
  Future<void> toggle() async {
    final next =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _applyMode(next);
  }

  /// Explicitly sets the [ThemeMode] to [mode].
  Future<void> setMode(ThemeMode mode) async {
    await _applyMode(mode);
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  Future<void> _applyMode(ThemeMode mode) async {
    state = mode;
    await _box.put(AppStrings.themeModeSetting, _toString(mode));
  }

  ThemeMode _fromString(String? value) => switch (value) {
        'light'  => ThemeMode.light,
        'dark'   => ThemeMode.dark,
        _        => ThemeMode.system,
      };

  String _toString(ThemeMode mode) => switch (mode) {
        ThemeMode.light  => 'light',
        ThemeMode.dark   => 'dark',
        ThemeMode.system => 'system',
      };
}
