// lib/features/notes/domain/usecases/get_note_by_id_use_case.dart

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

/// Returns the single note identified by [id].
///
/// Used by the note editor screen to load a note for viewing or editing.
///
/// Returns [NoteNotFoundFailure] if no note with the given ID exists.
/// The UI should navigate back or show an error message in this case.
class GetNoteByIdUseCase implements UseCase<NoteEntity, String> {
  const GetNoteByIdUseCase(this.repository);

  /// The note repository. Never references Hive directly.
  final NoteRepository repository;

  @override
  Future<Either<Failure, NoteEntity>> call(String id) =>
      repository.getNoteById(id);
}
