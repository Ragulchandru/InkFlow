// lib/core/constants/app_sizes.dart
//
// Design tokens for all spatial and temporal values in InkFlow.
//
// Why use constants instead of magic numbers?
//   - Change the entire app's spacing by editing one file.
//   - Prevents inconsistent spacing (e.g., 15 vs 16 px).
//   - Self-documenting: AppSizes.md is clearer than the number 16.

/// Spatial design tokens: spacing, radius, icon sizes, elevations,
/// animation durations, and component sizes.
abstract final class AppSizes {
  // ─── Spacing Scale ────────────────────────────────────────────────────────
  // Based on a 4px base unit — all values are multiples of 4.
  // Use these for padding, margin, gap between widgets.

  /// 4px — micro gap (e.g., between an icon and its label).
  static const double xs = 4.0;

  /// 8px — small gap (e.g., between list items, inside chips).
  static const double sm = 8.0;

  /// 16px — standard gap (e.g., screen horizontal padding).
  static const double md = 16.0;

  /// 24px — large gap (e.g., between sections).
  static const double lg = 24.0;

  /// 32px — extra large gap (e.g., hero content spacing).
  static const double xl = 32.0;

  /// 48px — 2x large gap (e.g., empty state vertical padding).
  static const double xxl = 48.0;

  /// 64px — 3x large gap (e.g., onboarding spacing).
  static const double xxxl = 64.0;

  // ─── Border Radius Scale ──────────────────────────────────────────────────
  // Used for cards, buttons, text fields, bottom sheets, dialogs.

  /// 8px — small radius (e.g., chips, small buttons).
  static const double radiusSm = 8.0;

  /// 12px — medium radius (e.g., cards, text fields).
  static const double radiusMd = 12.0;

  /// 16px — large radius (e.g., bottom sheets, dialogs).
  static const double radiusLg = 16.0;

  /// 24px — extra large radius (e.g., FAB, pill buttons).
  static const double radiusXl = 24.0;

  /// 999px — fully rounded (e.g., avatar, circular icon button).
  static const double radiusFull = 999.0;

  // ─── Icon Sizes ───────────────────────────────────────────────────────────

  /// 16px — small icon (e.g., inline with text).
  static const double iconSm = 16.0;

  /// 24px — standard icon (e.g., AppBar actions, list tiles).
  static const double iconMd = 24.0;

  /// 32px — large icon (e.g., category headers).
  static const double iconLg = 32.0;

  /// 48px — extra large icon (e.g., empty state).
  static const double iconXl = 48.0;

  /// 80px — hero icon (e.g., onboarding illustrations).
  static const double iconHero = 80.0;

  // ─── Elevation ────────────────────────────────────────────────────────────

  /// 0dp — flat (no shadow).
  static const double elevationNone = 0.0;

  /// 1dp — subtle shadow (e.g., resting card).
  static const double elevationSm = 1.0;

  /// 3dp — moderate shadow (e.g., FAB resting).
  static const double elevationMd = 3.0;

  /// 6dp — prominent shadow (e.g., bottom sheet).
  static const double elevationLg = 6.0;

  /// 12dp — floating element (e.g., dialog).
  static const double elevationXl = 12.0;

  // ─── Animation Durations ──────────────────────────────────────────────────

  /// 150ms — micro-interactions (e.g., button press ripple).
  static const Duration durationFast = Duration(milliseconds: 150);

  /// 300ms — standard transitions (e.g., page fade, widget appear).
  static const Duration durationNormal = Duration(milliseconds: 300);

  /// 500ms — slow transitions (e.g., hero animations, list stagger).
  static const Duration durationSlow = Duration(milliseconds: 500);

  // ─── Component Sizes ─────────────────────────────────────────────────────

  /// Standard button height (follows Material 3 spec: 40–56dp).
  static const double buttonHeight = 52.0;

  /// Standard text field height.
  static const double textFieldHeight = 52.0;

  /// Standard FAB diameter.
  static const double fabSize = 56.0;

  /// Standard AppBar height.
  static const double appBarHeight = 56.0;

  /// Standard card inner padding.
  static const double cardPadding = 16.0;
}
