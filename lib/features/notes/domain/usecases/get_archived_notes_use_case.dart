// lib/features/notes/domain/usecases/get_archived_notes_use_case.dart

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

/// Returns all archived notes for display on the Archive screen.
///
/// Results are sorted by most recently modified first.
/// Returns an empty list (not a failure) when there are no archived notes.
class GetArchivedNotesUseCase implements UseCase<List<NoteEntity>, NoParams> {
  const GetArchivedNotesUseCase(this.repository);

  /// The note repository. Never references Hive directly.
  final NoteRepository repository;

  @override
  Future<Either<Failure, List<NoteEntity>>> call(NoParams _) =>
      repository.getArchivedNotes();
}
