// lib/features/home/presentation/screens/home_screen.dart
//
// Orynta Home Screen — Phase 2, Step 8.
//
// ─────────────────────────────────────────────────────────────────────────────
// WIDGET TREE OVERVIEW
// ─────────────────────────────────────────────────────────────────────────────
//
// HomeScreen (ConsumerStatefulWidget)
//   └── Scaffold
//         ├── AppBar (_HomeAppBar)
//         │     ├── "Orynta" title + Playfair Display logotype
//         │     ├── Search icon → expands InkSearchBar
//         ├── Body (CustomScrollView)
//         │     ├── SliverToBoxAdapter → _SearchBar (visible when _isSearching)
//         │     ├── SliverToBoxAdapter → _FilterChips (All / Favorites / Pinned)
//         │     ├── SliverPadding
//         │     │     └── _NoteList (switches on filteredActiveNotesProvider)
//         │     │           ├── InkLoading (AsyncLoading)
//         │     │           ├── InkErrorView (AsyncError)
//         │     │           ├── InkEmptyState (empty list)
//         │     │           └── SliverList of NoteCard widgets (data)
//         └── FAB → _HomeFab (Extended FAB, placeholder)
//
// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER FLOW
// ─────────────────────────────────────────────────────────────────────────────
//
//  User creates a note
//    → ref.read(notesProvider.notifier).createNote(params)
//      → Hive write
//      → ref.invalidateSelf()
//        → notesProvider rebuilds (AsyncNotifier fetches all notes)
//          → filteredActiveNotesProvider rebuilds (derived, synchronous)
//            → _NoteList rebuilds → new NoteCard appears
//
//  User taps a filter chip
//    → ref.read(noteFilterProvider.notifier).state = NoteFilter.favorites
//      → filteredActiveNotesProvider re-runs switch (synchronous, no Hive read)
//        → _NoteList rebuilds with the new filtered + sorted list
//
// ─────────────────────────────────────────────────────────────────────────────
// MATERIAL 3 LAYOUT DECISIONS
// ─────────────────────────────────────────────────────────────────────────────
//
//  1. CustomScrollView + Slivers:
//     Allows the SearchBar and FilterChips to scroll away naturally as the
//     user scrolls down through notes — more premium than a fixed Column.
//
//  2. No NestedScrollView:
//     NestScrollView causes jank on Android when a SliverList is inside.
//     CustomScrollView with SliverAppBar is the correct M3 pattern.
//
//  3. Extended FAB (not round FAB):
//     M3 spec recommends Extended FABs for primary create actions on screens
//     where there is abundant horizontal space. It makes the primary action
//     immediately recognizable without needing a tooltip.
//
//  4. Filter chips (not tabs):
//     Tab bars are for full page navigation. Filter chips are for in-page
//     filtering of a single list — this is the M3-correct component.
//
//  5. Responsive grid:
//     On phones (< 600dp wide): 1-column list.
//     On tablets (≥ 600dp wide): 2-column staggered grid.
//     Implemented via LayoutBuilder + SliverGrid / SliverList.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/widgets/ink_empty_state.dart';
import '../../../../shared/widgets/ink_error_view.dart';
import '../../../../shared/widgets/ink_loading.dart';
import '../../../../shared/widgets/ink_snack_bar.dart';
import '../../../notes/domain/entities/note_entity.dart';
import '../../../notes/presentation/providers/note_filter.dart';
import '../../../notes/presentation/providers/notes_notifier.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../notes/presentation/widgets/note_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen
// ─────────────────────────────────────────────────────────────────────────────

