// lib/features/notes/domain/usecases/get_all_notes_use_case.dart

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

/// Returns every note in storage regardless of status.
///
/// Intended for bulk operations such as export or backup.
/// For filtered lists, prefer [GetActiveNotesUseCase],
/// [GetArchivedNotesUseCase], or [GetTrashedNotesUseCase].
class GetAllNotesUseCase implements UseCase<List<NoteEntity>, NoParams> {
  const GetAllNotesUseCase(this.repository);

  /// The note repository. Never references Hive directly.
  final NoteRepository repository;

  @override
  Future<Either<Failure, List<NoteEntity>>> call(NoParams _) =>
      repository.getAllNotes();
}
