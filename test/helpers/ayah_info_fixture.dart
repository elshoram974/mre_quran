import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Writes a database with the `glyphs` table of Quran.com's `ayahinfo`.
File writeAyahInfo(Directory dir, List<List<int>> rows) {
  final file = File('${dir.path}/ayahinfo.db');
  final db = sqlite3.open(file.path)
    ..execute(
      'CREATE TABLE glyphs(glyph_id int not null, page_number int not null, '
      'line_number int not null, sura_number int not null, '
      'ayah_number int not null, position int not null, min_x int not null, '
      'max_x int not null, min_y int not null, max_y int not null, '
      'primary key(glyph_id))',
    );
  final insert = db.prepare('INSERT INTO glyphs VALUES (?,?,?,?,?,?,?,?,?,?)');
  for (final (i, row) in rows.indexed) {
    insert.execute([i + 1, ...row]);
  }
  insert.close();
  db.close();
  return file;
}
