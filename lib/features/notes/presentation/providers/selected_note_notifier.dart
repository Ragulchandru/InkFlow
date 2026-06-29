// lib/features/notes/presentation/providers/selected_note_notifier.dart
//
// State management for the Note Editor screen.
//
// Lifecycle:
//   - build() returns null → no note selected.
//   - When the editor screen opens, it calls loadNote(id).
//   - When the user saves, it calls updateNote(entity).
//   - When the editor closes, it calls clear().
//
// Why not FutureProvider.family?
//   A family provider is excellent for read-only note display but provides
//   no mutation surface. The editor needs both read (load) and write (update).
//   AsyncNotifier gives a clean mutable surface:
//     ref.read(selectedNoteProvider.notifier).loadNote(id);
//     ref.read(selectedNoteProvider.notifier).updateNote(entity);
//
// Cross-provider invalidation:
//   updateNote() invalidates activeNotesProvider so the notes list reflects
//   changes made in the editor without a manual pull-to-refresh.
//   One-way import — no circular dependency.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../di/notes_use_case_providers.dart';
import '../../domain/entities/note_entity.dart';
import 'notes_notifier.dart';

/// Manages the note currently open in the editor screen.
///
/// State transitions:
///   `AsyncData(null)`         → initial / editor closed
///   `AsyncLoading()`          → loading a note by ID
///   `AsyncData(NoteEntity)`   → note loaded successfully
///   `AsyncError(failure, st)` → note not found or storage error
class SelectedNoteNotifier extends AsyncNotifier<NoteEntity?> {
  /// Initial state: no note selected.
  @override
  FutureOr<NoteEntity?> build() => null;

  /// Loads the note with [id] from local storage.
  ///
  /// Sets state to [AsyncLoading] immediately, then to [AsyncData] or
  /// [AsyncError] based on the result. The editor screen rebuilds on
  /// each transition.
  Future<void> loadNote(String id) async {
    state = const AsyncLoading();
    final result = await ref.read(getNoteByIdUseCaseProvider)(id);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (note) => AsyncData(note),
    );
  }

  /// Persists the [entity] and updates local state on success.
  ///
  /// On success:
  ///   - Updates [selectedNoteProvider] state with the saved entity.
  ///   - Invalidates [activeNotesProvider] so the notes list reflects the
  ///     updated title, body, and updatedAt without navigating away.
  ///
  /// On failure: state is unchanged; the UI reads the returned [Left] to
  /// show a SnackBar without disturbing the note the user was editing.
  Future<Either<Failure, NoteEntity>> updateNote(NoteEntity entity) async {
    final result = await ref.read(updateNoteUseCaseProvider)(entity);
    result.fold(
      (failure) => null, // Keep existing state; let the UI handle the error.
      (updated) {
        state = AsyncData(updated);
        // Invalidate the single source of truth so all derived providers
        // (activeNotesProvider, archivedNotesProvider, etc.) update at once.
        ref.invalidate(notesProvider);
      },
    );
    return result;
  }

  /// Resets the editor state to null.
  ///
  /// Call when the editor screen is disposed to release the note reference.
  void clear() => state = const AsyncData(null);
}

/// Provides the note currently open in the editor and exposes
/// [loadNote], [updateNote], and [clear] via [SelectedNoteNotifier].
///
/// ```dart
/// // In the editor's initState / build:
/// final noteAsync = ref.watch(selectedNoteProvider);
///
/// // On screen open:
/// ref.read(selectedNoteProvider.notifier).loadNote(noteId);
///
/// // On save:
/// await ref.read(selectedNoteProvider.notifier).updateNote(updatedEntity);
///
/// // On dispose:
/// ref.read(selectedNoteProvider.notifier).clear();
/// ```
final selectedNoteProvider =
    AsyncNotifierProvider<SelectedNoteNotifier, NoteEntity?>(
  SelectedNoteNotifier.new,
);
