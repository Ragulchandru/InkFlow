// lib/features/notes/data/models/note_type_adapter.dart

import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/hive_type_ids.dart';
import 'note_model.dart';

/// Hive [TypeAdapter] for [NoteModel].
///
/// Serializes and deserializes [NoteModel] to and from Hive's binary format.
/// Must be registered in [main] before any Hive box is opened.
///
/// ─── Why manual instead of generated (hive_generator)? ────────────────────
///
/// hive_generator 2.0.1 pins analyzer >=4.6.0 <7.0.0, conflicting with
/// freezed and riverpod_generator on Dart 3.12. Removing it unblocks the
/// entire version graph. With only a handful of models in Orynta, a
/// manual adapter is a clean, permanent trade-off. It also makes the
/// binary layout explicit and self-documenting.
///
/// ─── Binary field layout ──────────────────────────────────────────────────
///
/// ⚠️  This order is PERMANENT. Hive stores no field-name metadata — only
///     byte position. read() MUST mirror write() exactly. Reordering fields
///     after shipping corrupts all existing stored data.
///
/// Slot | Field           | Storage type
/// -----|-----------------|------------------------------------------------------
///   0  | id              | writeString
///   1  | title           | writeString
///   2  | body            | writeString
///   3  | hasColor        | writeBool  (null sentinel)
///   4  | color           | writeInt   (only when slot 3 = true)
///   5  | isPinned        | writeBool
///   6  | statusIndex     | writeInt
///   7  | createdAtMs     | writeInt
///   8  | updatedAtMs     | writeInt
///   9  | hasTrashedAt    | writeBool  (null sentinel)
///  10  | trashedAtMs     | writeInt   (only when slot 9 = true)
///  11  | hasCategoryId   | writeBool  (null sentinel)
///  12  | categoryId      | writeString (only when slot 11 = true)
///  13  | tagIdsCount     | writeInt   (list length)
///  14+ | tagIds[i]       | writeString (repeated tagIdsCount times)
///   *  | isFavorite      | writeBool  (immediately after last tagId)
///
/// ─── Nullable encoding ────────────────────────────────────────────────────
///
/// Hive has no native nullable primitive support. Nullable fields use a
/// boolean presence sentinel written immediately before the value:
///   write: writeBool(value != null); if (value != null) write(value);
///   read:  final has = readBool(); final value = has ? read() : null;
///
/// ─── List<String> encoding ────────────────────────────────────────────────
///
/// Lists are length-prefixed: writeInt(length) then writeString per element.
/// read() mirrors this with readInt() then readString() in a loop.
class NoteTypeAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = HiveTypeIds.note;

  // ─── Deserialize (Disk → NoteModel) ────────────────────────────────────

  @override
  NoteModel read(BinaryReader reader) {
    // Read in the EXACT same order as write() below.

    final id = reader.readString();                              // slot 0
    final title = reader.readString();                          // slot 1
    final body = reader.readString();                           // slot 2

    final hasColor = reader.readBool();                         // slot 3
    final color = hasColor ? reader.readInt() : null;           // slot 4

    final isPinned = reader.readBool();                         // slot 5
    final statusIndex = reader.readInt();                       // slot 6
    final createdAtMs = reader.readInt();                       // slot 7
    final updatedAtMs = reader.readInt();                       // slot 8

    final hasTrashedAt = reader.readBool();                     // slot 9
    final trashedAtMs = hasTrashedAt ? reader.readInt() : null; // slot 10

    final hasCategoryId = reader.readBool();                    // slot 11
    final categoryId = hasCategoryId ? reader.readString() : null; // slot 12

    final tagIdsCount = reader.readInt();                       // slot 13
    final tagIds = List<String>.generate(                       // slot 14+
      tagIdsCount,
      (_) => reader.readString(),
    );

    final isFavorite = reader.readBool();                       // slot *

    return NoteModel(
      id: id,
      title: title,
      body: body,
      color: color,
      isPinned: isPinned,
      statusIndex: statusIndex,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
      trashedAtMs: trashedAtMs,
      categoryId: categoryId,
      tagIds: tagIds,
      isFavorite: isFavorite,
    );
  }

  // ─── Serialize (NoteModel → Disk) ────────────────────────────────────────

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer.writeString(obj.id);                                 // slot 0
    writer.writeString(obj.title);                             // slot 1
    writer.writeString(obj.body);                              // slot 2

    writer.writeBool(obj.color != null);                       // slot 3
    if (obj.color != null) writer.writeInt(obj.color!);        // slot 4

    writer.writeBool(obj.isPinned);                            // slot 5
    writer.writeInt(obj.statusIndex);                          // slot 6
    writer.writeInt(obj.createdAtMs);                          // slot 7
    writer.writeInt(obj.updatedAtMs);                          // slot 8

    writer.writeBool(obj.trashedAtMs != null);                 // slot 9
    if (obj.trashedAtMs != null) writer.writeInt(obj.trashedAtMs!); // slot 10

    writer.writeBool(obj.categoryId != null);                  // slot 11
    if (obj.categoryId != null) writer.writeString(obj.categoryId!); // slot 12

    writer.writeInt(obj.tagIds.length);                        // slot 13
    for (final tagId in obj.tagIds) {                          // slot 14+
      writer.writeString(tagId);
    }

    writer.writeBool(obj.isFavorite);                          // slot *
  }
}
