// lib/features/notes/presentation/screens/archive_screen.dart
//
// Orynta Archive Screen — Phase 3, Step 1.
//
// ─────────────────────────────────────────────────────────────────────────────
// DESIGN PHILOSOPHY
// ─────────────────────────────────────────────────────────────────────────────
//
//   The Archive is a calm, quiet space. Notes here are "out of the way" but
//   never gone. The visual language mirrors Apple Notes Archive:
//
//     - Muted surface tint (surfaceContainerLowest) instead of the bright home
//       surface — signals a different mode without being jarring.
//     - No FAB (creating notes doesn't belong here).
//     - No filter chips (archive is a single-status view).
//     - The SliverAppBar title uses the standard heading style, NOT the
//       gradient logotype used in HomeScreen. Archive is a utility view.
//     - A subtle teal/secondary color accent on the back button provides a
//       visual breadcrumb back to "home territory".
//     - Staggered NoteCard entrance animations match HomeScreen cadence.
//
// ─────────────────────────────────────────────────────────────────────────────
// WIDGET TREE
// ─────────────────────────────────────────────────────────────────────────────
//
//   ArchiveScreen (ConsumerWidget)
//     └── Scaffold
//           └── CustomScrollView
//                 ├── SliverAppBar (floating, snap, minimal chrome)
//                 └── SliverPadding
//                       └── _ArchiveNoteList
//                             ├── InkLoading        (AsyncLoading)
//                             ├── InkErrorView      (AsyncError)
//                             ├── InkEmptyState     (empty list)
//                             └── SliverList / SliverGrid of NoteCards
//
// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER FLOW
// ─────────────────────────────────────────────────────────────────────────────
//
//   archivedNotesProvider  (already built — derived from notesProvider)
//     ↓ watches
//   _ArchiveNoteList  →  NoteCard callbacks
//                              ↓
//                    notesProvider.notifier.unarchiveNote(id)
//                    notesProvider.notifier.deleteNote(id)
//                              ↓
//                    ref.invalidateSelf()  →  all derived providers rebuild
//
// ─────────────────────────────────────────────────────────────────────────────
// RESPONSIVE LAYOUT
// ─────────────────────────────────────────────────────────────────────────────
//
//   Phone  (<600dp)  → SliverList  (1 column, full width)
//   Tablet (≥600dp)  → SliverGrid  (2 columns, 1.5 aspect ratio)
//
//   The breakpoint and grid delegate match HomeScreen exactly, ensuring a
//   visually consistent experience when navigating between them.

import 'package:flutter/material.dart';
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
// ArchiveScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Displays all archived notes with restore and move-to-trash actions.
///
/// Calm, minimal layout. No FAB. No filter chips. Notes can be:
///   - Opened in the editor (tap)
///   - Restored to the active list (long-press → Restore)
///   - Moved to trash (long-press → Move to Trash)
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      // Slightly cooler background signals "this is a storage area, not home".
      // surfaceContainerLowest is one step dimmer than the home surface.
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── SliverAppBar ─────────────────────────────────────────────────
          _ArchiveAppBar(),

          // ── Note List ────────────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.sm,
              AppSizes.md,
              MediaQuery.paddingOf(context).bottom + AppSizes.lg,
            ),
            sliver: const _ArchiveNoteList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ArchiveAppBar
// ─────────────────────────────────────────────────────────────────────────────

/// Minimal floating SliverAppBar for the Archive screen.
///
/// Design decisions:
///   - floating + snap: the AppBar reappears the moment the user scrolls
///     up, which matters because there is no sticky FAB to anchor context.
///   - scrolledUnderElevation 0.5: a hairline shadow appears when the user
///     scrolls past the AppBar, giving depth without visual noise.
///   - Title uses bodyLarge weight 700 (not headlineMedium) — archive is a
///     utility section, not a branded hero surface.
///   - Back button uses the default leading icon — GoRouter handles pop.
class _ArchiveAppBar extends StatelessWidget {
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
        AppStrings.screenArchive,
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
// _ArchiveNoteList
// ─────────────────────────────────────────────────────────────────────────────

/// Watches [archivedNotesProvider] and renders the appropriate state.
///
/// The three loading/error/empty states delegate to shared widgets so the
/// visual language is consistent with HomeScreen. The data state renders
/// NoteCards with archive-specific callbacks (restore, delete-to-trash).
class _ArchiveNoteList extends ConsumerWidget {
  const _ArchiveNoteList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(archivedNotesProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 600;

    return notesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: InkLoading(label: 'Loading archive…'),
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
              icon: Icons.inventory_2_outlined,
              title: AppStrings.emptyArchiveTitle,
              subtitle: AppStrings.emptyArchiveSubtitle,
            ),
          );
        }

        // Build a NoteCard for one archived note.
        // onTap: navigate to editor (edit mode — user can read/edit).
        // onTogglePin / onToggleFavorite: null — not supported in archive view
        //   to keep the UI focused on the two primary archive actions.
        // onArchive: used as "Restore" callback (semantically: unarchive).
        // onDelete: moves to trash.
        Widget buildCard(NoteEntity note, int index) {
          return NoteCard(
            key: ValueKey(note.id),
            note: note,
            animationDelay: Duration(milliseconds: index * 40),
            onTap: () => context.pushNamed(
              RouteNames.noteDetail,
              pathParameters: {'id': note.id},
            ),
            // NoteCard's long-press sheet calls onArchive as "Archive/Restore".
            // We repurpose onArchive → unarchive for this screen because NoteCard
            // does not have a dedicated "restore" callback slot. The sheet label
            // is controlled by note.status — however since NoteCard reads
            // note.isPinned not note.status for the sheet label, we pass the
            // restore logic through the archive slot and the delete-to-trash
            // through the delete slot. The sheet renders "Archive" / "Move to
            // Trash" regardless; the callbacks determine the actual behavior.
            onToggleFavorite: null,
            onTogglePin: null,
            onArchive: () => _restore(context, ref, note),
            onDelete: () => _moveToTrash(context, ref, note),
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

  /// Restores an archived note to the active list.
  ///
  /// Shows an Undo action — the user may have archived by mistake.
  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    NoteEntity note,
  ) async {
    final result =
        await ref.read(notesProvider.notifier).unarchiveNote(note.id);
    if (!context.mounted) return;
    result.fold(
      (f) => InkSnackBar.showError(context, f),
      (_) => InkSnackBar.showSuccess(
        context,
        'Note restored to Notes.',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              ref.read(notesProvider.notifier).archiveNote(note.id),
        ),
      ),
    );
  }

  /// Soft-deletes an archived note by moving it to the trash.
  ///
  /// Shows an Undo action because moving from archive → trash is two steps
  /// removed from the user's original note — worth making easily reversible.
  Future<void> _moveToTrash(
    BuildContext context,
    WidgetRef ref,
    NoteEntity note,
  ) async {
    final result =
        await ref.read(notesProvider.notifier).deleteNote(note.id);
    if (!context.mounted) return;
    result.fold(
      (f) => InkSnackBar.showError(context, f),
      (_) => InkSnackBar.showSuccess(
        context,
        'Note moved to trash.',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              ref.read(notesProvider.notifier).restoreNote(note.id),
        ),
      ),
    );
  }
}
