import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_source.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';

void main() {
  final file = File(QuranMetadataSource.assetPath);
  late QuranMetadata metadata;

  setUpAll(() {
    metadata = QuranMetadataParser.parse(file.readAsStringSync());
  });

  test('bundled file matches the recorded SHA-256', () {
    expect(
      sha256.convert(file.readAsBytesSync()).toString(),
      QuranMetadataSource.sha256Hex,
    );
  });

  test('has the structure of the Madinah Mushaf', () {
    expect(metadata.surahs, hasLength(114));
    expect(metadata.juzs, hasLength(30));
    expect(metadata.pageCount, 604);
    expect(metadata.surahs.fold<int>(0, (sum, s) => sum + s.ayahCount), 6236);
  });

  test('surahs and juz start on ordered pages', () {
    final surahPages = metadata.surahs.map((s) => s.startPage).toList();
    final juzPages = metadata.juzs.map((j) => j.startPage).toList();
    expect(surahPages, orderedEquals([...surahPages]..sort()));
    expect(juzPages, orderedEquals([...juzPages]..sort()));
    expect(surahPages.first, 1);
    expect(juzPages.first, 1);
    expect(surahPages.last, 604);
  });

  test('known landmarks', () {
    expect(metadata.surah(1).arabicName, 'الفاتحة');
    expect(metadata.surah(2).startPage, 2);
    expect(metadata.pageOf(2, 255), 42, reason: 'Ayat al-Kursi is on page 42');
    expect(metadata.surah(9).revelation, Revelation.medinan);
    expect(metadata.juzs[2].startPage, 42);
  });

  test('has 240 quarters, 60 hizb, starting at the first ayah', () {
    expect(metadata.rubStarts, hasLength(240));
    expect(metadata.rubStarts.first, const AyahRef(1, 1));
    expect(metadata.rubStartingAt(const AyahRef(1, 1)), 1);
    expect(metadata.rubStartingAt(const AyahRef(2, 26)), 2);
    expect(metadata.rubStartingAt(const AyahRef(2, 27)), isNull);
    expect(metadata.hizbOf(const AyahRef(1, 7)), 1);
    expect(metadata.hizbOf(const AyahRef(114, 6)), 60);
    expect(metadata.rubOf(const AyahRef(114, 6)), 240);
    // Every juz starts a new hizb, two hizb per juz.
    for (final juz in metadata.juzs) {
      final start = AyahRef(juz.surah, juz.ayah);
      expect(
        metadata.rubStartingAt(start),
        isNotNull,
        reason: 'juz ${juz.number} should start on a quarter',
      );
      expect(metadata.hizbOf(start), (juz.number - 1) * 2 + 1);
    }
  });

  test('pageOf agrees with a linear scan for every ayah', () {
    for (final surah in metadata.surahs) {
      for (var ayah = 1; ayah <= surah.ayahCount; ayah++) {
        var expected = 1;
        for (var i = 0; i < metadata.pageStarts.length; i++) {
          final start = metadata.pageStarts[i];
          final atOrBefore =
              start.surah < surah.number ||
              (start.surah == surah.number && start.ayah <= ayah);
          if (!atOrBefore) break;
          expected = i + 1;
        }
        expect(metadata.pageOf(surah.number, ayah), expected);
      }
    }
  });

  test('rejects a file with the wrong structure', () {
    expect(
      () => QuranMetadataParser.parse('<quran><suras/></quran>'),
      throwsA(isA<QuranMetadataFormatException>()),
    );
    expect(
      () => QuranMetadataParser.parse('not xml'),
      throwsA(isA<QuranMetadataFormatException>()),
    );
  });
}
