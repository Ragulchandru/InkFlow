// lib/features/notes/data/datasources/note_local_data_source.dart
//
// The contract that any local note storage implementation must fulfil.
//
// Why an interface?
//   Following the Dependency Inversion Principle (SOLID "D"), the repository
//   depends on this abstraction rather than on HiveNoteLocalDataSource
//   directly. This means:
//
//   1. The repository never imports Hive — it stays decoupled from storage.
//   2. Swapping Hive for another database only requires a new class that
//      implements this interface — no changes to the repository, use cases,
//      or UI.
//   3. Unit tests can use a mock or in-memory implementation instead of a
//      real Hive box.
//
// Layer boundary:
//   This interface lives in the DATA layer (features/notes/data/datasources).
//   It returns domain objects ([NoteEntity]) so the repository can forward
//   them up to use cases without an additional conversion step.
//
// Exception contract:
//   All methods throw [NoteNotFoundException] when the given ID is absent,
//   and [NoteStorageException] when a Hive I/O operation fails.
//   The repository (Step 4) catches these and converts them to
//   Either<Failure, T> values.

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/note_entity.dart';

// Suppress unused import warning — exceptions.dart is documented here
// to state the contract but not directly referenced in return types.
export '../../../../core/errors/exceptions.dart';

/// Contract for local (on-device) note storage operations.
///
/// All methods are asynchronous. Read operations return copies of the
/// current stored state. Write operations persist the change and return
/// the resulting [NoteEntity] so the caller always has the latest state.
///
/// Throws:
/// - [NoteNotFoundException] — when the requested note ID does not exist.
/// - [NoteStorageException] — when an underlying storage I/O error occurs.
abstract interface class NoteLocalDataSource {
  // ─── Write Operations ──────────────────────────────────────────────────

  /// Persists a new note and returns the saved [NoteEntity].
  ///
  /// The [entity] must have a unique [NoteEntity.id] (UUID v4).
  /// The caller (use case) is responsible for generating the ID and setting
  /// initial timestamps before calling this method.
  ///
  /// Throws [NoteStorageException] if the Hive write fails.
  Future<NoteEntity> createNote(NoteEntity entity);

  /// Overwrites an existing note with the fields in [entity] and returns
  /// the saved [NoteEntity].
  ///
  /// The note identified by [entity.id] must already exist in storage.
  ///
  /// Throws [NoteNotFoundException] if the note does not exist.
  /// Throws [NoteStorageException] if the Hive write fails.
  Future<NoteEntity> updateNote(NoteEntity entity);

  /// Soft-deletes a note by moving it to the trash.
  ///
  /// Sets [NoteEntity.status] to [NoteStatus.trashed] and records
  /// [NoteEntity.trashedAt] as the current time. The note is NOT removed
  /// from storage — it remains accessible via [getTrashedNotes()] until
  /// permanently purged after 30 days.
  ///
  /// Returns the updated [NoteEntity] in its trashed state.
  ///
  /// Throws [NoteNotFoundException] if the note does not exist.
  /// Throws [NoteStorageException] if the Hive write fails.
  Future<NoteEntity> deleteNote(String id);

  /// Restores a trashed note back to active status.
  ///
  /// Sets [NoteEntity.status] to [NoteStatus.active] and clears
  /// [NoteEntity.trashedAt]. The note reappears in the main list.
  ///
  /// Returns the restored [NoteEntity].
  ///
  /// Throws [NoteNotFoundException] if the note does not exist.
  /// Throws [NoteStorageException] if the Hive write fails.
  Future<NoteEntity> restoreNote(String id);

  /// Archives a note, hiding it from the main notes list.
  ///
  /// Sets [NoteEntity.status] to [NoteStatus.archived].
  /// The note remains accessible via [getArchivedNotes()].
  ///
  /// Returns the updated [NoteEntity].
  ///
  /// Throws [NoteNotFoundException] if the note does not exist.
  /// Throws [NoteStorageException] if the Hive write fails.
  Future<NoteEntity> archiveNote(String id);

  /// Unarchives a note, restoring it to the main notes list.
  ///
  /// Sets [NoteEntity.status] to [NoteStatus.active].
  ///
  /// Returns the updated [NoteEntity].
  ///
  /// Throws [NoteNotFoundException] if the note does not exist.
  /// Throws [NoteStorageException] if the Hive write fails.
  Future<NoteEntity> unarchiveNote(String id);

  /// Pins a note to the top of the active notes list.
  ///
  /// Sets [NoteEntity.isPinned] to `true` and updates [NoteEntity.updatedAt].
  ///
  /// Returns the updated [NoteEntity].
  ///
  /// Throws [NoteNotFoundException] if the note does not exist.
  /// Throws [NoteStorageException] if the Hive write fails.
  Future<NoteEntity> pinNote(String id);

  /// Unpins a previously pinned note.
  ///
  /// Sets [NoteEntity.isPinned] to `false` and updates [NoteEntity.updatedAt].
  ///
  /// Returns the updated [NoteEntity].
  ///
  /// Throws [NoteNotFoundException] if the note does not exist.
  /// Throws [NoteStorageException] if the Hive write fails.
  Future<NoteEntity> unpinNote(String id);

  /// Toggles the favorite state of a note.
  ///
  /// Flips [NoteEntity.isFavorite] and updates [NoteEntity.updatedAt].
  ///
  /// Returns the updated [NoteEntity].
  ///
  /// Throws [NoteNotFoundException] if the note does not exist.
  /// Throws [NoteStorageException] if the Hive write fails.
  Future<NoteEntity> toggleFavorite(String id);

  // ─── Read Operations ───────────────────────────────────────────────────

  /// Returns every note in storage, regardless of status.
  ///
  /// Intended for bulk operations (e.g., export, backup).
  /// For filtered lists, prefer [getActiveNotes], [getArchivedNotes],
  /// or [getTrashedNotes].
  ///
  /// Throws [NoteStorageException] if the Hive read fails.
  Future<List<NoteEntity>> getAllNotes();

  /// Returns all active notes, sorted by pin status then last-modified date.
  ///
  /// Sort order:
  ///   1. Pinned notes first.
  ///   2. Within each group, most recently modified ([NoteEntity.updatedAt]) first.
  ///
  /// Throws [NoteStorageException] if the Hive read fails.
  Future<List<NoteEntity>> getActiveNotes();

  /// Returns all archived notes, sorted by last-modified date descending.
  ///
  /// Throws [NoteStorageException] if the Hive read fails.
  Future<List<NoteEntity>> getArchivedNotes();

  /// Returns all trashed notes, sorted by trash date descending.
  ///
  /// The most recently trashed note appears first. Notes remain in trash
  /// for 30 days before being permanently purged.
  ///
  /// Throws [NoteStorageException] if the Hive read fails.
  Future<List<NoteEntity>> getTrashedNotes();

  /// Searches non-trashed notes whose [NoteEntity.title] or [NoteEntity.body]
  /// contains [query] (case-insensitive).
  ///
  /// An empty [query] returns an empty list.
  /// Results are sorted by last-modified date descending.
  ///
  /// Throws [NoteStorageException] if the Hive read fails.
  Future<List<NoteEntity>> searchNotes(String query);

  /// Returns the single note with the given [id].
  ///
  /// Throws [NoteNotFoundException] if no note with [id] exists.
  /// Throws [NoteStorageException] if the Hive read fails.
  Future<NoteEntity> getNoteById(String id);
}
