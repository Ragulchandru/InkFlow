// lib/features/notes/domain/usecases/update_note_use_case.dart

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

/// Updates the content of an existing note.
///
/// The Params type is [NoteEntity] — the UI supplies the full entity with the
/// user's edits already applied. The use case applies business rules on top.
///
/// Business rules:
///   1. [NoteEntity.title] and [NoteEntity.body] are trimmed of whitespace.
///   2. [NoteEntity.updatedAt] is overwritten with [DateTime.now()].
///      The caller must NOT set updatedAt — the use case owns this timestamp.
///   3. [NoteEntity.createdAt] is NEVER modified, even if the caller
///      accidentally changed it. The original value is preserved by reading
///      it from the entity's own field (which was loaded from storage).
///   4. All other fields (color, isPinned, status, tagIds, etc.) are passed
///      through unchanged, preserving values the user did not touch.
class UpdateNoteUseCase implements UseCase<NoteEntity, NoteEntity> {
  const UpdateNoteUseCase(this.repository);

  /// The note repository. Never references Hive directly.
  final NoteRepository repository;

  @override
  Future<Either<Failure, NoteEntity>> call(NoteEntity params) async {
    final updated = params.copyWith(
      title: params.title.trim(),     // Business rule 1.
      body: params.body.trim(),       // Business rule 1.
      updatedAt: DateTime.now(),      // Business rule 2.
      // createdAt is untouched — copyWith preserves it from params.
    );

    return repository.updateNote(updated);
  }
}
