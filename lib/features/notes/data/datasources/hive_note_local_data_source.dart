// lib/features/notes/data/datasources/hive_note_local_data_source.dart
//
// Hive implementation of [NoteLocalDataSource].
//
// Design decisions:
//
// 1. CONSTRUCTOR INJECTION for the Hive box.
//    The Box<NoteModel> is passed in via the constructor rather than
//    accessed via Hive.box() inside each method. This decouples the class
//    from the global Hive registry, making it testable without a real box.
//    In a test you pass an in-memory box; in production, Riverpod provides
//    the already-opened box from main.dart (Step 6).
//
// 2. IMMUTABLE UPDATES via entity.copyWith().
//    NoteModel fields are final — it cannot be mutated in place.
//    Status changes (archive, pin, etc.) follow this pattern:
//      a. Get model → convert to entity (toEntity).
//      b. Apply changes via freezed's copyWith (zero boilerplate).
//      c. Convert back to model (NoteModel.fromEntity).
//      d. Persist with box.put(id, newModel).
//    This guarantees all fields are consistent and updatedAt is always fresh.
//
// 3. PRIVATE HELPERS to eliminate repetition (DRY principle).
//    _getEntityOrThrow — single null-check for all read-by-ID operations.
//    _persistAndReturn  — single save-to-box step for all write operations.
//
// 4. EXCEPTION WRAPPING.
//    Every Hive call is wrapped in try/catch. Hive errors are re-thrown as
//    [NoteStorageException] so the repository can handle them uniformly.
//    Null results are re-thrown as [NoteNotFoundException].

import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/note_entity.dart';
import '../../domain/entities/note_status.dart';
import '../models/note_model.dart';
import 'note_local_data_source.dart';

/// Hive-backed implementation of [NoteLocalDataSource].
///
/// Stores notes in a [Box]<[NoteModel]> keyed by [NoteEntity.id] (UUID).
/// Converts between [NoteModel] and [NoteEntity] on every read and write.
class HiveNoteLocalDataSource implements NoteLocalDataSource {
  /// Creates an instance backed by the given [box].
  ///
  /// The box must already be open (opened in main.dart before runApp).
  /// Pass [Hive.box<NoteModel>(AppStrings.notesBoxName)] from the provider.
  const HiveNoteLocalDataSource({required Box<NoteModel> box}) : _box = box;

  final Box<NoteModel> _box;

  // ─── Private Helpers ──────────────────────────────────────────────────────

  /// Reads a [NoteModel] by [id] and converts it to a [NoteEntity].
  ///
  /// Throws [NoteNotFoundException] if no entry exists for [id].
  NoteEntity _getEntityOrThrow(String id) {
    final model = _box.get(id);
    if (model == null) throw NoteNotFoundException(id);
    return model.toEntity();
  }

  /// Converts [entity] to a [NoteModel], saves it to the box, and returns
  /// the entity. All write operations funnel through this method.
  ///
  /// Throws [NoteStorageException] if the Hive write fails.
  Future<NoteEntity> _persistAndReturn(NoteEntity entity) async {
    try {
      final model = NoteModel.fromEntity(entity);
      await _box.put(entity.id, model);
      return entity;
    } catch (e) {
      throw NoteStorageException('Failed to save note "${entity.id}": $e');
    }
  }

  // ─── Write Operations ─────────────────────────────────────────────────────

  @override
  Future<NoteEntity> createNote(NoteEntity entity) async {
    return _persistAndReturn(entity);
  }

  @override
  Future<NoteEntity> updateNote(NoteEntity entity) async {
    // Verify the note exists before overwriting — prevents ghost entries.
    _getEntityOrThrow(entity.id);
    final updated = entity.copyWith(updatedAt: DateTime.now());
    return _persistAndReturn(updated);
  }

  @override
  Future<NoteEntity> deleteNote(String id) async {
    // Soft delete: change status to trashed, record the trash timestamp.
    final existing = _getEntityOrThrow(id);
    final now = DateTime.now();
    final trashed = existing.copyWith(
      status: NoteStatus.trashed,
      trashedAt: now,
      updatedAt: now,
    );
    return _persistAndReturn(trashed);
  }

