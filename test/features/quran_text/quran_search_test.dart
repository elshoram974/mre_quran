import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_source.dart';
import 'package:mre_quran/features/quran_index/domain/index_search.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/data/quran_text_parser.dart';
import 'package:mre_quran/features/quran_text/data/quran_text_source.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_search.dart';
import 'package:mre_quran/features/quran_text/domain/basmala_split.dart';
import 'package:mre_quran/features/quran_text/domain/quran_search.dart';
import 'package:mre_quran/features/quran_text/domain/quran_text.dart';

void main() {
  late QuranSearch search;
  late QuranMetadata metadata;

  setUpAll(() {
    metadata = QuranMetadataParser.parse(
      File(QuranMetadataSource.assetPath).readAsStringSync(),
    );
    final counts = [for (final s in metadata.surahs) s.ayahCount];
    final split = splitBasmala(
      surahAyahCounts: counts,
      uthmani: QuranTextParser.parse(
        File(QuranTextSource.uthmaniAsset).readAsStringSync(),
        counts,
      ),
      clean: QuranTextParser.parse(
        File(QuranTextSource.cleanAsset).readAsStringSync(),
        counts,
      ),
    );
    final text = QuranText(
      metadata: metadata,
      uthmani: split.uthmani,
      clean: split.clean,
      basmala: split.basmala,
      prefixed: split.prefixed,
    );
    search = QuranSearch(
      surahs: IndexSearcher(metadata),
      ayahs: AyahSearchIndex(
        text: text,
        keys: AyahSearchIndex.buildKeys(split.clean),
        uthmaniKeys: AyahSearchIndex.buildKeys(split.uthmani),
      ),
    );
  });

  void expectDirect(String query, AyahRef ref, int page) {
    final outcome = search.outcome(query);
    expect(outcome.direct?.ref, ref, reason: query);
    expect(outcome.direct?.page, page, reason: query);
    expect(outcome.text.total, 0, reason: '$query is a reference, not text');
  }

  group('references', () {
    test('surah:ayah in Latin and Arabic-Indic digits', () {
      expectDirect('2:255', const AyahRef(2, 255), 42);
      expectDirect('٢:٢٥٥', const AyahRef(2, 255), 42);
      expectDirect('2 255', const AyahRef(2, 255), 42);
      expectDirect(' 2 : 255 ', const AyahRef(2, 255), 42);
    });

    test('surah name and ayah number', () {
      expectDirect('البقرة 255', const AyahRef(2, 255), 42);
      expectDirect('البقره 255', const AyahRef(2, 255), 42);
      expectDirect('بقرة 255', const AyahRef(2, 255), 42);
      expectDirect('سورة البقرة آية 255', const AyahRef(2, 255), 42);
      expectDirect('البقرة:255', const AyahRef(2, 255), 42);
      expectDirect('baqara 255', const AyahRef(2, 255), 42);
      expectDirect('Al-Baqara 255', const AyahRef(2, 255), 42);
    });

    test('names with a space and with hamza forms', () {
      expect(search.outcome('آل عمران 5').direct?.ref, const AyahRef(3, 5));
      expect(search.outcome('ال عمران 5').direct?.ref, const AyahRef(3, 5));
    });

    test('a bare surah number or name finds the surah', () {
      final byNumber = search.outcome('36');
      expect(byNumber.surahs.single.number, 36);
      expect(byNumber.text.total, 0);
      expect(search.outcome('الكهف').surahs.map((s) => s.number), contains(18));
      expect(search.outcome('سورة الكهف').surahs.first.number, 18);
    });

    test('an ayah that does not exist is not guessed', () {
      expect(search.outcome('2:300').isEmpty, isTrue);
      expect(search.outcome('2:300').isEmpty, isTrue);
      final tooHigh = search.outcome('البقرة 999');
      expect(tooHigh.direct, isNull);
      expect(tooHigh.surahs.single.number, 2);
    });

    test('first and last ayahs of the Quran', () {
      expectDirect('1:1', const AyahRef(1, 1), 1);
      expectDirect('114:6', const AyahRef(114, 6), 604);
    });
  });

  group('pages, juz, and hizb', () {
    PageHit only(String query) {
      final outcome = search.outcome(query);
      expect(outcome.pages, hasLength(1), reason: query);
      expect(outcome.direct, isNull, reason: query);
      return outcome.pages.single;
    }

    test('page by number with a word before or after', () {
      for (final query in [
        'صفحة 42',
        'صفحه ٤٢',
        'ص 42',
        'page 42',
        '42 صفحة',
      ]) {
        final hit = only(query);
        expect(hit.kind, PageHitKind.page, reason: query);
        expect(hit.page, 42, reason: query);
      }
    });

    test('juz by number opens its first page', () {
      final hit = only('جزء 3');
      expect(hit.kind, PageHitKind.juz);
      expect(hit.number, 3);
      expect(hit.page, metadata.juzs[2].startPage);
      expect(only('الجزء ٣٠').page, metadata.juzs[29].startPage);
      expect(only('juz 1').page, 1);
    });

    test('hizb by number opens the page its first quarter starts on', () {
      final hit = only('حزب 5');
      expect(hit.kind, PageHitKind.hizb);
      final start = metadata.rubStarts[16];
      expect(hit.page, metadata.pageOf(start.surah, start.ayah));
      expect(only('الحزب 60').number, 60);
    });

    test('out-of-range numbers are not guessed', () {
      expect(search.outcome('صفحة 605').pages, isEmpty);
      expect(search.outcome('جزء 31').pages, isEmpty);
      expect(search.outcome('حزب 61').pages, isEmpty);
      expect(search.outcome('صفحة 0').pages, isEmpty);
    });

    test('a bare number is both a surah and a page', () {
      final outcome = search.outcome('36');
      expect(outcome.surahs.single.number, 36);
      expect(outcome.pages.single.page, 36);
    });

    test('a bare number above 114 is only a page', () {
      final outcome = search.outcome('300');
      expect(outcome.surahs, isEmpty);
      expect(outcome.pages.single.page, 300);
      expect(search.outcome('604').pages.single.page, 604);
      expect(search.outcome('605').isEmpty, isTrue);
    });
  });

  group('text', () {
    test('words without tashkeel find their ayah', () {
      final outcome = search.outcome('الحمد لله رب العالمين');
      expect(outcome.direct, isNull);
      expect(outcome.text.matches.first.ref, const AyahRef(1, 2));
    });

    test('a word that is also a surah name gives both groups', () {
      final outcome = search.outcome('الكهف');
      expect(outcome.surahs.first.number, 18);
      expect(outcome.text.total, greaterThan(0));
    });

    test('the word "سورة" on its own is searched as text', () {
      final outcome = search.outcome('سورة');
      expect(outcome.text.total, greaterThan(0));
      expect(
        outcome.text.matches.map((m) => m.ref),
        contains(const AyahRef(2, 23)),
      );
      expect(search.outcome('سور').text.total, greaterThan(0));
    });

    test('empty and junk queries return nothing', () {
      expect(search.outcome('').isEmpty, isTrue);
      expect(search.outcome('   ').isEmpty, isTrue);
      expect(search.outcome('zzzzzz').isEmpty, isTrue);
    });
  });

  group('resolveSurah', () {
    final index = IndexSearcher(
      QuranMetadataParser.parse(
        File(QuranMetadataSource.assetPath).readAsStringSync(),
      ),
    );

    test('exact names resolve, with or without "ال"', () {
      expect(index.resolveSurah('البقرة')?.number, 2);
      expect(index.resolveSurah('بقرة')?.number, 2);
      expect(index.resolveSurah('الفاتحة')?.number, 1);
    });

    test('an unknown or ambiguous name does not resolve', () {
      expect(index.resolveSurah('xyz'), isNull);
      expect(index.resolveSurah(''), isNull);
    });
  });
}
