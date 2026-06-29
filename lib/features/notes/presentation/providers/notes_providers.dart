// lib/features/notes/presentation/providers/notes_providers.dart
//
// All derived and simple state providers for the Notes feature.
//
// Provider hierarchy:
//
//   notesProvider  (AsyncNotifier — raw full collection)
//       │
//       ├── activeNotesProvider    (Provider — filter + sort in memory)
//       │       └── filteredActiveNotesProvider  (Provider — NoteFilter applied)
//       ├── archivedNotesProvider  (Provider — filter + sort in memory)
//       ├── trashedNotesProvider   (Provider — filter + sort in memory)
//       └── favoriteNotesProvider  (Provider — cross-status favorites)
//
//   noteFilterProvider     (StateProvider — tab selection)
//   searchQueryProvider    (StateProvider.autoDispose — search input)
//   searchResultsProvider  (FutureProvider.autoDispose — search results)
//
// Sorting is done here, not in the data source, because:
//   1. We now use GetAllNotesUseCase whose order is insertion order.
//   2. Each view has its own sort preference.
//   3. In-memory sort of a List<NoteEntity> is O(n log n) and fast.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/notes_use_case_providers.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/entities/note_status.dart';
import 'note_filter.dart';
import 'notes_notifier.dart';

// ─── Filter ──────────────────────────────────────────────────────────────────

/// Controls which [NoteFilter] tab is active on the Notes screen.
///
/// Defaults to [NoteFilter.all]. Not auto-disposed — the filter persists
/// across navigations within the session.
final noteFilterProvider = StateProvider<NoteFilter>(
  (ref) => NoteFilter.all,
  name: 'noteFilterProvider',
);

// ─── Derived Note Lists ───────────────────────────────────────────────────────

/// All active notes, sorted pinned-first then by most recently updated.
///
/// Propagates the [AsyncValue] state of [notesProvider]:
///   - [AsyncLoading] while the initial fetch runs.
///   - [AsyncError]   if the fetch fails.
///   - [AsyncData]    with the sorted, filtered list when ready.
///
/// Automatically rebuilds whenever [notesProvider] delivers a new list
/// (i.e., after every successful mutation in [NotesNotifier]).
///
/// ```dart
/// final activeAsync = ref.watch(activeNotesProvider);
/// ```
final activeNotesProvider = Provider<AsyncValue<List<NoteEntity>>>((ref) {
  return ref.watch(notesProvider).whenData((notes) {
    final active = notes
        .where((n) => n.status == NoteStatus.active)
        .toList()
      ..sort((a, b) {
        // Pinned notes always appear above unpinned notes.
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        // Within the same pin group, most recently updated first.
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return active;
  });
}, name: 'activeNotesProvider');

/// Active notes further filtered by [noteFilterProvider].
///
/// The Notes screen watches this provider — NOT [activeNotesProvider] —
/// so that filter tab changes cause immediate, synchronous rebuilds without
/// any additional async work.
///
/// ```dart
/// final filtered = ref.watch(filteredActiveNotesProvider);
/// filtered.when(
///   loading: () => const InkLoadingIndicator(),
///   error:   (e, _) => NoteErrorView(failure: e as Failure),
///   data:    (notes) => NoteListView(notes: notes),
/// );
/// ```
final filteredActiveNotesProvider =
    Provider<AsyncValue<List<NoteEntity>>>((ref) {
  final filter = ref.watch(noteFilterProvider);
  return ref.watch(activeNotesProvider).whenData(
        (notes) => switch (filter) {
          NoteFilter.all      => notes,
          NoteFilter.favorites => notes.where((n) => n.isFavorite).toList(),
          NoteFilter.pinned   => notes.where((n) => n.isPinned).toList(),
        },
      );
}, name: 'filteredActiveNotesProvider');

/// All archived notes, sorted by most recently updated.
///
/// The Archive screen watches this provider directly.
final archivedNotesProvider = Provider<AsyncValue<List<NoteEntity>>>((ref) {
  return ref.watch(notesProvider).whenData((notes) {
    return notes
        .where((n) => n.status == NoteStatus.archived)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  });
}, name: 'archivedNotesProvider');

/// All trashed notes, sorted by most recently trashed first.
///
/// Uses [NoteEntity.trashedAt] when available, falling back to [updatedAt].
/// The Trash screen watches this provider directly.
final trashedNotesProvider = Provider<AsyncValue<List<NoteEntity>>>((ref) {
  return ref.watch(notesProvider).whenData((notes) {
    return notes
        .where((n) => n.status == NoteStatus.trashed)
        .toList()
      ..sort((a, b) {
        final aTime = a.trashedAt ?? a.updatedAt;
        final bTime = b.trashedAt ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });
  });
}, name: 'trashedNotesProvider');

/// Favorited notes across active AND archived status (trashed excluded).
///
/// The Favorites screen watches this provider. A note remains in Favorites
/// whether it is active or archived — matching Google Keep behavior.
final favoriteNotesProvider = Provider<AsyncValue<List<NoteEntity>>>((ref) {
  return ref.watch(notesProvider).whenData((notes) {
    return notes
        .where((n) => n.isFavorite && n.status != NoteStatus.trashed)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  });
}, name: 'favoriteNotesProvider');

// ─── Search ───────────────────────────────────────────────────────────────────

/// Raw text typed into the search field.
///
/// Auto-disposed when the search screen closes and all listeners are removed,
/// which resets the query to '' without manual intervention.
final searchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
  name: 'searchQueryProvider',
);

/// Live search results derived from [searchQueryProvider].
///
/// - Returns `[]` immediately for a blank query (no data source call).
/// - Re-executes automatically whenever [searchQueryProvider] changes.
/// - Auto-disposed with [searchQueryProvider] when the search screen closes.
/// - Throws [Failure] on error → surfaces as [AsyncError] in the UI.
///
/// ```dart
/// final resultsAsync = ref.watch(searchResultsProvider);
/// resultsAsync.when(
///   data:    (notes) => SearchResultsView(notes: notes),
///   loading: () => const InkLoadingIndicator(),
///   error:   (e, _) => NoteErrorView(failure: e as Failure),
/// );
/// ```
final searchResultsProvider =
    FutureProvider.autoDispose<List<NoteEntity>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final result =
      await ref.read(searchNotesUseCaseProvider)(query.trim());
  return result.fold(
    (failure) => throw failure,
    (notes) => notes,
  );
}, name: 'searchResultsProvider');
