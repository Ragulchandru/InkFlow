// lib/features/notes/domain/usecases/archive_note_use_case.dart

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

/// Archives a note, hiding it from the main notes list.
///
/// Business rules:
///   1. [NoteEntity.status] is set to [NoteStatus.archived].
///   2. The note remains accessible via [GetArchivedNotesUseCase].
///   3. Archiving does NOT affect [NoteEntity.isPinned] or [NoteEntity.isFavorite].
///   4. A [NoteNotFoundFailure] is returned if the note does not exist.
class ArchiveNoteUseCase implements UseCase<NoteEntity, String> {
  const ArchiveNoteUseCase(this.repository);

  /// The note repository. Never references Hive directly.
  final NoteRepository repository;

  @override
  Future<Either<Failure, NoteEntity>> call(String id) =>
      repository.archiveNote(id);
}
