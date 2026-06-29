// lib/features/notes/domain/usecases/get_active_notes_use_case.dart

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

/// Returns all active notes for display on the main Notes screen.
///
/// Results are sorted by the data source:
///   1. Pinned notes first.
///   2. Within each group, most recently modified first.
///
/// Returns an empty list (not a failure) when the user has no active notes.
class GetActiveNotesUseCase implements UseCase<List<NoteEntity>, NoParams> {
  const GetActiveNotesUseCase(this.repository);

  /// The note repository. Never references Hive directly.
  final NoteRepository repository;

  @override
  Future<Either<Failure, List<NoteEntity>>> call(NoParams _) =>
      repository.getActiveNotes();
}
