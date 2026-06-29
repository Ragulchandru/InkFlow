// lib/core/constants/hive_type_ids.dart
//
// Central registry for all Hive TypeAdapter type IDs.
//
// Why centralize type IDs?
//   Every Hive TypeAdapter requires a unique integer ID called typeId.
//   Hive uses this number to identify which adapter to use when reading
//   binary data from disk. If two adapters share the same typeId, Hive
//   will throw a runtime exception.
//
//   By listing all IDs here, we get:
//     1. Compile-time visibility of all reserved IDs.
//     2. A single place to check for conflicts before adding a new model.
//     3. Clear documentation of the ID-to-model mapping.
//
// ⚠️ CRITICAL RULE: Never change an existing ID after shipping.
//   Hive writes the typeId into stored binary data. Changing an ID
//   means Hive can no longer read previously stored objects — all
//   user data for that model would be lost permanently.
//
// ID allocation:
//   0–9   : Core / Notes feature
//   10–19 : Categories feature
//   20–29 : Tags feature
//   30–39 : Reminders feature
//   40–49 : Auth / Profile (Phase 6)

/// Unique TypeAdapter IDs for every Hive model in Orynta.
abstract final class HiveTypeIds {
  // ── Phase 1: Notes ────────────────────────────────────────────────────────
  /// TypeAdapter ID for [NoteModel].
  static const int note = 0;

  // ── Phase 2: Categories ───────────────────────────────────────────────────
  /// TypeAdapter ID for [CategoryModel]. (reserved — not yet implemented)
  static const int category = 10;

  // ── Phase 2: Tags ─────────────────────────────────────────────────────────
  /// TypeAdapter ID for [TagModel]. (reserved — not yet implemented)
  static const int tag = 20;

  // ── Phase 3: Reminders ────────────────────────────────────────────────────
  /// TypeAdapter ID for [ReminderModel]. (reserved — not yet implemented)
  static const int reminder = 30;
}
