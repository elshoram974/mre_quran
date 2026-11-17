import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/domain/mushaf_edition.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_source.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/data/riwaya_text_parser.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_texts.dart';

void main() {
  final metadata = QuranMetadataParser.parse(
    File(QuranMetadataSource.assetPath).readAsStringSync(),
  );
  final withText = [
    for (final edition in MushafEditions.all)
      if (edition.text != null) edition,
  ];

  test('every reading but Hafs carries its own text and font', () {
    expect(withText, hasLength(MushafEditions.all.length - 1));
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final edition in withText) {
      expect(pubspec, contains('family: ${edition.text!.fontFamily}'));
    }
  });

  for (final edition in withText) {
    group(edition.id, () {
      final info = edition.text!;
      final bytes = File(info.asset).readAsBytesSync();
      final ayahs = RiwayaTextParser.parse(utf8.decode(bytes));
      final texts = RiwayaAyahTexts(
        metadata: metadata,
        ayahs: ayahs,
        fontFamily: info.fontFamily,
        unmatchedSurahs: info.unmatchedSurahs,
      );

      test('matches its recorded SHA-256', () {
        expect(sha256.convert(bytes).toString(), info.sha256);
      });

      test('holds every ayah of its pages, each on the page its polygons '
          'put it', () {
        // The page of each ayah, from the edition's polygon files, is
        // checked by tool/build_riwaya_text.py's companion check in
        // docs/QURAN_SOURCES.md, section 15. Here: a sane shape.
        expect(texts.ayahCount(1), 7);
        expect(texts.ayahCount(114), 6);
        expect(texts.pageOf(const AyahRef(1, 1)), 1);
        expect(texts.pageOf(const AyahRef(114, 1)), 604);
        for (final ayah in ayahs.values) {
          expect(ayah.text, isNotEmpty);
          expect(ayah.mark, matches(RegExp(r'^[٠-٩]+$')));
          expect(ayah.page, inInclusiveRange(1, 604));
        }
      });

      test('gives no text for a surah its pages count differently', () {
        for (final surah in info.unmatchedSurahs) {
          expect(texts.has(AyahRef(surah, 1)), isFalse);
        }
        expect(texts.has(const AyahRef(2, 1)), isTrue);
        expect(texts.has(const AyahRef(115, 1)), isFalse);
      });
    });
  }

  test('a broken line is refused', () {
    expect(() => RiwayaTextParser.parse('1|1|1|text'), throwsFormatException);
    expect(() => RiwayaTextParser.parse('x|1|1|t|١'), throwsFormatException);
    expect(() => RiwayaTextParser.parse(''), throwsFormatException);
  });
}
