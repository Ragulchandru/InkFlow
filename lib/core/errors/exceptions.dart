// lib/core/errors/exceptions.dart
//
// All application-level exceptions that cross layer boundaries.
//
// Design notes:
//   - Exceptions are thrown by the DATA LAYER (data sources).
//   - The REPOSITORY catches them and converts them to Failure objects
//     wrapped in Either<Failure, T> from fpdart (Step 4).
//   - The domain layer and UI layer never see raw exceptions —
//     they only receive typed Either values.
//
//   Keeping exceptions in core/ rather than inside a feature folder allows
//   the repository (also in the feature folder) to catch them without a
//   circular import, and allows future features to reuse base types.

/// Base class for all Orynta application exceptions.
///
/// Extends [Exception] so that all custom exceptions are identifiable
/// by a single type in catch clauses.
abstract class AppException implements Exception {
  const AppException(this.message);

  /// A human-readable description of what went wrong.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown by a data source when a requested note does not exist in storage.
///
/// Example: [NoteLocalDataSource.getNoteById] throws this when the given
/// ID is not a key in the Hive box.
class NoteNotFoundException extends AppException {
  const NoteNotFoundException(String id)
      : super('Note with ID "$id" was not found in storage.');
}

/// Thrown by a data source when a Hive read or write operation fails.
///
/// Wraps the original [Object] error from Hive so that the repository
/// can log it before converting to a domain-level Failure.
class NoteStorageException extends AppException {
  const NoteStorageException(super.message);
}
