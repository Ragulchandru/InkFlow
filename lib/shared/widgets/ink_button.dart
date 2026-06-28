// lib/shared/widgets/ink_button.dart
//
// InkButton — InkFlow's universal button component.
//
// Wraps Material 3's native button types (FilledButton, OutlinedButton,
// TextButton) under a single API, so the rest of the app never imports
// those directly. If we ever need to change the button style globally,
// we change it here — not in 50 different screens.
//
// Variants:
//   InkButton(...)                  → primary   (FilledButton)
//   InkButton.secondary(...)        → secondary (OutlinedButton)
//   InkButton.text(...)             → text      (TextButton)
//   InkButton.destructive(...)      → danger    (FilledButton, error color)
//
// Features:
//   - isLoading: replaces label with a CircularProgressIndicator
//   - isFullWidth: true by default (full row); set false for compact
//   - icon: optional leading icon

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_sizes.dart';

/// The button variants available in InkFlow.
enum InkButtonVariant {
  /// Filled background — primary actions (e.g., "Save", "Create").
  primary,

  /// Outlined border, transparent background — secondary actions (e.g., "Cancel").
  secondary,

  /// No background or border — low-emphasis actions (e.g., "Learn more").
  text,

  /// Filled background with error color — destructive actions (e.g., "Delete").
  destructive,
}

/// InkFlow's branded button widget.
///
/// Use the named constructors for ergonomic variant selection:
/// ```dart
/// InkButton(label: 'Save', onPressed: _save)             // primary
/// InkButton.secondary(label: 'Cancel', onPressed: _pop)  // secondary
/// InkButton.text(label: 'Skip', onPressed: _skip)        // text
/// InkButton.destructive(label: 'Delete', onPressed: _del) // destructive
/// ```
class InkButton extends StatelessWidget {
  /// Creates a primary (filled) [InkButton].
  const InkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = InkButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  /// Creates a secondary (outlined) [InkButton].
  const InkButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  }) : variant = InkButtonVariant.secondary;

  /// Creates a text (no background) [InkButton].
  const InkButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = InkButtonVariant.text;

  /// Creates a destructive (error-colored filled) [InkButton].
  const InkButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  }) : variant = InkButtonVariant.destructive;

  // ─── Properties ───────────────────────────────────────────────────────────

  /// The text label displayed on the button.
  final String label;

  /// Called when the button is tapped. Pass `null` to disable.
  final VoidCallback? onPressed;

  /// Which visual style to render.
  final InkButtonVariant variant;

  /// Optional leading icon displayed before the label.
  final IconData? icon;

  /// When true, replaces the label with a [CircularProgressIndicator]
  /// and disables the button.
  final bool isLoading;

  /// When true, the button expands to fill its parent's width.
  /// Defaults to true for primary/secondary/destructive, false for text.
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Build the child widget (label or loading spinner).
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              // Spinner color matches button text color for contrast.
              color: variant == InkButtonVariant.primary ||
                      variant == InkButtonVariant.destructive
                  ? colorScheme.onPrimary
                  : colorScheme.primary,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: AppSizes.iconSm),
                  const SizedBox(width: AppSizes.sm),
                  Text(label),
                ],
              )
            : Text(label);

    final button = switch (variant) {
      InkButtonVariant.primary => FilledButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      InkButtonVariant.secondary => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      InkButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      InkButtonVariant.destructive => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: child,
        ),
    };

    // Wrap in SizedBox to control width behavior.
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: button
          // Subtle scale animation on entry — flutter_animate.
          .animate()
          .fadeIn(duration: AppSizes.durationFast),
    );
  }
}
