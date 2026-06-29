// lib/features/notes/domain/usecases/toggle_favorite_use_case.dart

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

/// Toggles the favorite state of a note.
///
/// Business rules:
///   1. If [NoteEntity.isFavorite] is `true`, it becomes `false`.
///      If it is `false`, it becomes `true`.
///   2. [NoteEntity.updatedAt] is refreshed on every toggle
///      (delegated to the data source).
///   3. A [NoteNotFoundFailure] is returned if the note does not exist.
///
/// No pre-read is required — the toggle is inherently safe on any state.
class ToggleFavoriteUseCase implements UseCase<NoteEntity, String> {
  const ToggleFavoriteUseCase(this.repository);

  /// The note repository. Never references Hive directly.
  final NoteRepository repository;

  @override
  Future<Either<Failure, NoteEntity>> call(String id) =>
      repository.toggleFavorite(id);
}