/// The main screen of Orynta — displays the user's active notes.
///
/// Uses [ConsumerStatefulWidget] for local search-bar expand/collapse state
/// while delegating all note data to Riverpod providers.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Controls whether the search bar is visible below the AppBar.
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Opens the search bar and focuses the text field.
  void _openSearch() {
    setState(() => _isSearching = true);
    // Defer focus to after the widget rebuilds.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _searchFocus.requestFocus(),
    );
  }

  /// Closes the search bar, clears the query, and releases the provider.
  void _closeSearch() {
    setState(() => _isSearching = false);
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    _searchFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── SliverAppBar ────────────────────────────────────────────────
          _HomeAppBar(
            isSearching: _isSearching,
            onSearchTap: _openSearch,
            onCloseTap: _closeSearch,
          ),

          // ── Search Bar ──────────────────────────────────────────────────
          if (_isSearching)
            SliverToBoxAdapter(
              child: _SearchBar(
                controller: _searchController,
                focusNode: _searchFocus,
              ).animate().fadeIn(duration: AppSizes.durationFast).slideY(
                    begin: -0.1,
                    end: 0,
                    duration: AppSizes.durationFast,
                  ),
            ),

          // ── Filter Chips (hidden during search) ─────────────────────────
          if (!_isSearching)
            const SliverToBoxAdapter(child: _FilterChips()),

          // ── Note List ───────────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.sm,
              AppSizes.md,
              // Bottom padding — room for the FAB + safe area.
              MediaQuery.paddingOf(context).bottom + AppSizes.xxxl,
            ),
            sliver: _isSearching
                ? const _SearchResultsList()
                : const _NoteList(),
          ),
        ],
      ),

      // ── Extended FAB ─────────────────────────────────────────────────────
      floatingActionButton: _isSearching ? null : const _HomeFab(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HomeAppBar
// ─────────────────────────────────────────────────────────────────────────────

/// The SliverAppBar for the Home screen.
///
/// - Floating: appears immediately when scrolling up (not pinned).
/// - snap: snaps fully into view rather than partially appearing.
/// - Title: "Orynta" logotype in Playfair Display via the theme.
class _HomeAppBar extends ConsumerWidget {
  const _HomeAppBar({
    required this.isSearching,
    required this.onSearchTap,
    required this.onCloseTap,
  });

  final bool isSearching;
  final VoidCallback onSearchTap;
  final VoidCallback onCloseTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

    return SliverAppBar(
      floating: true,
      snap: true,
      toolbarHeight: 64,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: isDark
              ? [theme.colorScheme.primary, theme.colorScheme.tertiary]
              : [
                  theme.colorScheme.primary,
                  Color.lerp(
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                    0.6,
                  )!,
                ],
        ).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: Text(
          AppStrings.appName,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
        ),
      ),
      actions: [
        if (!isSearching)
          _AppBarIconButton(
            icon: Icons.search_rounded,
            tooltip: 'Search notes',
            onTap: onSearchTap,
          ),
        if (isSearching)
          _AppBarIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Close search',
            onTap: onCloseTap,
          ),
        _AppBarIconButton(
          icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          tooltip: isDark ? 'Light mode' : 'Dark mode',
          onTap: () => ref.read(themeModeNotifierProvider.notifier).toggle(),
          animate: true,
          animateKey: isDark,
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          tooltip: 'More options',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          onSelected: (value) {
            switch (value) {
              case 'archive':
                context.pushNamed(RouteNames.archive);
              case 'trash':
                context.pushNamed(RouteNames.trash);
              case 'settings':
                // Settings screen — Phase 3 Step 2.
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'archive', child: Text('Archive')),
            PopupMenuItem(value: 'trash', child: Text('Trash')),
            PopupMenuItem(value: 'settings', child: Text('Settings')),
          ],
        ),
        const SizedBox(width: AppSizes.xs),
      ],
    );
  }
}

