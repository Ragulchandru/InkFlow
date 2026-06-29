// lib/features/notes/domain/usecases/unpin_note_use_case.dart

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

/// Unpins a previously pinned note.
///
/// Business rules:
///   1. If the note is already unpinned, this is a no-op — the existing
///      [NoteEntity] is returned immediately without a storage write.
///      This prevents redundant writes and a spurious [updatedAt] change.
///   2. The note must exist in storage. A [NoteNotFoundFailure] is returned
///      if it does not.
class UnpinNoteUseCase implements UseCase<NoteEntity, String> {
  const UnpinNoteUseCase(this.repository);

  /// The note repository. Never references Hive directly.
  final NoteRepository repository;

  @override
  Future<Either<Failure, NoteEntity>> call(String id) async {
    final result = await repository.getNoteById(id);

    // Propagate any failure (e.g. note not found) immediately.
    if (result.isLeft()) return result;

    final note = result.getRight().toNullable()!;

    // Business rule 1: already unpinned — return as-is, skip the write.
    if (!note.isPinned) return Right(note);

    return repository.unpinNote(id);
  }
}
