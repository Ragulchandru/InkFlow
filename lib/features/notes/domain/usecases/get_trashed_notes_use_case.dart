// lib/features/notes/domain/usecases/get_trashed_notes_use_case.dart

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

/// Returns all trashed notes for display on the Trash screen.
///
/// Results are sorted by most recently trashed first.
/// Returns an empty list (not a failure) when the trash is empty.
///
/// The UI should display each note's [NoteEntity.trashedAt] timestamp so
/// users understand when the 30-day auto-delete countdown expires.
class GetTrashedNotesUseCase implements UseCase<List<NoteEntity>, NoParams> {
  const GetTrashedNotesUseCase(this.repository);

  /// The note repository. Never references Hive directly.
  final NoteRepository repository;

  @override
  Future<Either<Failure, List<NoteEntity>>> call(NoParams _) =>
      repository.getTrashedNotes();
}
