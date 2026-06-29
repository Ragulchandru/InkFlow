// lib/core/constants/app_colors.dart
//
// Centralized color palette for Orynta.
//
// Rule: Raw color values live here. The actual Material 3 ColorScheme
// is generated in AppTheme via ColorScheme.fromSeed(). Widgets should
// always use theme.colorScheme.* values — only reference AppColors
// directly for brand-specific values like noteColors.

import 'package:flutter/material.dart';

/// Brand and palette color constants for Orynta.
abstract final class AppColors {
  // ─── Brand / Seed ─────────────────────────────────────────────────────────
  /// The single seed color from which Material 3 generates the entire
  /// tonal palette (primary, secondary, tertiary, surface tints, etc.).
  /// Deep Indigo — evokes creativity, focus, and trust.
  static const Color seedColor = Color(0xFF3D2C8D);

  // ─── Explicit Surface Overrides ───────────────────────────────────────────
  /// Light mode surface — slightly warm white (avoids harsh pure white).
  static const Color surfaceLight = Color(0xFFFCFBFF);

  /// Dark mode surface — deep charcoal (avoids harsh pure black).
  static const Color surfaceDark = Color(0xFF141218);

  // ─── Status / Semantic Colors ─────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57F17);
  static const Color error   = Color(0xFFB00020);
  static const Color info    = Color(0xFF01579B);

  // ─── Note Background Colors (stored as ARGB int in Hive) ─────────────────
  // These are the 8 curated pastel tones available for note backgrounds.
  // They are stored in the database as int (ARGB) and displayed via Color(int).
  //
  // Example:
  //   int colorValue = note.color ?? AppColors.noteColorDefault;
  //   Color displayColor = Color(colorValue);

  /// No tint — uses the theme's default card surface color.
  static const int noteColorDefault  = 0xFFFFFFFF;

  /// Soft purple — calm, creative.
  static const int noteColorLavender = 0xFFD0BCFF;

  /// Mint green — fresh, organized.
  static const int noteColorMint     = 0xFFB5EAD7;

  /// Warm peach — energetic, warm.
  static const int noteColorPeach    = 0xFFFFDAB9;

  /// Soft yellow — cheerful, light.
  static const int noteColorButter   = 0xFFFFF9C4;

  /// Blush pink — gentle, personal.
  static const int noteColorRose     = 0xFFFFB3BA;

  /// Sky blue — clear, focused.
  static const int noteColorSky      = 0xFFC7E0F4;

  /// Warm sand — earthy, grounded.
  static const int noteColorSand     = 0xFFE8D5C4;

  /// All note colors in display order (for the color picker widget).
  static const List<int> noteColors = [
    noteColorDefault,
    noteColorLavender,
    noteColorMint,
    noteColorPeach,
    noteColorButter,
    noteColorRose,
    noteColorSky,
    noteColorSand,
  ];

  // ─── Transparency ─────────────────────────────────────────────────────────
  static const Color transparent = Colors.transparent;
}
