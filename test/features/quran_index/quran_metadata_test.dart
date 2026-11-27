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

  test('orders the surahs by revelation, each once', () {
    final orders = [for (final surah in metadata.surahs) surah.revelationOrder];
    expect(orders.toSet(), {for (var i = 1; i <= 114; i++) i});
    // Al-Alaq was revealed first, Al-Fatihah fifth, An-Nasr last.
    expect(metadata.surah(96).revelationOrder, 1);
    expect(metadata.surah(1).revelationOrder, 5);
    expect(metadata.surah(110).revelationOrder, 114);
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

  test('has 60 hizb, two to a juz, each beginning on a quarter', () {
    final hizbs = metadata.hizbs;
    expect(hizbs, hasLength(60));
    expect(
      [for (final hizb in hizbs) hizb.number],
      [for (var number = 1; number <= 60; number++) number],
    );
    expect(
      (hizbs.first.surah, hizbs.first.ayah, hizbs.first.startPage),
      (1, 1, 1),
    );
    // The second hizb begins at Al-Baqara 2:75.
    expect((hizbs[1].surah, hizbs[1].ayah), (2, 75));
    for (final hizb in hizbs) {
      final start = AyahRef(hizb.surah, hizb.ayah);
      expect(metadata.rubStartingAt(start), (hizb.number - 1) * 4 + 1);
      expect(metadata.hizbOf(start), hizb.number);
      expect(hizb.startPage, metadata.pageOf(hizb.surah, hizb.ayah));
    }
    // A juz is its two hizb: the first begins where the juz does.
    for (final juz in metadata.juzs) {
      final first = hizbs[(juz.number - 1) * 2];
      expect(
        (first.surah, first.ayah, first.startPage),
        (juz.surah, juz.ayah, juz.startPage),
      );
      expect(first.juz, juz.number);
      expect(hizbs[(juz.number - 1) * 2 + 1].juz, juz.number);
    }
    // Reading order: each begins on a later page than the one before, or the
    // same page.
    for (var i = 1; i < hizbs.length; i++) {
      expect(hizbs[i].startPage, greaterThanOrEqualTo(hizbs[i - 1].startPage));
    }
  });

  test('a quarter knows its hizb and how far into it it begins', () {
    expect((const HizbQuarter(1).hizb, const HizbQuarter(1).quarter), (1, 0));
    expect((const HizbQuarter(2).hizb, const HizbQuarter(2).quarter), (1, 1));
    expect((const HizbQuarter(3).hizb, const HizbQuarter(3).quarter), (1, 2));
    expect((const HizbQuarter(4).hizb, const HizbQuarter(4).quarter), (1, 3));
    expect((const HizbQuarter(5).hizb, const HizbQuarter(5).quarter), (2, 0));
    expect(
      (const HizbQuarter(240).hizb, const HizbQuarter(240).quarter),
      (60, 3),
    );
    expect(const HizbQuarter(7), const HizbQuarter(7));
    expect(const HizbQuarter(7), isNot(const HizbQuarter(8)));
  });

  test('a page belongs to the last quarter that begins on or before it', () {
    PageStart start(int page) => metadata.pageStarts[page - 1];
    // The first page opens the first hizb, and the last page is in the last
    // quarter of the last.
    expect(metadata.quarterOfPage(1), const HizbQuarter(1));
    expect(metadata.quarterOfPage(604), const HizbQuarter(240));
    expect(
      (metadata.quarterOfPage(604).hizb, metadata.quarterOfPage(604).quarter),
      (60, 3),
    );

    // The first quarter mark, 2:26, is part way down page 5, which begins
    // at 2:25: the pages before it are the hizb's start, page 5 its quarter.
    expect((start(5).surah, start(5).ayah), (2, 25));
    expect(metadata.rubStartingAt(const AyahRef(2, 26)), 2);
    expect(metadata.quarterOfPage(4), const HizbQuarter(1));
    expect(metadata.quarterOfPage(5), const HizbQuarter(2));

    // Hizb 2 begins at 2:75, part way down page 11, which begins at 2:70.
    // The page is named by the new hizb, as its margin marks it, though its
    // first ayah is still in the first.
    expect((start(11).surah, start(11).ayah), (2, 70));
    expect(metadata.hizbs[1].startPage, 11);
    expect(metadata.hizbOf(metadata.ayahsOnPage(11).first), 1);
    expect(metadata.quarterOfPage(10), const HizbQuarter(4));
    expect(metadata.quarterOfPage(11), const HizbQuarter(5));
    expect(
      (metadata.quarterOfPage(11).hizb, metadata.quarterOfPage(11).quarter),
      (2, 0),
    );

    // Half of hizb 2 begins at 2:106, the very top of page 17.
    expect((start(17).surah, start(17).ayah), (2, 106));
    expect(metadata.rubStartingAt(const AyahRef(2, 106)), 7);
    expect(metadata.quarterOfPage(16), const HizbQuarter(6));
    expect(metadata.quarterOfPage(17), const HizbQuarter(7));
    expect(
      (metadata.quarterOfPage(17).hizb, metadata.quarterOfPage(17).quarter),
      (2, 2),
    );

    // A hizb at the very top of a page: the third, with the second juz.
    expect((start(22).surah, start(22).ayah), (2, 142));
    expect(metadata.quarterOfPage(21), const HizbQuarter(8));
    expect(metadata.quarterOfPage(22), const HizbQuarter(9));
  });

  test('every page\'s quarter agrees with its ayahs, its juz and the hizb '
      'list', () {
    var before = 1;
    for (var page = 1; page <= metadata.pageCount; page++) {
      final quarter = metadata.quarterOfPage(page);
      // The last quarter begun by the end of the page is the one its last
      // ayah is in.
      expect(
        quarter.rub,
        metadata.rubOf(metadata.ayahsOnPage(page).last),
        reason: 'page $page',
      );
      expect(quarter.rub, greaterThanOrEqualTo(before), reason: 'page $page');
      before = quarter.rub;
      // Two hizb to a juz, and both are named by the same rule.
      expect(
        metadata.hizbs[quarter.hizb - 1].juz,
        metadata.juzOfPage(page).number,
        reason: 'page $page',
      );
      // The page's hizb is the last in the index that begins by this page.
      expect(
        quarter.hizb,
        metadata.hizbs.lastWhere((hizb) => hizb.startPage <= page).number,
        reason: 'page $page',
      );
    }
    // Every quarter names at least one page: none is skipped.
    expect({
      for (var page = 1; page <= metadata.pageCount; page++)
        metadata.quarterOfPage(page).rub,
    }, hasLength(240));
  });

  test('has the fifteen sajda ayahs of the Madinah Mushaf, in order', () {
    final sajdas = metadata.sajdas;
    expect(sajdas, hasLength(15));
    expect(
      [for (final sajda in sajdas) sajda.number],
      [for (var number = 1; number <= 15; number++) number],
    );
    expect((sajdas.first.surah, sajdas.first.ayah), (7, 206));
    expect((sajdas.last.surah, sajdas.last.ayah), (96, 19));
    // Al-Hajj has two.
    expect(
      [
        for (final s in sajdas)
          if (s.surah == 22) s.ayah,
      ],
      [18, 77],
    );
    for (var i = 0; i < sajdas.length; i++) {
      final sajda = sajdas[i];
      expect(
        sajda.ayah,
        inInclusiveRange(1, metadata.surah(sajda.surah).ayahCount),
      );
      expect(sajda.startPage, metadata.pageOf(sajda.surah, sajda.ayah));
      if (i > 0) {
        expect(
          AyahRef(
            sajda.surah,
            sajda.ayah,
          ).compareTo(AyahRef(sajdas[i - 1].surah, sajdas[i - 1].ayah)),
          greaterThan(0),
        );
      }
    }
  });

  test('juzOf finds the juz an ayah is in', () {
    expect(metadata.juzOf(const AyahRef(1, 1)), 1);
    expect(metadata.juzOf(const AyahRef(2, 141)), 1);
    expect(metadata.juzOf(const AyahRef(2, 142)), 2);
    expect(
      metadata.juzOf(const AyahRef(3, 1)),
      3,
      reason: 'juz 3 begins at 2:253',
    );
    expect(metadata.juzOf(const AyahRef(7, 206)), 9);
    expect(metadata.juzOf(const AyahRef(114, 6)), 30);
    for (final juz in metadata.juzs) {
      expect(metadata.juzOf(AyahRef(juz.surah, juz.ayah)), juz.number);
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
