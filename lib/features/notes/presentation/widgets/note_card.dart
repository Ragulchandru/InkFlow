// lib/features/notes/presentation/widgets/note_card.dart
//
// NoteCard — Premium domain-aware note card for Orynta.
//
// Design inspiration: Apple Notes · Craft · Material You
//
// Visual anatomy:
//
//   ┌─────────────────────────────────────┐  ← tinted surface, r=16
//   │  ┌─── Accent strip ───────────┐    │  ← 3px left accent if colored
//   │  │                            │    │
//   │  │  📌  Note title            │    │  ← titleMedium, w600
//   │  │  Preview line 1            │    │  ← bodyMedium, onSurfaceVariant
//   │  │  Preview line 2            │    │
//   │  │                            │    │
//   │  │  Jun 28          ♥         │    │  ← footer: timestamp + favorite
//   │  └────────────────────────────┘    │
//   └─────────────────────────────────────┘
//
// Premium details:
//   - Soft shadow instead of flat elevation
//   - Accent bar (3px left border) when note has a custom color
//   - Generous padding and comfortable line-height
//   - Animated entrance: fade + subtle slide (no bounciness)
//   - Favorite animates between heart states with scale pulse
//   - Title uses titleMedium (larger than titleSmall — more legible on cards)
//   - Body preview uses bodyMedium with 2 lines
//   - Dark mode: color is desaturated to avoid garish brightness

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/note_entity.dart';

