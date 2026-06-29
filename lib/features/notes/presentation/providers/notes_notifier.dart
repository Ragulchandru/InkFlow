// lib/features/notes/presentation/providers/notes_notifier.dart
//
// Single source of truth for the entire notes collection.
//
// Architecture decision — Why one notifier instead of three?
//
//   BEFORE (three notifiers):
//     ActiveNotesNotifier  ─── fetches active notes independently
//     ArchivedNotesNotifier ── fetches archived notes independently
//     TrashedNotesNotifier  ── fetches trashed notes independently
//
//     Problem: archiving a note requires invalidating TWO notifiers.
//     Tricky one-way import chain. If a third screen is added, a third
//     notifier must be kept in sync. Any missed invalidation = stale UI.
//
//   AFTER (one notifier, derived providers):
//     NotesNotifier ─── fetches ALL notes once (via GetAllNotesUseCase)
//         │
//         ├── activeNotesProvider   ─── in-memory filter + sort
//         ├── archivedNotesProvider ─── in-memory filter + sort
//         ├── trashedNotesProvider  ─── in-memory filter + sort
//         └── filteredActiveNotesProvider ─── NoteFilter applied on top
//
//     A single ref.invalidateSelf() updates EVERY view simultaneously.
//     No cross-provider invalidation. No import dependencies between views.
//
// Why GetAllNotesUseCase instead of GetActiveNotesUseCase?
//   Hive is an in-memory key-value store — reading all notes is essentially
//   the same cost as reading a filtered subset (no SQL query planner). For
//   Phase 1 (hundreds of notes), the difference is imperceptible. The
//   in-memory sort/filter in Dart is fast and clean.
//
// Mutation contract:
//   Each method returns Either<Failure, NoteEntity> to the caller (the UI).
//   On Right: ref.invalidateSelf() re-runs build() and refreshes all views.
//   On Left:  notifier state is unchanged; the UI handles the error.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/use_case.dart';
import '../../di/notes_use_case_providers.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/usecases/create_note_use_case.dart';

/// Single AsyncNotifier that owns the complete in-memory notes collection.
///
/// All four derived providers ([activeNotesProvider], [archivedNotesProvider],
/// [trashedNotesProvider], [filteredActiveNotesProvider]) are computed from
/// this notifier's state — they do NOT fetch independently.
///
/// The UI never calls [notesProvider] directly for display; it watches the
/// appropriate derived provider instead.
class NotesNotifier extends AsyncNotifier<List<NoteEntity>> {
  /// Loads all notes from local storage.
  ///
  /// Called automatically on first access and whenever [ref.invalidateSelf()]
  /// is called by a mutation method. Throws [Failure] on storage error,
  /// which Riverpod surfaces as [AsyncError] on all derived providers.
  @override
  Future<List<NoteEntity>> build() async {
    final result =
        await ref.read(getAllNotesUseCaseProvider)(const NoParams());
    return result.fold(
      (failure) => throw failure,
      (notes) => notes,
    );
  }

  // ─── Private Helper ──────────────────────────────────────────────────────

  /// Executes [action], refreshes on success, and returns the [Either].
  ///
  /// Consolidates the three-line pattern shared by all 9 mutation methods:
  ///   1. Await the use case result.
  ///   2. Invalidate self on [Right] to trigger a re-fetch.
  ///   3. Return the [Either] to the UI for error handling.
  Future<Either<Failure, T>> _mutate<T>(
    Future<Either<Failure, T>> Function() action,
  ) async {
    final result = await action();
    if (result.isRight()) ref.invalidateSelf();
    return result;
  }

  // ─── Write Operations ─────────────────────────────────────────────────────

  /// Creates a new note.
  ///
  /// Returns [NoteValidationFailure] if both title and body are empty.
  /// Returns [NoteStorageFailure] if the write fails.
  Future<Either<Failure, NoteEntity>> createNote(
    CreateNoteParams params,
  ) =>
      _mutate(() => ref.read(createNoteUseCaseProvider)(params));

  /// Updates an existing note's content, trimming fields and stamping updatedAt.
  ///
  /// Returns [NoteNotFoundFailure] if the note no longer exists.
  Future<Either<Failure, NoteEntity>> updateNote(NoteEntity entity) =>
      _mutate(() => ref.read(updateNoteUseCaseProvider)(entity));

  /// Soft-deletes a note by moving it to the trash.
  ///
  /// The note disappears from [activeNotesProvider] and appears in
  /// [trashedNotesProvider] after the next re-fetch — with a single
  /// [ref.invalidateSelf()] call.
  Future<Either<Failure, NoteEntity>> deleteNote(String id) =>
      _mutate(() => ref.read(deleteNoteUseCaseProvider)(id));

  /// Archives a note.
  ///
  /// After [ref.invalidateSelf()], the note vanishes from [activeNotesProvider]
  /// and appears in [archivedNotesProvider] — no cross-invalidation needed.
  Future<Either<Failure, NoteEntity>> archiveNote(String id) =>
      _mutate(() => ref.read(archiveNoteUseCaseProvider)(id));

  /// Returns an archived note to the active list.
  Future<Either<Failure, NoteEntity>> unarchiveNote(String id) =>
      _mutate(() => ref.read(unarchiveNoteUseCaseProvider)(id));

  /// Restores a trashed note to the active list.
  Future<Either<Failure, NoteEntity>> restoreNote(String id) =>
      _mutate(() => ref.read(restoreNoteUseCaseProvider)(id));

  /// Pins a note to the top of the active list.
  ///
  /// No-op (returns [Right]) if the note is already pinned.
  Future<Either<Failure, NoteEntity>> pinNote(String id) =>
      _mutate(() => ref.read(pinNoteUseCaseProvider)(id));

  /// Unpins a note.
  ///
  /// No-op (returns [Right]) if the note is already unpinned.
  Future<Either<Failure, NoteEntity>> unpinNote(String id) =>
      _mutate(() => ref.read(unpinNoteUseCaseProvider)(id));

  /// Toggles the favorite state of a note.
  Future<Either<Failure, NoteEntity>> toggleFavorite(String id) =>
      _mutate(() => ref.read(toggleFavoriteUseCaseProvider)(id));
}

/// The single source of truth for all notes.
///
/// Derived providers watch this — the UI watches derived providers instead.
///
/// ```dart
/// // From the UI — mutate:
/// await ref.read(notesProvider.notifier).createNote(params);
/// await ref.read(notesProvider.notifier).archiveNote(id);
///
/// // Do NOT watch this directly for display:
/// // Use activeNotesProvider, archivedNotesProvider, etc.
/// ```
final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<NoteEntity>>(
  NotesNotifier.new,
);
