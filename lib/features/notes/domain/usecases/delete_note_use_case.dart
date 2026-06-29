// lib/features/notes/domain/usecases/delete_note_use_case.dart

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

/// Soft-deletes a note by moving it to the trash.
///
/// Business rules:
///   1. This is a SOFT delete — the note is NOT removed from storage.
///      It is marked with [NoteStatus.trashed] and a [NoteEntity.trashedAt]
///      timestamp is recorded by the data source.
///   2. The note remains accessible via [GetTrashedNotesUseCase] for 30 days
///      before being permanently purged.
///   3. A [NoteNotFoundFailure] is returned if the note does not exist.
///
/// For permanent deletion (purge), a separate use case will be added
/// in a future phase.
class DeleteNoteUseCase implements UseCase<NoteEntity, String> {
  const DeleteNoteUseCase(this.repository);

  /// The note repository. Never references Hive directly.
  final NoteRepository repository;

  @override
  Future<Either<Failure, NoteEntity>> call(String id) =>
      repository.deleteNote(id);
}
