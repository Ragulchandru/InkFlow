// lib/core/errors/failures.dart
//
// Domain-layer error types returned by repositories.
//
// Failures vs Exceptions — the key distinction:
//
//   EXCEPTIONS are infrastructure events (data source layer):
//     - Thrown when something goes wrong at the Hive/network/OS level.
//     - Propagate via Dart's throw/catch mechanism.
//     - Unchecked — callers must know to handle them.
//
//   FAILURES are domain values (repository layer):
//     - Returned as the Left side of Either<Failure, T>.
//     - Are first-class values, not control flow — no try/catch needed above
//       the repository boundary.
//     - Checked — the compiler enforces that callers handle them because
//       Either<Failure, T> cannot be ignored like an exception can.
//
// Why sealed?
//   Dart's `sealed` keyword makes Failure a closed hierarchy — every subclass
//   must be declared in this file. This enables EXHAUSTIVE switch expressions
//   in the UI layer:
//
//     switch (failure) {
//       NoteNotFoundFailure() => 'Note not found',
//       NoteStorageFailure()  => 'Storage error, please try again',
//       UnexpectedFailure()   => 'Something went wrong',
//     }
//
//   If a new Failure subclass is added here, every switch that doesn't
//   handle it becomes a compile-time warning — preventing silent bugs.

/// Base class for all domain-level failures in Orynta.
///
/// Returned as the [Left] side of [Either]<[Failure], T> by every repository.
/// Never thrown — always returned as a value.
sealed class Failure {
  const Failure(this.message);

  /// A human-readable description of what went wrong.
  /// Displayed to the user or logged for debugging.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Returned when the requested note does not exist in local storage.
///
/// Maps from [NoteNotFoundException] thrown by [NoteLocalDataSource].
/// The UI should display a "Note not found" message and navigate back.
final class NoteNotFoundFailure extends Failure {
  const NoteNotFoundFailure(super.message);
}

/// Returned when an operation violates a business rule before reaching storage.
///
/// Examples:
///   - Creating a note where both title and body are empty.
/// The UI should display the [message] directly as user-facing feedback.
final class NoteValidationFailure extends Failure {
  const NoteValidationFailure(super.message);
}

/// Returned when a Hive read or write operation fails.
///
/// Maps from [NoteStorageException] thrown by [NoteLocalDataSource].
/// The UI should display a "Storage error" snackbar and allow retry.
final class NoteStorageFailure extends Failure {
  const NoteStorageFailure(super.message);
}

/// Returned when an error occurs that is not covered by a specific Failure type.
///
/// Acts as a safety net — any exception not matched by the repository's
/// typed catch clauses becomes an [UnexpectedFailure].
/// The UI should display a generic "Something went wrong" message.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