  @override
  Future<NoteEntity> restoreNote(String id) async {
    final existing = _getEntityOrThrow(id);
    final restored = existing.copyWith(
      status: NoteStatus.active,
      // Clear the trash timestamp — the note is no longer in trash.
      trashedAt: null,
      updatedAt: DateTime.now(),
    );
    return _persistAndReturn(restored);
  }

  @override
  Future<NoteEntity> archiveNote(String id) async {
    final existing = _getEntityOrThrow(id);
    final archived = existing.copyWith(
      status: NoteStatus.archived,
      updatedAt: DateTime.now(),
    );
    return _persistAndReturn(archived);
  }

  @override
  Future<NoteEntity> unarchiveNote(String id) async {
    final existing = _getEntityOrThrow(id);
    final active = existing.copyWith(
      status: NoteStatus.active,
      updatedAt: DateTime.now(),
    );
    return _persistAndReturn(active);
  }

  @override
  Future<NoteEntity> pinNote(String id) async {
    final existing = _getEntityOrThrow(id);
    final pinned = existing.copyWith(
      isPinned: true,
      updatedAt: DateTime.now(),
    );
    return _persistAndReturn(pinned);
  }

  @override
  Future<NoteEntity> unpinNote(String id) async {
    final existing = _getEntityOrThrow(id);
    final unpinned = existing.copyWith(
      isPinned: false,
      updatedAt: DateTime.now(),
    );
    return _persistAndReturn(unpinned);
  }

  @override
  Future<NoteEntity> toggleFavorite(String id) async {
    final existing = _getEntityOrThrow(id);
    final toggled = existing.copyWith(
      isFavorite: !existing.isFavorite,
      updatedAt: DateTime.now(),
    );
    return _persistAndReturn(toggled);
  }

  // ─── Read Operations ──────────────────────────────────────────────────────

  @override
  Future<List<NoteEntity>> getAllNotes() async {
    try {
      return _box.values.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw NoteStorageException('Failed to read all notes: $e');
    }
  }

  @override
  Future<List<NoteEntity>> getActiveNotes() async {
    try {
      final notes = _box.values
          .where((m) => m.statusIndex == NoteStatus.active.index)
          .map((m) => m.toEntity())
          .toList();

      // Sort: pinned notes first, then by most recently modified.
      notes.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

      return notes;
    } catch (e) {
      throw NoteStorageException('Failed to read active notes: $e');
    }
  }

  @override
  Future<List<NoteEntity>> getArchivedNotes() async {
    try {
      final notes = _box.values
          .where((m) => m.statusIndex == NoteStatus.archived.index)
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return notes;
    } catch (e) {
      throw NoteStorageException('Failed to read archived notes: $e');
    }
  }

  @override
  Future<List<NoteEntity>> getTrashedNotes() async {
    try {
      final notes = _box.values
          .where((m) => m.statusIndex == NoteStatus.trashed.index)
          .map((m) => m.toEntity())
          .toList();

      // Sort by most recently trashed first.
      // trashedAt is guaranteed non-null for trashed notes.
      notes.sort(
        (a, b) => b.trashedAt!.compareTo(a.trashedAt!),
      );

      return notes;
    } catch (e) {
      throw NoteStorageException('Failed to read trashed notes: $e');
    }
  }

  @override
  Future<List<NoteEntity>> searchNotes(String query) async {
    // Return empty immediately — avoids an expensive scan for empty input.
    if (query.trim().isEmpty) return [];

    try {
      final q = query.toLowerCase();

      final results = _box.values
          // Search active and archived notes; exclude trashed notes.
          .where((m) => m.statusIndex != NoteStatus.trashed.index)
          .map((m) => m.toEntity())
          .where(
            (e) =>
                e.title.toLowerCase().contains(q) ||
                e.body.toLowerCase().contains(q),
          )
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return results;
    } catch (e) {
      throw NoteStorageException('Failed to search notes: $e');
    }
  }

  @override
  Future<NoteEntity> getNoteById(String id) async {
    try {
      return _getEntityOrThrow(id);
    } on NoteNotFoundException {
      rethrow;
    } catch (e) {
      throw NoteStorageException('Failed to read note "$id": $e');
    }
  }
}
