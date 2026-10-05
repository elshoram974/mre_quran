import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../../quran_index/domain/quran_metadata.dart';
import '../domain/page_geometry.dart';

/// Reads glyph boxes from the Quran.com `ayahinfo` database.
class AyahInfoDatabase {
  /// Opens [file] read-only.
  AyahInfoDatabase.open(File file)
    : _db = sqlite3.open(file.path, mode: OpenMode.readOnly);

  final Database _db;

  /// Every glyph on [page], in database order.
  List<GlyphBox> page(int page) => [
    for (final row in _db.select(
      'SELECT sura_number, ayah_number, position, line_number, '
      'min_x, max_x, min_y, max_y FROM glyphs WHERE page_number = ?',
      [page],
    ))
      (
        ayah: AyahRef(row['sura_number'] as int, row['ayah_number'] as int),
        position: row['position'] as int,
        line: row['line_number'] as int,
        minX: row['min_x'] as int,
        maxX: row['max_x'] as int,
        minY: row['min_y'] as int,
        maxY: row['max_y'] as int,
      ),
  ];

  /// Closes the database.
  void close() => _db.close();
}
