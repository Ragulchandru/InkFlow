// lib/shared/widgets/ink_text_field.dart
//
// InkTextField — InkFlow's branded text input component.
//
// Wraps Flutter's TextField so that:
//   1. Consistent styling (from AppTheme's inputDecorationTheme) is applied
//      automatically — no per-screen decoration boilerplate.
//   2. We can add app-wide behavior (e.g., haptic feedback, analytics)
//      in one place without touching every screen.
//   3. The API is simpler than raw TextField for our common use cases.
//
// Supports:
//   - Single-line and multi-line (set maxLines > 1)
//   - Prefix icon, suffix widget
//   - Hint text and floating label
//   - Validation
//   - Read-only mode

import 'package:flutter/material.dart';

/// InkFlow's branded text input field.
///
/// ```dart
/// InkTextField(
///   controller: _controller,
///   hint: 'Search notes...',
///   prefixIcon: Icons.search_outlined,
/// )
///
/// InkTextField(
///   controller: _bodyController,
///   hint: 'Write something...',
///   maxLines: null,  // expands infinitely
/// )
/// ```
class InkTextField extends StatelessWidget {
  const InkTextField({
    super.key,
    required this.controller,
    this.hint,
    this.label,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
  });

  // ─── Properties ───────────────────────────────────────────────────────────

  /// Manages the text content and cursor position.
  final TextEditingController controller;

  /// Placeholder text shown when the field is empty.
  final String? hint;

  /// Floating label above the field when focused or non-empty.
  final String? label;

  /// Icon displayed at the left edge of the field.
  final IconData? prefixIcon;

  /// Widget displayed at the right edge (e.g., a clear button).
  final Widget? suffix;

  /// Maximum number of lines.
  /// - `1` (default): single-line input.
  /// - `null`: unlimited lines (expands vertically).
  /// - `> 1`: fixed multi-line height.
  final int? maxLines;

  /// The keyboard type to display (e.g., text, email, number).
  final TextInputType? keyboardType;

  /// Action button on the keyboard (e.g., done, next, search).
  final TextInputAction? textInputAction;

  /// Called every time the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits (presses the action key).
  final ValueChanged<String>? onSubmitted;

  /// Validation function. Return an error string or null.
  final FormFieldValidator<String>? validator;

  /// Whether the field accepts input. Defaults to true.
  final bool enabled;

  /// When true, the field displays text but does not accept input.
  final bool readOnly;

  /// Whether the field should request focus when first built.
  final bool autofocus;

  /// Optional external FocusNode for programmatic focus control.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    // The visual decoration is inherited from AppTheme.inputDecorationTheme.
    // We only need to customize per-instance properties here.
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      maxLines: maxLines,
      keyboardType: keyboardType ??
          (maxLines == null || maxLines! > 1
              ? TextInputType.multiline
              : TextInputType.text),
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffix: suffix,
      ),
    );
  }
}
