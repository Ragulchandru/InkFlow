// lib/shared/widgets/ink_card.dart
//
// InkCard — InkFlow's branded container/card widget.
//
// Built on top of Flutter's Material widget (not Card) for maximum control:
//   - Supports custom background colors (critical for note color tinting).
//   - Ink ripple effect on tap via InkWell.
//   - Consistent border radius and padding across the app.
//   - Optionally add a border.
//
// Usage:
//   // Basic card
//   InkCard(child: Text('Hello'))
//
//   // Tappable card (e.g., note list item)
//   InkCard(onTap: () => navigateToNote(), child: NoteCardContent())
//
//   // Note with background color
//   InkCard(
//     backgroundColor: Color(note.color ?? AppColors.noteColorDefault),
//     child: NoteCardContent(),
//   )

import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

/// InkFlow's branded surface/container card.
///
/// Wraps content in a rounded, optionally-colored Material container with
/// a proper InkWell ripple for tappable cards.
class InkCard extends StatelessWidget {
  const InkCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
    this.border,
    this.margin,
  });

  // ─── Properties ───────────────────────────────────────────────────────────

  /// The widget to display inside the card.
  final Widget child;

  /// If provided, the card becomes tappable with a ripple effect.
  final VoidCallback? onTap;

  /// If provided, the card becomes long-pressable (e.g., for context menus).
  final VoidCallback? onLongPress;

  /// Custom background color.
  ///
  /// Defaults to [ColorScheme.surfaceContainerLow] (from the active theme).
  /// For note color tinting, pass `Color(note.color ?? AppColors.noteColorDefault)`.
  final Color? backgroundColor;

  /// Inner padding. Defaults to `EdgeInsets.all(AppSizes.md)`.
  final EdgeInsetsGeometry? padding;

  /// Corner radius. Defaults to [AppSizes.radiusMd] (12px).
  final double? borderRadius;

  /// Optional border around the card.
  final BoxBorder? border;

  /// Outer margin around the card.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedBorderRadius =
        BorderRadius.circular(borderRadius ?? AppSizes.radiusMd);
    final resolvedBg =
        backgroundColor ?? theme.colorScheme.surfaceContainerLow;

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSizes.cardPadding),
      child: child,
    );

    // If the card is not tappable, skip the InkWell entirely.
    // This avoids an unnecessary tap splash zone.
    final cardChild = (onTap != null || onLongPress != null)
        ? InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: resolvedBorderRadius,
            child: content,
          )
        : content;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: resolvedBorderRadius,
        border: border,
      ),
      // ClipRRect ensures the InkWell ripple is clipped to the card shape.
      child: ClipRRect(
        borderRadius: resolvedBorderRadius,
        child: Material(
          // Material must be transparent here because the Container
          // above provides the background color.
          color: Colors.transparent,
          child: cardChild,
        ),
      ),
    );
  }
}
