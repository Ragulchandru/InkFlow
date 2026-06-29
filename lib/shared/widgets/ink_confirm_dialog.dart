// lib/shared/widgets/ink_confirm_dialog.dart
//
// InkConfirmDialog — Orynta's standardised confirmation dialog.
//
// Used for destructive and irreversible actions before executing them.
// Returns a Future<bool> — true = user confirmed, false = user cancelled.
//
// Why a helper instead of inline showDialog?
//   Without this, every screen that has a "Delete" or "Archive" action
//   duplicates the same showDialog(...) setup. Centralising it here means:
//     1. The dialog appearance is consistent across all screens.
//     2. Adding a new confirmation is a single line.
//     3. The styling always inherits from AppTheme.dialogTheme.
//
// Usage:
//
//   // Destructive confirmation (red confirm button):
//   final confirmed = await InkConfirmDialog.show(
//     context,
//     title: 'Delete note?',
//     message: 'This note will be moved to trash.',
//     confirmLabel: 'Delete',
//     isDestructive: true,
//   );
//   if (confirmed) await ref.read(notesProvider.notifier).deleteNote(id);
//
//   // Non-destructive confirmation (primary confirm button):
//   final confirmed = await InkConfirmDialog.show(
//     context,
//     title: 'Archive note?',
//     message: 'You can restore it from the Archive screen.',
//     confirmLabel: 'Archive',
//   );

import 'package:flutter/material.dart';

/// Static helper that shows a standardised confirmation dialog.
///
/// Returns `true` if the user tapped the confirm button,
/// `false` if they cancelled or dismissed the dialog.
abstract final class InkConfirmDialog {
  /// Shows a confirmation dialog and returns the user's choice.
  ///
  /// Parameters:
  ///   - [title]: The question shown at the top (e.g., "Delete note?").
  ///   - [message]: Supporting detail below the title.
  ///   - [confirmLabel]: Label on the primary action button (e.g., "Delete").
  ///   - [cancelLabel]: Label on the cancel button. Defaults to "Cancel".
  ///   - [isDestructive]: When `true`, the confirm button uses the error color.
  ///
  /// The visual styling (shape, background, font) is inherited from
  /// [AppTheme.dialogTheme] — this method only provides content.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      // Barrier dismissal = cancel (false).
      barrierDismissible: true,
      builder: (dialogContext) => _InkConfirmDialogContent(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    // showDialog returns null if dismissed by tapping outside.
    return result ?? false;
  }
}

/// The actual dialog widget — kept private; use [InkConfirmDialog.show].
class _InkConfirmDialogContent extends StatelessWidget {
  const _InkConfirmDialogContent({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        // Cancel — always a text button (low emphasis).
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),

        // Confirm — filled or destructive based on [isDestructive].
        if (isDestructive)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text(confirmLabel),
          )
        else
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
      ],
    );
  }
}
