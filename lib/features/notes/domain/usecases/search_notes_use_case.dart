// lib/features/notes/domain/usecases/search_notes_use_case.dart

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

/// Searches non-trashed notes whose title or body contains the query string.
///
/// Business rules:
///   1. Leading and trailing whitespace is stripped from the query before
///      the search. "  todo  " is treated as "todo".
///   2. If the trimmed query is empty, an empty list is returned immediately.
///      This avoids an unnecessary full scan and never returns all notes.
///   3. Matching is case-insensitive (delegated to the data source).
///   4. Trashed notes are excluded from results (delegated to the data source).
///   5. Results are ordered by [NoteEntity.updatedAt] descending
///      (delegated to the data source).
class SearchNotesUseCase implements UseCase<List<NoteEntity>, String> {
  const SearchNotesUseCase(this.repository);

  /// The note repository. Never references Hive directly.
  final NoteRepository repository;

  @override
  Future<Either<Failure, List<NoteEntity>>> call(String query) async {
    final trimmed = query.trim(); // Business rule 1.

    // Business rule 2: skip the repository call entirely for blank queries.
    if (trimmed.isEmpty) return const Right([]);

    return repository.searchNotes(trimmed);
  }
}