/// Rounded icon button for the AppBar — slightly larger hit area, uniform style.
class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.animate = false,
    this.animateKey,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool animate;
  final Object? animateKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconWidget = Icon(
      icon,
      color: theme.colorScheme.onSurfaceVariant,
      key: animate ? ValueKey(animateKey) : null,
    );

    return IconButton(
      icon: animate
          ? AnimatedSwitcher(
              duration: AppSizes.durationNormal,
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: iconWidget,
            )
          : iconWidget,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
      onPressed: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SearchBar
// ─────────────────────────────────────────────────────────────────────────────

/// An inline search field shown below the AppBar when search is active.
///
/// Writes the text value to [searchQueryProvider] on every keystroke,
/// which triggers [searchResultsProvider] to re-execute.
class _SearchBar extends ConsumerWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md, AppSizes.xs, AppSizes.md, AppSizes.sm,
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Search your notes…',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    onPressed: () {
                      controller.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            isDense: true,
            filled: false,
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FilterChips
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal scrollable row of filter chips.
///
/// Watches [noteFilterProvider]. Selecting a chip writes a new [NoteFilter]
/// value, which causes [filteredActiveNotesProvider] to re-derive from the
/// same notes list — no Hive read needed.
class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(noteFilterProvider);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        children: NoteFilter.values.map((filter) {
          final isSelected = filter == activeFilter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: FilterChip(
              label: Text(_labelFor(filter)),
              selected: isSelected,
              showCheckmark: false,
              avatar: Icon(
                _iconFor(filter),
                size: AppSizes.iconSm,
              ),
              onSelected: (_) {
                ref.read(noteFilterProvider.notifier).state = filter;
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _labelFor(NoteFilter filter) => switch (filter) {
        NoteFilter.all => 'All',
        NoteFilter.favorites => 'Favorites',
        NoteFilter.pinned => 'Pinned',
      };

  IconData _iconFor(NoteFilter filter) => switch (filter) {
        NoteFilter.all => Icons.notes_rounded,
        NoteFilter.favorites => Icons.favorite_border_rounded,
        NoteFilter.pinned => Icons.push_pin_outlined,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// _NoteList
// ─────────────────────────────────────────────────────────────────────────────

/// Watches [filteredActiveNotesProvider] and renders the appropriate state.
///
/// Adapts between phone (1-column SliverList) and tablet (2-column SliverGrid)
/// using [LayoutBuilder] via the MediaQuery breakpoint.
///
/// How NoteCard is used:
///   Each [NoteCard] is constructed with the [NoteEntity] and four callbacks.
///   All callbacks call [notesProvider.notifier] methods — the card itself
///   contains zero business logic. After each mutation, [notesProvider]
///   invalidates itself, causing [filteredActiveNotesProvider] to re-derive
///   and all [NoteCard]s to rebuild with fresh data.
class _NoteList extends ConsumerWidget {
  const _NoteList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(filteredActiveNotesProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 600;

    return notesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: InkLoading(label: 'Loading notes...'),
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
              icon: Icons.edit_note_rounded,
              title: AppStrings.emptyNotesTitle,
              subtitle: AppStrings.emptyNotesSubtitle,
            ),
          );
        }

        // Build NoteCard builders once — shared by both list and grid.
        Widget buildCard(NoteEntity note, int index) {
          return NoteCard(
            key: ValueKey(note.id),
            note: note,
            animationDelay: Duration(milliseconds: index * 40),
            onTap: () {
              context.pushNamed(
                RouteNames.noteDetail,
                pathParameters: {'id': note.id},
              );
            },
            onToggleFavorite: () => _toggleFavorite(context, ref, note),
            onTogglePin: () => _togglePin(context, ref, note),
            onArchive: () => _archive(context, ref, note),
            onDelete: () => _delete(context, ref, note),
          );
        }

        // ── Tablet: 2-column grid ──────────────────────────────────────────
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

        // ── Phone: 1-column list ───────────────────────────────────────────
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

  // ─── Mutation Handlers ──────────────────────────────────────────────────────

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    NoteEntity note,
  ) async {
    final result =
        await ref.read(notesProvider.notifier).toggleFavorite(note.id);
    if (!context.mounted) return;
    result.fold(
      (f) => InkSnackBar.showError(context, f),
      (_) => InkSnackBar.showSuccess(
        context,
        note.isFavorite ? 'Removed from favorites.' : 'Added to favorites.',
      ),
    );
  }

  Future<void> _togglePin(
    BuildContext context,
    WidgetRef ref,
    NoteEntity note,
  ) async {
    final result = note.isPinned
        ? await ref.read(notesProvider.notifier).unpinNote(note.id)
        : await ref.read(notesProvider.notifier).pinNote(note.id);
    if (!context.mounted) return;
    result.fold(
      (f) => InkSnackBar.showError(context, f),
      (_) => InkSnackBar.showSuccess(
        context,
        note.isPinned ? 'Note unpinned.' : 'Note pinned.',
      ),
    );
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    NoteEntity note,
  ) async {
    final result =
        await ref.read(notesProvider.notifier).archiveNote(note.id);
    if (!context.mounted) return;
    result.fold(
      (f) => InkSnackBar.showError(context, f),
      (_) => InkSnackBar.showSuccess(
        context,
        'Note archived.',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              ref.read(notesProvider.notifier).unarchiveNote(note.id),
        ),
      ),
    );
  }

  Future<void> _delete(
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

// ─────────────────────────────────────────────────────────────────────────────
// _SearchResultsList
// ─────────────────────────────────────────────────────────────────────────────

/// Shows search results from [searchResultsProvider].
///
/// Displayed in place of [_NoteList] when [_isSearching] is true.
/// Auto-disposed when the search bar closes — query and results reset to [].
class _SearchResultsList extends ConsumerWidget {
  const _SearchResultsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    // Empty query → prompt the user to type something.
    if (query.trim().isEmpty) {
      return const SliverToBoxAdapter(
        child: InkEmptyState(
          icon: Icons.search_rounded,
          title: 'Search your notes',
          subtitle: 'Type to find notes by title or content.',
        ),
      );
    }

    return resultsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(height: 200, child: InkLoading()),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: InkErrorView(
          failure: e as Failure,
          onRetry: () => ref.invalidate(searchResultsProvider),
        ),
      ),
      data: (notes) {
        if (notes.isEmpty) {
          return const SliverToBoxAdapter(
            child: InkEmptyState(
              icon: Icons.search_off_rounded,
              title: AppStrings.emptySearchTitle,
              subtitle: AppStrings.emptySearchSubtitle,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: NoteCard(
                key: ValueKey(notes[index].id),
                note: notes[index],
                animationDelay: Duration(milliseconds: index * 30),
                onTap: () {},
                onToggleFavorite: null,
                onTogglePin: null,
                onArchive: null,
                onDelete: null,
              ),
            ),
            childCount: notes.length,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HomeFab
// ─────────────────────────────────────────────────────────────────────────────

/// The Extended FAB for creating a new note.
///
/// Navigation to the editor screen will be wired in Step 9.
/// The FAB is hidden when the search bar is open to avoid visual clutter.
class _HomeFab extends StatelessWidget {
  const _HomeFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'home_fab',
      onPressed: () => context.pushNamed(RouteNames.noteEditor),
      icon: const Icon(Icons.add_rounded),
      label: const Text('New Note'),
    ).animate().fadeIn(
          delay: const Duration(milliseconds: 300),
          duration: AppSizes.durationNormal,
        );
  }
}
