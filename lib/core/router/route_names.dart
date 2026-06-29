// lib/core/router/route_names.dart
//
// Named route constants for GoRouter.
//
// Why use constants?
//   GoRouter routes are identified by name when navigating:
//     context.goNamed(RouteNames.home)
//
//   If we used string literals ('home', 'notes', etc.) in every file,
//   a single typo would cause a runtime error with no compile-time warning.
//   Constants give us compile-time safety — a typo becomes a missing symbol.

/// Named route identifiers for Orynta's navigation graph.
abstract final class RouteNames {
  // ─── Phase 0 ──────────────────────────────────────────────────────────────
  /// Placeholder home screen (replaced by NotesScreen in Phase 1).
  static const String home = 'home';

  // ─── Phase 1 (Notes) ──────────────────────────────────────────────────────
  /// Full list of notes (active).
  static const String notes = 'notes';

  /// Detail/reader view of a single note.
  static const String noteDetail = 'note-detail';

  /// Create or edit a note (same screen, different modes).
  static const String noteEditor = 'note-editor';

  /// Archived notes list.
  static const String archive = 'archive';

  /// Trash / deleted notes list.
  static const String trash = 'trash';

  // ─── Phase 2 (Organization) ───────────────────────────────────────────────
  /// Global search screen.
  static const String search = 'search';

  /// Categories list screen.
  static const String categories = 'categories';

  /// Notes filtered by a single category.
  static const String categoryDetail = 'category-detail';

  /// Tags list screen.
  static const String tags = 'tags';

  // ─── Phase 3+ (Settings, Auth, etc.) ─────────────────────────────────────
  /// App settings screen.
  static const String settings = 'settings';

  /// User profile screen (Phase 6 — Firebase).
  static const String profile = 'profile';

  /// Login screen (Phase 6 — Firebase).
  static const String login = 'login';
}
