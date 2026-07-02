// lib/features/notes/presentation/screens/note_editor_screen.dart
//
// NoteEditorScreen — Premium note editor for Orynta.
//
// Design inspiration: Apple Notes · Craft · Notion · Material You
//
// ─────────────────────────────────────────────────────────────────────────────
// DESIGN PHILOSOPHY
// ─────────────────────────────────────────────────────────────────────────────
//
//   The editor is a blank canvas. Every pixel that doesn't carry meaning
//   is removed. The user's words are the only thing that matters.
//
//   Decisions made for premium feel:
//     1. CustomScrollView + SliverAppBar (pinned, transparent backdrop).
//        The title and save action stay visible while the user scrolls.
//        The app bar gains a subtle shadow only after scrolling begins.
//
//     2. Completely borderless TextField for title and body.
//        No outlined, filled, or underlined decoration — pure canvas.
//
//     3. Title uses headlineMedium (~28sp). Noticeably larger than the body.
//        This creates a clear hierarchy (title feels like a heading, not a form).
//
//     4. Body uses bodyLarge (16sp) with line height 1.7 — comfortable for
//        sustained reading and writing (matches Apple Notes body text feel).
//
//     5. Note color tints the entire scaffold background (not just the card).
//        When editing a colored note, the entire screen takes that hue —
//        immersive, like a physical colored paper.
//
//     6. Bottom metadata bar:
//        "Last modified · N words · N chars" — subtle, single line.
//        Updates reactively as the user types.
//
//     7. Staggered fade animation on editor content appearance.
//
// ─────────────────────────────────────────────────────────────────────────────
// WIDGET TREE
// ─────────────────────────────────────────────────────────────────────────────
//
//   NoteEditorScreen (ConsumerStatefulWidget)
//     └── PopScope (unsaved changes guard)
//           └── Scaffold (backgroundColor = note tint)
//                 └── CustomScrollView
//                       ├── SliverAppBar (pinned, transparent→frosted on scroll)
//                       │     ├── Back icon
//                       │     ├── Save (✓) / CircularProgress
//                       │     └── [edit] Pin · Favorite · More (overflow)
//                       └── SliverFillRemaining
//                             ├── [loading] InkLoading
//                             ├── [error]   InkErrorView
//                             └── [data]    _EditorCanvas
//                                   ├── Title TextField (headlineMedium, 3 lines max)
//                                   ├── _MetaRow (timestamp + word/char count)
//                                   ├── Divider
//                                   └── Body TextField (bodyLarge, unbounded)
//
// ─────────────────────────────────────────────────────────────────────────────
// MODES
// ─────────────────────────────────────────────────────────────────────────────
//
//   Create mode (noteId == null):
//     Empty controllers. Auto-focuses title. Save → createNote().
//
//   Edit mode (noteId != null):
//     loadNote() called in initState. Controllers populated on AsyncData.
//     Save → updateNote().
//
// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER FLOW — same as original; see notes_notifier.dart for details.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/ink_confirm_dialog.dart';
import '../../../../shared/widgets/ink_error_view.dart';
import '../../../../shared/widgets/ink_loading.dart';
import '../../../../shared/widgets/ink_snack_bar.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/usecases/create_note_use_case.dart';
import '../providers/notes_notifier.dart';
import '../providers/selected_note_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NoteEditorScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Premium note creation and editing screen.
///
/// - [noteId] == `null` → **create mode**
/// - [noteId] != `null` → **edit mode**
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, this.noteId});

  /// The ID of the note to edit. `null` = create mode.
  final String? noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  // ── Controllers & Focus ───────────────────────────────────────────────────

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // ── State ─────────────────────────────────────────────────────────────────

  /// Snapshot of the note when the editor opened. Used for change detection.
  NoteEntity? _originalNote;

  /// Word count — recomputed on every keystroke.
  int _wordCount = 0;

  /// Whether a save operation is in flight.
  bool _isSaving = false;

  /// Tracks whether the AppBar should show frosted backdrop (after scroll).
  bool _isScrolled = false;

  bool get _isCreateMode => widget.noteId == null;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _bodyController.addListener(_onBodyChanged);
    _scrollController.addListener(_onScroll);

    if (!_isCreateMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedNoteProvider.notifier).loadNote(widget.noteId!);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _bodyController.removeListener(_onBodyChanged);
    _scrollController.removeListener(_onScroll);
    _titleController.dispose();
    _bodyController.dispose();
    _titleFocus.dispose();
    _scrollController.dispose();
    // Do NOT call ref.read() here — ref is invalid after disposal.
    // clear() is called on every successful exit path while still mounted.
    super.dispose();
  }

  void _onBodyChanged() {
    final text = _bodyController.text.trim();
    final count = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    if (count != _wordCount) setState(() => _wordCount = count);
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 4;
    if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
  }

  // ── Change Detection ───────────────────────────────────────────────────────

  bool get _hasUnsavedChanges {
    if (_isCreateMode) {
      return _titleController.text.trim().isNotEmpty ||
          _bodyController.text.trim().isNotEmpty;
    }
    if (_originalNote == null) return false;
    return _titleController.text.trim() != _originalNote!.title.trim() ||
        _bodyController.text.trim() != _originalNote!.body.trim();
  }

  // ── Populate ───────────────────────────────────────────────────────────────

  void _populateFromNote(NoteEntity note) {
    if (_originalNote != null) return; // only once
    _originalNote = note;
    _titleController.text = note.title;
    _bodyController.text = note.body;
    // Seed word count.
    final text = note.body.trim();
    _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
  }

  // ── Background color ───────────────────────────────────────────────────────

  /// Returns the scaffold background tint — the entire screen adopts the
  /// note's color for an immersive editing experience.
  Color _scaffoldBackground(BuildContext context) {
    final theme = Theme.of(context);
    final raw = _originalNote?.color;
    if (raw == null || raw == AppColors.noteColorDefault) {
      return theme.colorScheme.surface;
    }
    final isDark = theme.brightness == Brightness.dark;
    final base = Color(raw);
    return isDark
        ? Color.alphaBlend(Colors.black.withValues(alpha: 0.55), base)
        : Color.alphaBlend(Colors.white.withValues(alpha: 0.35), base);
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_isSaving) return;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty && body.isEmpty) {
      if (!mounted) return;
      InkSnackBar.showError(
        context,
        const NoteValidationFailure('A note must have a title or body.'),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_isCreateMode) {
        await _saveCreate(title, body);
      } else {
        await _saveUpdate(title, body);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveCreate(String title, String body) async {
    final result = await ref
        .read(notesProvider.notifier)
        .createNote(CreateNoteParams(title: title, body: body));
    if (!mounted) return;
    result.fold(
      (f) => InkSnackBar.showError(context, f),
      (_) {
        // Clear provider state while ref is still valid (widget is mounted).
        ref.read(selectedNoteProvider.notifier).clear();
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _saveUpdate(String title, String body) async {
    final current = _originalNote;
    if (current == null) return;
    final updated = current.copyWith(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
    );
    final result =
        await ref.read(notesProvider.notifier).updateNote(updated);
    if (!mounted) return;
    result.fold(
      (f) => InkSnackBar.showError(context, f),
      (saved) => setState(() => _originalNote = saved),
    );
  }

  // ── Back ──────────────────────────────────────────────────────────────────

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) return;
    if (!_hasUnsavedChanges) {
      if (mounted) {
        ref.read(selectedNoteProvider.notifier).clear();
        Navigator.of(context).pop();
      }
      return;
    }
    if (!mounted) return;
    final discard = await InkConfirmDialog.show(
      context,
      title: 'Discard changes?',
      message: 'Your unsaved changes will be lost.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      isDestructive: true,
    );
    if (discard && mounted) {
      ref.read(selectedNoteProvider.notifier).clear();
      Navigator.of(context).pop();
    }
  }

  // ── AppBar Actions ─────────────────────────────────────────────────────────

  Future<void> _togglePin() async {
    final note = _originalNote;
    if (note == null) return;
    final result = note.isPinned
        ? await ref.read(notesProvider.notifier).unpinNote(note.id)
        : await ref.read(notesProvider.notifier).pinNote(note.id);
    if (!mounted) return;
    result.fold(
      (f) => InkSnackBar.showError(context, f),
      (saved) => setState(() => _originalNote = saved),
    );
  }

  Future<void> _toggleFavorite() async {
    final note = _originalNote;
    if (note == null) return;
    final result =
        await ref.read(notesProvider.notifier).toggleFavorite(note.id);
    if (!mounted) return;
    result.fold(
      (f) => InkSnackBar.showError(context, f),
      (saved) {
        setState(() => _originalNote = saved);
        InkSnackBar.showSuccess(
          context,
          saved.isFavorite ? 'Added to favorites.' : 'Removed from favorites.',
        );
      },
    );
  }

  Future<void> _archive() async {
    final note = _originalNote;
    if (note == null) return;
    final confirmed = await InkConfirmDialog.show(
      context,
      title: 'Archive note?',
      message: 'This note will be moved to your archive.',
      confirmLabel: 'Archive',
    );
    if (!confirmed || !mounted) return;
    final result =
        await ref.read(notesProvider.notifier).archiveNote(note.id);
    if (!mounted) return;
    result.fold(
      (f) => InkSnackBar.showError(context, f),
      (_) {
        // Clear provider state while ref is still valid (widget is mounted).
        ref.read(selectedNoteProvider.notifier).clear();
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _delete() async {
    final note = _originalNote;
    if (note == null) return;
    final confirmed = await InkConfirmDialog.show(
      context,
      title: 'Move to trash?',
      message: 'This note will be moved to the trash.',
      confirmLabel: 'Move to trash',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final result =
        await ref.read(notesProvider.notifier).deleteNote(note.id);
    if (!mounted) return;
    result.fold(
      (f) => InkSnackBar.showError(context, f),
      (_) {
        // Clear provider state while ref is still valid (widget is mounted).
        ref.read(selectedNoteProvider.notifier).clear();
        Navigator.of(context).pop();
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(selectedNoteProvider);
    if (!_isCreateMode) {
      noteAsync.whenData((note) {
        if (note != null) _populateFromNote(note);
      });
    }

    final theme = Theme.of(context);
    final bgColor = _scaffoldBackground(context);
    final isPinned = _originalNote?.isPinned ?? false;
    final isFavorite = _originalNote?.isFavorite ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        backgroundColor: bgColor,
        body: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Frosted SliverAppBar ───────────────────────────────────────
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              flexibleSpace: AnimatedContainer(
                duration: AppSizes.durationFast,
                decoration: BoxDecoration(
                  // Frosted glass effect once the user scrolls past the title.
                  color: _isScrolled
                      ? bgColor.withValues(alpha: 0.85)
                      : Colors.transparent,
                  border: _isScrolled
                      ? Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                          ),
                        )
                      : null,
                ),
                child: _isScrolled
                    ? BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: const SizedBox.expand(),
                      )
                    : const SizedBox.expand(),
              ),
              title: _isScrolled
                  ? Text(
                      _titleController.text.isEmpty
                          ? (_isCreateMode ? 'New Note' : 'Edit Note')
                          : _titleController.text,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                tooltip: 'Back',
                onPressed: () => _handlePop(false, null),
              ),
              actions: _buildActions(
                isPinned: isPinned,
                isFavorite: isFavorite,
                theme: theme,
              ),
            ),

            // ── Editor canvas ──────────────────────────────────────────────
            SliverFillRemaining(
              hasScrollBody: false,
              child: _isCreateMode
                  ? _EditorCanvas(
                      titleController: _titleController,
                      bodyController: _bodyController,
                      titleFocus: _titleFocus,
                      wordCount: _wordCount,
                      note: _originalNote,
                      onTitleChanged: () => setState(() {}),
                    ).animate().fadeIn(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      )
                  : _buildEditModeBody(noteAsync),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions({
    required bool isPinned,
    required bool isFavorite,
    required ThemeData theme,
  }) {
    return [
      // Save button
      if (_isSaving)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      else
        IconButton(
          icon: const Icon(Icons.check_rounded),
          tooltip: 'Save',
          onPressed: _save,
        ),

      // Edit-mode actions
      if (!_isCreateMode && _originalNote != null) ...[
        IconButton(
          icon: Icon(
            isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            size: 20,
          ),
          tooltip: isPinned ? 'Unpin' : 'Pin',
          onPressed: _isSaving ? null : _togglePin,
        ),
        IconButton(
          icon: Icon(
            isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: 20,
            color: isFavorite ? theme.colorScheme.error : null,
          ),
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          onPressed: _isSaving ? null : _toggleFavorite,
        ),
        PopupMenuButton<_EditorOverflow>(
          icon: const Icon(Icons.more_horiz_rounded),
          tooltip: 'More',
          enabled: !_isSaving,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          onSelected: (a) => switch (a) {
            _EditorOverflow.archive => _archive(),
            _EditorOverflow.delete => _delete(),
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: _EditorOverflow.archive,
              child: _OverflowItem(
                icon: Icons.archive_outlined,
                label: 'Archive',
              ),
            ),
            PopupMenuItem(
              value: _EditorOverflow.delete,
              child: _OverflowItem(
                icon: Icons.delete_outline_rounded,
                label: 'Move to trash',
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ],

      const SizedBox(width: AppSizes.xs),
    ];
  }

  Widget _buildEditModeBody(AsyncValue<NoteEntity?> noteAsync) {
    return switch (noteAsync) {
      AsyncLoading() => const InkLoading(label: 'Loading note...'),
      AsyncError(:final error) => InkErrorView(
          failure: error is Failure
              ? error
              : UnexpectedFailure(error.toString()),
          onRetry: () => ref
              .read(selectedNoteProvider.notifier)
              .loadNote(widget.noteId!),
        ),
      AsyncData() => _EditorCanvas(
          titleController: _titleController,
          bodyController: _bodyController,
          titleFocus: _titleFocus,
          wordCount: _wordCount,
          note: _originalNote,
          onTitleChanged: () => setState(() {}),
        )
            .animate()
            .fadeIn(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            )
            .slideY(
              begin: 0.04,
              end: 0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            ),
      _ => const InkLoading(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditorCanvas
// ─────────────────────────────────────────────────────────────────────────────

/// The full-screen writing canvas.
///
/// Deliberately borderless — the background is the affordance.
/// Title is large (headlineMedium) and body is comfortable (bodyLarge, 1.7 lh).
/// A subtle metadata row between them shows word count and last-modified time.
class _EditorCanvas extends StatelessWidget {
  const _EditorCanvas({
    required this.titleController,
    required this.bodyController,
    required this.titleFocus,
    required this.wordCount,
    required this.onTitleChanged,
    this.note,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final FocusNode titleFocus;
  final int wordCount;
  final VoidCallback onTitleChanged;
  final NoteEntity? note;

  String _modifiedLabel() {
    if (note == null) return 'Not yet saved';
    final diff = DateTime.now().difference(note!.updatedAt);
    if (diff.inMinutes < 1) return 'Saved just now';
    if (diff.inMinutes < 60) return 'Saved ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Saved ${diff.inHours}h ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = months[note!.updatedAt.month - 1];
    final d = note!.updatedAt.day;
    return 'Saved $m $d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // If the note has a custom color, derive text colors for contrast.
    final hasColor = note?.color != null &&
        note!.color != AppColors.noteColorDefault;
    final primaryText = hasColor
        ? (isDark
            ? Colors.white.withValues(alpha: 0.92)
            : Colors.black.withValues(alpha: 0.85))
        : theme.colorScheme.onSurface;
    final secondaryText = hasColor
        ? (isDark
            ? Colors.white.withValues(alpha: 0.55)
            : Colors.black.withValues(alpha: 0.50))
        : theme.colorScheme.onSurfaceVariant;

    // SliverFillRemaining(hasScrollBody: false) gives this widget a finite
    // height equal to the remaining viewport. The Column uses that bounded
    // height; the body TextField is wrapped in Expanded so it fills whatever
    // vertical space is left after the title, metadata row, and divider.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.sm,
        AppSizes.lg,
        MediaQuery.paddingOf(context).bottom + AppSizes.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──────────────────────────────────────────────────────
          TextField(
            controller: titleController,
            focusNode: titleFocus,
            onChanged: (_) => onTitleChanged(),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: primaryText,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.5,
            ),
            decoration: InputDecoration(
              hintText: 'Title',
              hintStyle: theme.textTheme.headlineMedium?.copyWith(
                color: secondaryText.withValues(alpha: 0.45),
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              fillColor: Colors.transparent,
              filled: true,
            ),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
          ),

          const SizedBox(height: AppSizes.sm),

          // ── Metadata row ───────────────────────────────────────────────
          Row(
            children: [
              Text(
                _modifiedLabel(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: secondaryText.withValues(alpha: 0.65),
                  letterSpacing: 0.2,
                ),
              ),
              if (wordCount > 0) ...[
                Text(
                  '  ·  ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: secondaryText.withValues(alpha: 0.4),
                  ),
                ),
                Text(
                  '$wordCount ${wordCount == 1 ? 'word' : 'words'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: secondaryText.withValues(alpha: 0.65),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppSizes.sm),

          // ── Divider ────────────────────────────────────────────────────
          Container(
            height: 1,
            color: secondaryText.withValues(alpha: 0.12),
          ),

          const SizedBox(height: AppSizes.md),

          // ── Body ───────────────────────────────────────────────────────
          // Expanded gives the TextField a finite height (the leftover space
          // inside the bounded Column) so Flutter never sees infinite height.
          Expanded(
            child: TextField(
              controller: bodyController,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: primaryText.withValues(alpha: 0.88),
                height: 1.7,
                letterSpacing: 0.1,
              ),
              decoration: InputDecoration(
                hintText: 'Start writing…',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: secondaryText.withValues(alpha: 0.45),
                  height: 1.7,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                fillColor: Colors.transparent,
                filled: true,
              ),
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting types
// ─────────────────────────────────────────────────────────────────────────────

enum _EditorOverflow { archive, delete }

/// A single row in the popup overflow menu.
class _OverflowItem extends StatelessWidget {
  const _OverflowItem({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconMd, color: resolved),
        const SizedBox(width: AppSizes.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: resolved,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
