// lib/shared/widgets/ink_loading.dart
//
// InkLoading — InkFlow's loading indicator widget.
//
// Wraps CircularProgressIndicator with consistent sizing and an optional
// descriptive label. Used to replace content areas while data is loading.
//
// Usage:
//   // Simple spinner
//   const InkLoading()
//
//   // Spinner with label
//   const InkLoading(label: 'Loading notes...')
//
//   // Custom size and color
//   InkLoading(size: 48, color: theme.colorScheme.secondary)
//
// Design note:
//   We center the spinner by default (Column + Center) so it works
//   correctly whether placed in a body, a card, or an overlay.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';

/// InkFlow's branded loading indicator.
///
/// Shows a [CircularProgressIndicator] with an optional text label below.
/// Fades in smoothly using [flutter_animate].
class InkLoading extends StatelessWidget {
  const InkLoading({
    super.key,
    this.label,
    this.size = AppSizes.iconLg,
    this.color,
  });

  /// Optional descriptive text shown below the spinner.
  final String? label;

  /// Diameter of the spinner. Defaults to 32px.
  final double size;

  /// Color of the spinner arc. Defaults to the theme's primary color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: AppStrings.semanticLoading,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: color ?? theme.colorScheme.primary,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: AppSizes.md),
              Text(
                label!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      )
          // Animate entry: fade in over 300ms.
          .animate()
          .fadeIn(duration: AppSizes.durationNormal),
    );
  }
}
