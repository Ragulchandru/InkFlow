// lib/core/theme/app_text_styles.dart
//
// Material 3 full type scale using Google Fonts.
//
// Font choices:
//   - Inter (body, labels, titles): Humanist sans-serif. Extremely legible
//     at all sizes. Used in Figma, Linear, Notion — a modern standard.
//   - Playfair Display (display headings): Transitional serif. Elegant,
//     editorial feel that differentiates InkFlow's brand.
//
// Usage:
//   Text('Hello', style: Theme.of(context).textTheme.titleMedium)
//
// You should ALWAYS read text styles from Theme.of(context).textTheme,
// not from this class directly. This class populates the ThemeData;
// reading from the theme ensures the color is always correct for
// light/dark mode.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Defines the full Material 3 type scale for InkFlow.
///
/// Used exclusively in [AppTheme._buildTheme] to populate [ThemeData.textTheme].
abstract final class AppTextStyles {
  // ─── Display (Hero / Editorial headings) ──────────────────────────────────

  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
      );

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
      );

  static TextStyle get displaySmall => GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
      );

  // ─── Headline (Screen/section titles) ─────────────────────────────────────

  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.29,
      );

  static TextStyle get headlineSmall => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
      );

  // ─── Title (Card titles, dialogs, app bars) ───────────────────────────────

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.27,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.50,
      );

  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      );

  // ─── Body (Primary reading text) ──────────────────────────────────────────

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.50,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      );

  // ─── Label (Buttons, chips, captions, tabs) ───────────────────────────────

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.33,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.45,
      );
}
