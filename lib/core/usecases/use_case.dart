// lib/core/usecases/use_case.dart
//
// Base contract shared by every use case in Orynta.
//
// Why a base class?
//   All use cases share the same shape: they take some input (Params) and
//   return Either<Failure, Type>. Encoding this shape in a generic base class
//   means:
//     - Every use case is recognisable by a single type.
//     - Riverpod providers and tests can reference UseCase<T, P> without
//       knowing which concrete class they hold.
//     - Adding a new use case automatically follows the same contract.

import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';

/// Base contract for every Orynta use case.
///
/// - [Output] — the success value type (e.g., [NoteEntity], [List<NoteEntity>]).
/// - [Params] — the input parameter type. Use [NoParams] when no input is needed.
///
/// Call a use case with `call()` or the shorthand `useCase(params)` syntax:
/// ```dart
/// final result = await createNote(params);       // shorthand
/// final result = await createNote.call(params);  // explicit
/// ```
abstract class UseCase<Output, Params> {
  /// Executes the use case with [params] and returns [Either]<[Failure], [Output]>.
  Future<Either<Failure, Output>> call(Params params);
}

/// Sentinel type for [UseCase]s that require no input parameters.
///
/// ```dart
/// final result = await getActiveNotes(const NoParams());
/// ```
class NoParams {
  const NoParams();
}
