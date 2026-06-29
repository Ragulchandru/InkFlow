// lib/shared/widgets/ink_error_view.dart
//
// InkErrorView — Orynta's generic error state widget.
//
// Shown when an AsyncNotifier's build() throws a Failure — i.e., when
// notesProvider, archivedNotesProvider, etc. surface an AsyncError.
//
// Design:
//   - Maps each sealed Failure subtype to a distinct icon + user-readable message.
//   - Provides an optional Retry button that re-triggers the failed provider.
//   - Matches InkEmptyState layout (icon → title → subtitle → action)
//     so error and empty states feel visually consistent.
//
// Usage:
//   notesAsync.when(
//     loading: () => const InkLoading(),
//     error:   (e, _) => InkErrorView(
//       failure: e as Failure,
//       onRetry: () => ref.invalidate(notesProvider),
//     ),
//     data:    (notes) => NoteListView(notes: notes),
//   );

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/errors/failures.dart';

/// Renders a centered, animated error state for a [Failure].
///
/// Each [Failure] subtype maps to a distinct icon and friendly message.
/// An optional [onRetry] callback renders a "Try again" button.
class InkErrorView extends StatelessWidget {
  const InkErrorView({
    super.key,
    required this.failure,
    this.onRetry,
  });

  /// The domain failure to display. Must be a subtype of [Failure].
  final Failure failure;

  /// Called when the user taps "Try again".
  ///
  /// Typically: `() => ref.invalidate(someProvider)`.
  /// Omit to hide the retry button (e.g., for validation errors).
  final VoidCallback? onRetry;

  // ─── Failure → Display Mapping ─────────────────────────────────────────────

  /// Returns the icon most appropriate for the [Failure] type.
  IconData _iconFor(Failure f) => switch (f) {
        NoteNotFoundFailure() => Icons.search_off_outlined,
        NoteValidationFailure() => Icons.warning_amber_outlined,
        NoteStorageFailure() => Icons.storage_outlined,
        UnexpectedFailure() => Icons.error_outline_rounded,
      };

  /// Returns a concise, user-friendly title for the [Failure] type.
  String _titleFor(Failure f) => switch (f) {
        NoteNotFoundFailure() => 'Note not found',
        NoteValidationFailure() => 'Invalid input',
        NoteStorageFailure() => 'Storage error',
        UnexpectedFailure() => 'Something went wrong',
      };

  /// Returns the subtitle shown below the title.
  ///
  /// For [NoteValidationFailure], the failure's own [Failure.message] is
  /// user-facing (e.g., "Title and body cannot both be empty.").
  /// For infrastructure failures, a generic recovery hint is more helpful.
  String _subtitleFor(Failure f) => switch (f) {
        NoteValidationFailure() => f.message,
        NoteNotFoundFailure() => 'This note may have been deleted.',
        NoteStorageFailure() =>
          'Could not access local storage. Please try again.',
        UnexpectedFailure() =>
          'An unexpected error occurred. Please try again.',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.xl,
          vertical: AppSizes.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Error Icon ─────────────────────────────────────────────────
            Icon(
              _iconFor(failure),
              size: AppSizes.iconHero,
              color: theme.colorScheme.error.withValues(alpha: 0.7),
            )
                .animate()
                .fadeIn(duration: AppSizes.durationNormal)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.0, 1.0),
                  duration: AppSizes.durationSlow,
                  curve: Curves.elasticOut,
                ),

            const SizedBox(height: AppSizes.lg),

            // ── Title ──────────────────────────────────────────────────────
            Text(
              _titleFor(failure),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(
                  duration: AppSizes.durationNormal,
                  delay: const Duration(milliseconds: 150),
                )
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: AppSizes.durationNormal,
                  delay: const Duration(milliseconds: 150),
                ),

            const SizedBox(height: AppSizes.sm),

            // ── Subtitle ───────────────────────────────────────────────────
            Text(
              _subtitleFor(failure),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(
                  duration: AppSizes.durationNormal,
                  delay: const Duration(milliseconds: 250),
                )
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: AppSizes.durationNormal,
                  delay: const Duration(milliseconds: 250),
                ),

            // ── Retry Button ───────────────────────────────────────────────
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.xl),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Try again'),
              )
                  .animate()
                  .fadeIn(
                    duration: AppSizes.durationNormal,
                    delay: const Duration(milliseconds: 350),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
