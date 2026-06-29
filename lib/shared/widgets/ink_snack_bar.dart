// lib/shared/widgets/ink_snack_bar.dart
//
// InkSnackBar — Orynta's SnackBar helper.
//
// Problem it solves:
//   Every screen that mutates data (create, archive, delete, etc.) needs to
//   show feedback via SnackBar. Without this helper, each screen repeats:
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//         ...
//       ),
//     );
//
//   This is 8+ lines per call, spread across every screen.
//
// Solution:
//   InkSnackBar.showError(context, failure)   — 1 line
//   InkSnackBar.showSuccess(context, message) — 1 line
//
// Styling:
//   The SnackBar's visual appearance (floating, rounded corners, font) is
//   already defined in AppTheme.snackBarTheme. This class only sets the
//   semantically meaningful properties: content, background color, action.
//
// Usage:
//   // After a failed mutation:
//   result.fold(
//     (failure) => InkSnackBar.showError(context, failure),
//     (_)       => null,
//   );
//
//   // After a successful mutation:
//   result.fold(
//     (failure) => InkSnackBar.showError(context, failure),
//     (_)       => InkSnackBar.showSuccess(context, 'Note archived.'),
//   );
//
//   // With an undo action:
//   InkSnackBar.showSuccess(
//     context,
//     'Note moved to trash.',
//     action: SnackBarAction(label: 'Undo', onPressed: _restore),
//   );

import 'package:flutter/material.dart';

import '../../core/errors/failures.dart';

/// Static helper for showing consistently styled SnackBars in Orynta.
///
/// All methods call [ScaffoldMessenger.of(context).showSnackBar] internally.
/// The styling is inherited from [AppTheme.snackBarTheme].
abstract final class InkSnackBar {
  // ─── Error ────────────────────────────────────────────────────────────────

  /// Shows an error SnackBar for a [Failure].
  ///
  /// The message is derived from [Failure.message] for validation failures
  /// (which are user-readable) and from a generic string for infrastructure
  /// failures (which contain internal details not suitable for display).
  ///
  /// Example:
  /// ```dart
  /// result.fold(
  ///   (failure) => InkSnackBar.showError(context, failure),
  ///   (_) => null,
  /// );
  /// ```
  static void showError(
    BuildContext context,
    Failure failure, {
    SnackBarAction? action,
  }) {
    final message = switch (failure) {
      // Validation messages are already user-friendly — show them directly.
      NoteValidationFailure() => failure.message,
      NoteNotFoundFailure() => 'Note not found.',
      NoteStorageFailure() => 'Could not save. Please try again.',
      UnexpectedFailure() => 'Something went wrong. Please try again.',
    };

    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
      action: action,
    );
  }

  // ─── Success ──────────────────────────────────────────────────────────────

  /// Shows a success SnackBar with [message].
  ///
  /// Optional [action] enables patterns like "Undo" for reversible actions.
  ///
  /// Example:
  /// ```dart
  /// InkSnackBar.showSuccess(
  ///   context,
  ///   'Note archived.',
  ///   action: SnackBarAction(label: 'Undo', onPressed: _unarchive),
  /// );
  /// ```
  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: colorScheme.secondaryContainer,
      foregroundColor: colorScheme.onSecondaryContainer,
      action: action,
    );
  }

  // ─── Info ─────────────────────────────────────────────────────────────────

  /// Shows a neutral informational SnackBar.
  ///
  /// Use for messages that are neither success nor error
  /// (e.g., "Note already pinned.").
  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      backgroundColor: colorScheme.surfaceContainerHigh,
      foregroundColor: colorScheme.onSurface,
      action: action,
    );
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    SnackBarAction? action,
  }) {
    // Dismiss any currently visible SnackBar before showing the new one.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // Row with icon + text — the theme handles float, shape, and font.
        content: Row(
          children: [
            Icon(icon, color: foregroundColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: foregroundColor),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        action: action,
        // Dismiss after 3 seconds for errors, 2 seconds for success/info.
        duration: action != null
            ? const Duration(seconds: 5)
            : const Duration(seconds: 3),
      ),
    );
  }
}
