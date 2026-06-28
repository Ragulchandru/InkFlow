// lib/core/constants/app_strings.dart
//
// All hardcoded strings are centralized here.
// Benefits:
//   1. Easy to find and update any string in one place.
//   2. Required for localization (l10n) when we add multi-language support.
//   3. No magic strings scattered across the codebase.

/// App-wide string constants for InkFlow.
abstract final class AppStrings {
  // ─── App Identity ─────────────────────────────────────────────────────────
  static const String appName = 'InkFlow';
  static const String appTagline = 'Capture Ideas. Organize Life.';

  // ─── Hive Box Names ───────────────────────────────────────────────────────
  // These are the keys used to open Hive boxes.
  // IMPORTANT: Never change these values after shipping — doing so would
  // cause the app to lose all existing user data.
  static const String settingsBoxName = 'settings_box';
  static const String notesBoxName = 'notes_box';
  static const String categoriesBoxName = 'categories_box';
  static const String tagsBoxName = 'tags_box';
  static const String remindersBoxName = 'reminders_box';
  static const String attachmentsBoxName = 'attachments_box';

  // ─── Settings Keys ────────────────────────────────────────────────────────
  // Keys for values stored in the settings_box.
  static const String themeModeSetting = 'theme_mode';

  // ─── Empty State Messages ─────────────────────────────────────────────────
  static const String emptyNotesTitle = 'No notes yet';
  static const String emptyNotesSubtitle =
      'Tap the + button to create your first note.';

  static const String emptySearchTitle = 'No results found';
  static const String emptySearchSubtitle =
      'Try a different keyword or check your spelling.';

  static const String emptyTrashTitle = 'Trash is empty';
  static const String emptyTrashSubtitle =
      'Deleted notes will appear here for 30 days.';

  static const String emptyArchiveTitle = 'Archive is empty';
  static const String emptyArchiveSubtitle =
      'Archived notes will appear here.';

  static const String emptyFavoritesTitle = 'No favorites yet';
  static const String emptyFavoritesSubtitle =
      'Tap the heart on any note to add it here.';

  // ─── Button Labels ────────────────────────────────────────────────────────
  static const String buttonDone = 'Done';
  static const String buttonCancel = 'Cancel';
  static const String buttonSave = 'Save';
  static const String buttonDelete = 'Delete';
  static const String buttonRestore = 'Restore';
  static const String buttonCreate = 'Create';
  static const String buttonEdit = 'Edit';
  static const String buttonDiscard = 'Discard';

  // ─── Screen Titles ────────────────────────────────────────────────────────
  static const String screenNotes = 'Notes';
  static const String screenSearch = 'Search';
  static const String screenCategories = 'Categories';
  static const String screenSettings = 'Settings';
  static const String screenArchive = 'Archive';
  static const String screenTrash = 'Trash';
  static const String screenFavorites = 'Favorites';

  // ─── Accessibility Semantics ──────────────────────────────────────────────
  static const String semanticLoading = 'Loading content, please wait';
  static const String semanticEmptyState = 'Empty state illustration';
  static const String semanticThemeToggle = 'Toggle light and dark mode';
}