/// A premium domain-aware card widget for a single [NoteEntity].
///
/// Renders color tinting, title, body preview, pin indicator, favorite
/// icon, and a relative/absolute timestamp. Tapping calls [onTap];
/// long-pressing opens the [_NoteActionsSheet] bottom sheet.
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onArchive,
    this.onDelete,
    this.onTogglePin,
    this.onToggleFavorite,
    this.animationDelay = Duration.zero,
  });

  /// The note to render.
  final NoteEntity note;

  /// Called when the card is tapped (navigate to editor).
  final VoidCallback onTap;

  /// Called when the user selects "Archive" from the bottom sheet.
  final VoidCallback? onArchive;

  /// Called when the user selects "Move to trash" from the bottom sheet.
  final VoidCallback? onDelete;

  /// Called when the user selects "Pin / Unpin" from the bottom sheet.
  final VoidCallback? onTogglePin;

  /// Called when the user taps the favorite heart icon directly on the card.
  final VoidCallback? onToggleFavorite;

  /// Stagger delay for list entrance animations.
  final Duration animationDelay;

  // ─── Color ────────────────────────────────────────────────────────────────

  bool get _hasCustomColor =>
      note.color != null && note.color != AppColors.noteColorDefault;

  /// Returns the tinted surface color for the card background.
  Color _surfaceColor(BuildContext context) {
    if (!_hasCustomColor) {
      return Theme.of(context).colorScheme.surfaceContainerLow;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = Color(note.color!);
    // Dark mode: blend with black to desaturate pastels.
    return isDark
        ? Color.alphaBlend(Colors.black.withValues(alpha: 0.45), base)
        : base;
  }

  /// Returns the accent color for the left border strip.
  Color _accentColor(BuildContext context) {
    final base = Color(note.color!);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Color.alphaBlend(Colors.black.withValues(alpha: 0.2), base)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.15), base);
  }

  // ─── Timestamp ────────────────────────────────────────────────────────────

  String _timestamp() {
    final now = DateTime.now();
    final diff = now.difference(note.updatedAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = months[note.updatedAt.month - 1];
    final d = note.updatedAt.day;
    final y = note.updatedAt.year;
    return y == now.year ? '$m $d' : '$m $d, $y';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = _surfaceColor(context);
    final hasTitle = note.title.isNotEmpty;
    final hasBody = note.body.isNotEmpty;

    // On-surface text color — for colored cards, darken for contrast.
    final onCard = _hasCustomColor
        ? (isDark
            ? Colors.white.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.80))
        : theme.colorScheme.onSurface;

    final onCardVariant = _hasCustomColor
        ? (isDark
            ? Colors.white.withValues(alpha: 0.60)
            : Colors.black.withValues(alpha: 0.55))
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showActionsSheet(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            // Subtle shadow — softer than Card's default.
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.30)
                    : Colors.black.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Stack(
              children: [
                // ── Card content ─────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    _hasCustomColor ? AppSizes.md + 4 : AppSizes.md,
                    AppSizes.md,
                    AppSizes.sm,
                    AppSizes.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Pin indicator ──────────────────────────────
                      if (note.isPinned) ...[
                        Icon(
                          Icons.push_pin_rounded,
                          size: AppSizes.iconSm,
                          color: onCardVariant,
                        ),
                        const SizedBox(height: 6),
                      ],

                      // ── Title ──────────────────────────────────────
                      if (hasTitle) ...[
                        Text(
                          note.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: onCard,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasBody) const SizedBox(height: 6),
                      ],

                      // ── Body preview ───────────────────────────────
                      if (hasBody)
                        Text(
                          note.body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: onCardVariant,
                            height: 1.45,
                          ),
                          maxLines: hasTitle ? 2 : 4,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: AppSizes.sm),

                      // ── Footer ─────────────────────────────────────
                      Row(
                        children: [
                          Text(
                            _timestamp(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: onCardVariant.withValues(alpha: 0.75),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const Spacer(),
                          // Favorite icon — direct tap target
                          GestureDetector(
                            onTap: onToggleFavorite,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSizes.sm, AppSizes.xs,
                                AppSizes.xs, AppSizes.xs,
                              ),
                              child: Icon(
                                note.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 16,
                                color: note.isFavorite
                                    ? theme.colorScheme.error
                                    : onCardVariant.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Colored left accent strip ────────────────────────────
                if (_hasCustomColor)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      color: _accentColor(context),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    )
        // Staggered entrance: fade + very gentle upward slide.
        .animate(delay: animationDelay)
        .fadeIn(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.06,
          end: 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
  }

  void _showActionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteActionsSheet(
        note: note,
        onTogglePin: onTogglePin,
        onArchive: onArchive,
        onDelete: onDelete,
      ),
    );
  }
}

// ─── Premium Context Actions Bottom Sheet ─────────────────────────────────────

class _NoteActionsSheet extends StatelessWidget {
  const _NoteActionsSheet({
    required this.note,
    this.onTogglePin,
    this.onArchive,
    this.onDelete,
  });

  final NoteEntity note;
  final VoidCallback? onTogglePin;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusXl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh
                .withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag handle ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSizes.sm,
                    bottom: AppSizes.xs,
                  ),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                ),

                // ── Note title preview ──────────────────────────────────
                if (note.title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.lg, AppSizes.sm, AppSizes.lg, AppSizes.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                Divider(
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.5),
                  thickness: 1,
                  height: AppSizes.md,
                  indent: AppSizes.lg,
                  endIndent: AppSizes.lg,
                ),

                // ── Actions ─────────────────────────────────────────────
                if (onTogglePin != null)
                  _ActionTile(
                    icon: note.isPinned
                        ? Icons.push_pin_outlined
                        : Icons.push_pin_rounded,
                    label: note.isPinned ? 'Unpin note' : 'Pin note',
                    onTap: () {
                      Navigator.of(context).pop();
                      onTogglePin!();
                    },
                  ),

                if (onArchive != null)
                  _ActionTile(
                    icon: Icons.archive_outlined,
                    label: 'Archive',
                    onTap: () {
                      Navigator.of(context).pop();
                      onArchive!();
                    },
                  ),

                if (onDelete != null)
                  _ActionTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Move to trash',
                    color: theme.colorScheme.error,
                    onTap: () {
                      Navigator.of(context).pop();
                      onDelete!();
                    },
                  ),

                const SizedBox(height: AppSizes.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = color ?? theme.colorScheme.onSurface;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: resolved.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Icon(icon, color: resolved, size: AppSizes.iconMd),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: resolved,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
    );
  }
}
