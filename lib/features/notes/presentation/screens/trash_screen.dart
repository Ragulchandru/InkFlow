// lib/features/notes/presentation/screens/trash_screen.dart
//
// Orynta Trash Screen — Phase 3, Step 1.
//
// ─────────────────────────────────────────────────────────────────────────────
// DESIGN PHILOSOPHY
// ─────────────────────────────────────────────────────────────────────────────
//
//   The Trash should feel temporary — not scary. The visual language is:
//
//     - Same muted surface as archive (surfaceContainerLowest) — it's a
//       storage area, not the primary workspace.
//     - An informational banner at the top explains what trash is and that
//       notes can be restored. It is NOT a warning-colored caution banner —
//       the tone is calm and educational, not alarming.
//     - No red colors on the notes themselves.
//     - The only available action is Restore — consistent with the spec.
//       Permanent delete and Empty Trash are Phase 3 Step 2.
//
// ─────────────────────────────────────────────────────────────────────────────
// WIDGET TREE
// ─────────────────────────────────────────────────────────────────────────────
//
//   TrashScreen (ConsumerWidget)
//     └── Scaffold
//           └── CustomScrollView
//                 ├── SliverAppBar (floating, snap, minimal chrome)
//                 ├── SliverToBoxAdapter → _TrashInfoBanner
//                 └── SliverPadding
//                       └── _TrashNoteList
//                             ├── InkLoading        (AsyncLoading)
//                             ├── InkErrorView      (AsyncError)
//                             ├── InkEmptyState     (empty list)
//                             └── SliverList / SliverGrid of NoteCards
//
// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER FLOW
// ─────────────────────────────────────────────────────────────────────────────
//
//   trashedNotesProvider  (already built — derived from notesProvider)
//     ↓ watches
//   _TrashNoteList  →  NoteCard onArchive callback (repurposed as Restore)
//                              ↓
//                    notesProvider.notifier.restoreNote(id)
//                              ↓
//                    ref.invalidateSelf()  →  all derived providers rebuild
//
// ─────────────────────────────────────────────────────────────────────────────
// RESPONSIVE LAYOUT
// ─────────────────────────────────────────────────────────────────────────────
//
//   Phone  (<600dp)  → SliverList  (1 column, full width)
//   Tablet (≥600dp)  → SliverGrid  (2 columns, 1.5 aspect ratio)

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/ink_empty_state.dart';
import '../../../../shared/widgets/ink_error_view.dart';
import '../../../../shared/widgets/ink_loading.dart';
import '../../../../shared/widgets/ink_snack_bar.dart';
import '../../../notes/domain/entities/note_entity.dart';
import '../providers/notes_notifier.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TrashScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Displays all trashed notes with a restore action.
///
/// The tone is calm and informational. Notes are shown with a muted surface.
/// The only available action on this screen is Restore — permanent delete
/// and Empty Trash are deferred to Phase 3 Step 2.
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── SliverAppBar ──────────────────────────────────────────────────
          _TrashAppBar(),

          // ── Informational Banner ─────────────────────────────────────────
          const SliverToBoxAdapter(child: _TrashInfoBanner()),

          // ── Note List ────────────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.xs,
              AppSizes.md,
              MediaQuery.paddingOf(context).bottom + AppSizes.lg,
            ),
            sliver: const _TrashNoteList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrashAppBar
// ─────────────────────────────────────────────────────────────────────────────

