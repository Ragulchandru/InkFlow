// lib/shared/widgets/ink_empty_state.dart
//
// InkEmptyState — Orynta's empty-state placeholder widget.
//
// Shown whenever a list or screen has no content to display.
// Each screen passes its own icon, title, and subtitle to communicate
// context clearly to the user.
//
// Usage:
//   const InkEmptyState(
//     icon: Icons.note_outlined,
//     title: AppStrings.emptyNotesTitle,
//     subtitle: AppStrings.emptyNotesSubtitle,
//   )
//
//   // With an action button
//   InkEmptyState(
//     icon: Icons.search_off_outlined,
//     title: 'No results found',
//     subtitle: 'Try a different keyword.',
//     action: InkButton(label: 'Clear Search', onPressed: _clear),
//   )
//
// Animation:
//   The icon, title, and subtitle fade and scale in with a stagger
//   using flutter_animate, giving a polished "reveal" feel.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';

/// Orynta's empty state placeholder.
///
/// Displays a centered icon, title, optional subtitle, and optional action widget.
/// Each element animates in with a staggered delay for a polished entrance.
class InkEmptyState extends StatelessWidget {
  const InkEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize = AppSizes.iconHero,
  });

  /// The icon to display as the visual anchor.
  final IconData icon;

  /// The primary message (e.g., "No notes yet").
  final String title;

  /// A secondary hint message (e.g., "Tap + to create your first note.").
  final String? subtitle;

  /// An optional action widget placed below the subtitle.
  /// Typically an [InkButton] that helps the user take the next step.
  final Widget? action;

  /// Size of the icon. Defaults to 80px.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: AppStrings.semanticEmptyState,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.xl,
            vertical: AppSizes.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon ────────────────────────────────────────────────────
              Icon(
                icon,
                size: iconSize,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              )
                  .animate()
                  .fadeIn(
                    duration: AppSizes.durationNormal,
                    delay: const Duration(milliseconds: 0),
                  )
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.0, 1.0),
                    duration: AppSizes.durationSlow,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: AppSizes.lg),

              // ── Title ───────────────────────────────────────────────────
              Text(
                title,
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

              // ── Subtitle ─────────────────────────────────────────────────
              if (subtitle != null) ...[
                const SizedBox(height: AppSizes.sm),
                Text(
                  subtitle!,
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
              ],

              // ── Action Button ─────────────────────────────────────────────
              if (action != null) ...[
                const SizedBox(height: AppSizes.xl),
                action!
                    .animate()
                    .fadeIn(
                      duration: AppSizes.durationNormal,
                      delay: const Duration(milliseconds: 350),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
