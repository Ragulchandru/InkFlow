// lib/features/notes/domain/usecases/unarchive_note_use_case.dart

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

/// Unarchives a note, returning it to the active notes list.
///
/// Business rules:
///   1. [NoteEntity.status] is set back to [NoteStatus.active].
///   2. The note reappears in the main [GetActiveNotesUseCase] list.
///   3. A [NoteNotFoundFailure] is returned if the note does not exist.
class UnarchiveNoteUseCase implements UseCase<NoteEntity, String> {
  const UnarchiveNoteUseCase(this.repository);

  /// The note repository. Never references Hive directly.
  final NoteRepository repository;

  @override
  Future<Either<Failure, NoteEntity>> call(String id) =>
      repository.unarchiveNote(id);
}
