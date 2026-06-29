// lib/features/notes/presentation/providers/note_filter.dart
//
// Display filter applied on top of the already-fetched active notes list.
//
// This is a PRESENTATION concern — it never touches the data source or
// repository. Filtering happens in [filteredActiveNotesProvider] by
// running a where() clause on the in-memory list returned by
// [activeNotesProvider].
//
// Adding a new filter tab in the UI requires only:
//   1. Adding an entry here.
//   2. Handling the new case in [filteredActiveNotesProvider].

/// Controls which subset of active notes is displayed on the Notes screen.
///
/// Consumed by [noteFilterProvider] and derived in [filteredActiveNotesProvider].
enum NoteFilter {
  /// Show every active note. Pinned notes float to the top (sort by data source).
  all,

  /// Show only active notes where [NoteEntity.isFavorite] is `true`.
  favorites,

  /// Show only active notes where [NoteEntity.isPinned] is `true`.
  pinned,
}
