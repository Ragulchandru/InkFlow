// lib/features/home/presentation/screens/home_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// PHASE 0 PLACEHOLDER
// ─────────────────────────────────────────────────────────────────────────────
// This screen exists solely to:
//   1. Prove the GoRouter + Riverpod + Hive pipeline works end-to-end.
//   2. Visually demonstrate all 5 shared widgets in one screen.
//   3. Verify the light/dark theme toggle persists across restarts.
//
// In Phase 1, this screen will be REPLACED by NotesScreen.
// The GoRouter route '/' will point to NotesScreen instead.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/widgets/ink_button.dart';
import '../../../../shared/widgets/ink_card.dart';
import '../../../../shared/widgets/ink_empty_state.dart';
import '../../../../shared/widgets/ink_loading.dart';
import '../../../../shared/widgets/ink_text_field.dart';

/// Phase 0 demonstration screen.
///
/// Renders all shared widgets so the entire design system can be reviewed
/// and approved before Phase 1 Note CRUD implementation begins.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _textController = TextEditingController();

  bool _showLoading = false;
  bool _showEmpty = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          // ── Theme Toggle ─────────────────────────────────────────────────
          // Demonstrates: ThemeModeNotifier, Hive persistence, flutter_animate.
          Semantics(
            label: AppStrings.semanticThemeToggle,
            child: IconButton(
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              icon: AnimatedSwitcher(
                duration: AppSizes.durationNormal,
                transitionBuilder: (child, animation) => RotationTransition(
                  turns: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  key: ValueKey(isDark),
                ),
              ),
              onPressed: () {
                ref.read(themeModeNotifierProvider.notifier).toggle();
              },
            ),
          ),
          const SizedBox(width: AppSizes.xs),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Phase Badge ─────────────────────────────────────────────────
            const _PhaseStatusCard().animate().fadeIn(duration: AppSizes.durationNormal),

            const SizedBox(height: AppSizes.xl),

            // ── Section: InkTextField ────────────────────────────────────────
            const _SectionLabel(label: 'InkTextField')
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 80))
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: AppSizes.sm),
            InkTextField(
              controller: _textController,
              hint: 'Search notes...',
              prefixIcon: Icons.search_outlined,
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 100))
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: AppSizes.sm),

            InkTextField(
              controller: _textController,
              hint: 'Write your note here...',
              label: 'Note Body',
              maxLines: 4,
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 120))
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: AppSizes.xl),

            // ── Section: InkCard ─────────────────────────────────────────────
            const _SectionLabel(label: 'InkCard')
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 160))
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: AppSizes.sm),

            // Plain card
            InkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample Note Title',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'This is what a note card will look like. It supports '
                    'multi-line content, and the background color can be '
                    'tinted using any of the 8 curated note colors.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 180))
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: AppSizes.sm),

            // Tinted card — Lavender note color
            InkCard(
              backgroundColor: const Color(0xFFD0BCFF),
              onTap: () {},
              child: Row(
                children: [
                  const Icon(Icons.push_pin_outlined, size: AppSizes.iconSm),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      'Lavender tinted card — tappable with ripple',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF21005D),
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 200))
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: AppSizes.xl),

            // ── Section: InkButton ────────────────────────────────────────────
            const _SectionLabel(label: 'InkButton Variants')
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 240))
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: AppSizes.sm),

            InkButton(
              label: 'Primary — Create Note',
              icon: Icons.add,
              onPressed: () {},
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 260)),

            const SizedBox(height: AppSizes.sm),

            InkButton.secondary(
              label: 'Secondary — View Archive',
              icon: Icons.archive_outlined,
              onPressed: () {},
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 280)),

            const SizedBox(height: AppSizes.sm),

            Row(
              children: [
                InkButton.text(
                  label: 'Text Button',
                  onPressed: () {},
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 300)),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: InkButton(
                    label: 'Loading...',
                    isLoading: true,
                    onPressed: () {},
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 310)),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.sm),

            InkButton.destructive(
              label: 'Destructive — Delete Note',
              icon: Icons.delete_outline,
              onPressed: () {},
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 320)),

            const SizedBox(height: AppSizes.xl),

            // ── Section: InkLoading & InkEmptyState ───────────────────────────
            const _SectionLabel(label: 'InkLoading & InkEmptyState')
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 360))
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: AppSizes.sm),

            Row(
              children: [
                Expanded(
                  child: InkButton.secondary(
                    label: _showLoading ? 'Hide Loading' : 'Show Loading',
                    onPressed: () =>
                        setState(() => _showLoading = !_showLoading),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: InkButton.secondary(
                    label: _showEmpty ? 'Hide Empty' : 'Show Empty',
                    onPressed: () =>
                        setState(() => _showEmpty = !_showEmpty),
                  ),
                ),
              ],
            ),

            if (_showLoading) ...[
              const SizedBox(height: AppSizes.xl),
              const InkLoading(label: 'Loading your notes...'),
            ],

            if (_showEmpty) ...[
              const SizedBox(height: AppSizes.md),
              const InkEmptyState(
                icon: Icons.note_outlined,
                title: AppStrings.emptyNotesTitle,
                subtitle: AppStrings.emptyNotesSubtitle,
              ),
            ],

            // Bottom padding for scroll breathing room
            const SizedBox(height: AppSizes.xxxl),
          ],
        ),
      ),
    );
  }
}

// ─── Private sub-widgets ────────────────────────────────────────────────────
// These are small, single-use widgets extracted to keep build() readable.

/// The Phase 0 status card shown at the top of the screen.
class _PhaseStatusCard extends ConsumerWidget {
  const _PhaseStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return InkCard(
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.rocket_launch_outlined,
            color: theme.colorScheme.onPrimaryContainer,
            size: AppSizes.iconLg,
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phase 0 — Foundation ✅',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  'Clean Architecture · Riverpod · GoRouter · Hive · Material 3',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  'Toggle the ☀/🌙 icon in the top-right to switch themes.\n'
                  'The preference is saved to Hive and persists across restarts.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A section label used to separate widget demos.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}
