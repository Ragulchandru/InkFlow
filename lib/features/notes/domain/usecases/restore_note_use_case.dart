// lib/features/notes/domain/usecases/restore_note_use_case.dart

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

/// Restores a trashed note back to active status.
///
/// Business rules:
///   1. [NoteEntity.status] is set back to [NoteStatus.active].
///   2. [NoteEntity.trashedAt] is cleared (set to null) — the note is no
///      longer subject to the 30-day auto-delete countdown.
///   3. The restored note reappears in the main [GetActiveNotesUseCase] list.
///   4. A [NoteNotFoundFailure] is returned if the note does not exist.
class RestoreNoteUseCase implements UseCase<NoteEntity, String> {
  const RestoreNoteUseCase(this.repository);

  /// The note repository. Never references Hive directly.
  final NoteRepository repository;

  @override
  Future<Either<Failure, NoteEntity>> call(String id) =>
      repository.restoreNote(id);
}