/// Minimal floating SliverAppBar for the Trash screen.
///
/// Visually identical to [_ArchiveAppBar] — both are utility views with the
/// same chrome level. Intentional: it prevents the Trash from feeling "more
/// dangerous" than Archive due to purely visual differences.
class _TrashAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      floating: true,
      snap: true,
      toolbarHeight: 64,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        tooltip: 'Back',
        onPressed: () => context.pop(),
      ),
      title: Text(
        AppStrings.screenTrash,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrashInfoBanner
// ─────────────────────────────────────────────────────────────────────────────

/// A calm, neutral informational strip shown at the top of the trash list.
///
/// Design decisions:
///   - Uses [surfaceContainerHigh] + [onSurfaceVariant] — not warning colors.
///     The spec says "not scary" — a yellow/orange banner would undermine that.
///   - Rounded corners and generous padding to feel like a card, not a system
///     alert. It should read as a contextual hint, not an error state.
///   - Uses an info icon rather than a warning triangle.
///   - Fades in with a 100ms delay so it doesn't compete with the AppBar
///     entrance animation.
///   - Hidden (zero-height) when the list is empty — the empty state is
///     self-explanatory and the banner would be redundant.
class _TrashInfoBanner extends ConsumerWidget {
  const _TrashInfoBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(trashedNotesProvider);
    final hasNotes = notesAsync.valueOrNull?.isNotEmpty ?? false;
    if (!hasNotes) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.sm,
        AppSizes.md,
        AppSizes.xs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: AppSizes.iconSm,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                'Items remain here until you restore them.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: AppSizes.durationNormal,
          delay: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrashNoteList
// ─────────────────────────────────────────────────────────────────────────────

/// Watches [trashedNotesProvider] and renders the appropriate state.
///
/// The only available action is Restore. The NoteCard's onArchive callback
/// is repurposed to call [restoreNote] — the same pattern used in
/// [ArchiveScreen] to avoid creating a new callback slot on NoteCard.
///
/// onDelete is explicitly null — "Move to Trash" makes no sense when already
/// in the trash, and the sheet simply omits the action when the callback is null.
class _TrashNoteList extends ConsumerWidget {
  const _TrashNoteList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(trashedNotesProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 600;

    return notesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: InkLoading(label: 'Loading trash…'),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: InkErrorView(
          failure: e as Failure,
          onRetry: () => ref.invalidate(notesProvider),
        ),
      ),
      data: (notes) {
        if (notes.isEmpty) {
          return const SliverToBoxAdapter(
            child: InkEmptyState(
              icon: Icons.delete_outline_rounded,
              title: AppStrings.emptyTrashTitle,
              subtitle: AppStrings.emptyTrashSubtitle,
            ),
          );
        }

        // Build a NoteCard for one trashed note.
        // onTap:          Open in editor — user may want to read before deciding.
        // onArchive:      Repurposed as Restore (see class-level comment).
        // onDelete:       null — "Move to Trash" is meaningless when in trash.
        // onTogglePin:    null — pinning is only meaningful in the active list.
        // onToggleFavorite: null — same rationale as pin.
        Widget buildCard(NoteEntity note, int index) {
          return NoteCard(
            key: ValueKey(note.id),
            note: note,
            animationDelay: Duration(milliseconds: index * 40),
            onTap: () => context.pushNamed(
              RouteNames.noteDetail,
              pathParameters: {'id': note.id},
            ),
            onToggleFavorite: null,
            onTogglePin: null,
            onArchive: () => _restore(context, ref, note),
            onDelete: null,
          );
        }

        // ── Tablet: 2-column grid ────────────────────────────────────────
        if (isTablet) {
          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSizes.sm,
              mainAxisSpacing: AppSizes.sm,
              childAspectRatio: 1.4,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, index) => buildCard(notes[index], index),
              childCount: notes.length,
            ),
          );
        }

        // ── Phone: 1-column list ──────────────────────────────────────────
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: buildCard(notes[index], index),
            ),
            childCount: notes.length,
          ),
        );
      },
    );
  }

  // ─── Mutation Handlers ─────────────────────────────────────────────────────

  /// Restores a trashed note back to the active list.
  ///
  /// Shows an Undo action — the user might restore by accident.
  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    NoteEntity note,
  ) async {
    final result =
        await ref.read(notesProvider.notifier).restoreNote(note.id);
    if (!context.mounted) return;
    result.fold(
      (f) => InkSnackBar.showError(context, f),
      (_) => InkSnackBar.showSuccess(
        context,
        'Note restored to Notes.',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              ref.read(notesProvider.notifier).deleteNote(note.id),
        ),
      ),
    );
  }
}
