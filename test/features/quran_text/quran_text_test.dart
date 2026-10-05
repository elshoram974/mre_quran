import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_source.dart';
import 'package:mre_quran/features/quran_index/domain/index_search.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/data/quran_text_parser.dart';
import 'package:mre_quran/features/quran_text/data/quran_text_source.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_search.dart';
import 'package:mre_quran/features/quran_text/domain/quran_text.dart';

void main() {
  final uthmaniFile = File(QuranTextSource.uthmaniAsset);
  final cleanFile = File(QuranTextSource.cleanAsset);
  late QuranMetadata metadata;
  late QuranText text;
  late AyahSearchIndex search;

  setUpAll(() {
    metadata = QuranMetadataParser.parse(
      File(QuranMetadataSource.assetPath).readAsStringSync(),
    );
    final counts = [for (final s in metadata.surahs) s.ayahCount];
    final uthmani = QuranTextParser.parse(
      uthmaniFile.readAsStringSync(),
      counts,
    );
    final clean = QuranTextParser.parse(cleanFile.readAsStringSync(), counts);
    text = QuranText(metadata: metadata, uthmani: uthmani, clean: clean);
    search = AyahSearchIndex(
      text: text,
      keys: AyahSearchIndex.buildKeys(clean),
      uthmaniKeys: AyahSearchIndex.buildKeys(uthmani),
    );
  });

  group('integrity', () {
    test('bundled files match the recorded SHA-256', () {
      expect(
        sha256.convert(uthmaniFile.readAsBytesSync()).toString(),
        QuranTextSource.uthmaniSha256,
      );
      expect(
        sha256.convert(cleanFile.readAsBytesSync()).toString(),
        QuranTextSource.cleanSha256,
      );
    });

    test('both files carry the Tanzil copyright block unmodified', () {
      for (final file in [uthmaniFile, cleanFile]) {
        final source = file.readAsStringSync();
        expect(
          source,
          contains('PLEASE DO NOT REMOVE OR CHANGE THIS COPYRIGHT BLOCK'),
        );
        expect(source, contains('License: Creative Commons Attribution 3.0'));
        expect(source, contains('tanzil.net'));
      }
    });

    test('has 6,236 ayahs matching the metadata surah by surah', () {
      expect(text.length, 6236);
      expect(metadata.totalAyahs, 6236);
      for (final surah in metadata.surahs) {
        expect(
          text.uthmaniOfSurah(surah.number),
          hasLength(surah.ayahCount),
          reason: 'surah ${surah.number}',
        );
      }
    });

    test('display text keeps tashkeel and the clean text has none', () {
      final marks = RegExp('[ً-ٰٟۖ-ۭ]');
      var withMarks = 0;
      for (var i = 0; i < text.length; i++) {
        final ref = text.refAt(i);
        if (marks.hasMatch(text.uthmani(ref))) withMarks++;
        expect(
          marks.hasMatch(text.clean(ref)),
          isFalse,
          reason: 'clean text of $ref has diacritics',
        );
      }
      expect(withMarks, greaterThan(6000));
    });
  });

  group('lookup', () {
    test('first and last ayahs', () {
      expect(text.uthmani(const AyahRef(1, 1)), startsWith('بِسْمِ'));
      expect(text.clean(const AyahRef(1, 1)), 'بسم الله الرحمن الرحيم');
      expect(text.clean(const AyahRef(114, 6)), contains('الجنة'));
    });

    test('indexOf and refAt are inverses for every ayah', () {
      for (var i = 0; i < text.length; i++) {
        expect(text.indexOf(text.refAt(i)), i);
      }
    });

    test('rejects an ayah outside its surah', () {
      expect(() => text.uthmani(const AyahRef(1, 8)), throwsRangeError);
      expect(() => text.uthmani(const AyahRef(115, 1)), throwsRangeError);
    });
  });

  group('pages', () {
    test('page 1 holds the whole of Al-Fatiha', () {
      final refs = metadata.ayahsOnPage(1);
      expect(refs.first, const AyahRef(1, 1));
      expect(refs.last, const AyahRef(1, 7));
      expect(refs, hasLength(7));
    });

    test('pages cover every ayah once, in order', () {
      final all = [
        for (var page = 1; page <= metadata.pageCount; page++)
          ...metadata.ayahsOnPage(page),
      ];
      expect(all, hasLength(6236));
      for (var i = 1; i < all.length; i++) {
        expect(all[i].compareTo(all[i - 1]), greaterThan(0));
      }
      expect(all.last, const AyahRef(114, 6));
    });

    test('Ayat al-Kursi is among the ayahs of page 42', () {
      const ref = AyahRef(2, 255);
      final onPage = text.pageAyahs(42);
      expect(onPage.map((a) => a.ref), contains(ref));
      final shown = onPage.firstWhere((a) => a.ref == ref).text;
      expect(
        normalizeSearchKey(shown),
        contains('الله لا اله الا هو الحي القيوم'),
      );
    });
  });

  group('search', () {
    test('finds Ayat al-Kursi without any tashkeel', () {
      final result = search.search('الله لا اله الا هو الحي القيوم');
      expect(result.matches.first.ref, const AyahRef(2, 255));
      expect(result.matches.first.page, 42);
    });

    test('ignores tashkeel, hamza forms, and ta marbuta in the query', () {
      final plain = search.search('الله لا اله الا هو').total;
      expect(plain, greaterThan(0));
      expect(search.search('ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ').total, plain);
      expect(search.search('الجنه').total, search.search('الجنة').total);
    });

    test('Arabic-Indic digits and extra spaces do not break it', () {
      expect(
        search.search('  الحمد   لله  رب  العالمين ').matches.first.ref,
        const AyahRef(1, 2),
      );
    });

    test('phrase matches come before scattered word matches', () {
      final result = search.search('الرحمن الرحيم', limit: 500);
      final firstScattered = result.matches.indexWhere(
        (m) => !normalizeSearchKey(text.clean(m.ref)).contains('الرحمن الرحيم'),
      );
      if (firstScattered != -1) {
        for (final m in result.matches.skip(firstScattered)) {
          expect(
            normalizeSearchKey(text.clean(m.ref)).contains('الرحمن الرحيم'),
            isFalse,
          );
        }
      }
      expect(result.matches.first.ref, const AyahRef(1, 1));
    });

    test('plain and Uthmani spellings of a word both match', () {
      // Uthmani writes some alefs as dagger alefs, so the folded spellings
      // differ ("العالمين" vs "العلمين"). Either query finds Al-Fatiha 1:2.
      for (final query in ['العالمين', 'العلمين', 'ٱلْعَٰلَمِينَ']) {
        final refs = search.search(query, limit: 500).matches.map((m) => m.ref);
        expect(refs, contains(const AyahRef(1, 2)), reason: query);
      }
    });

    test('limit caps the matches but not the total', () {
      final result = search.search('الله', limit: 5);
      expect(result.matches, hasLength(5));
      expect(result.total, greaterThan(5));
    });

    test('empty, blank, and unknown queries return nothing', () {
      expect(search.search('').total, 0);
      expect(search.search('   ').total, 0);
      expect(search.search('zzzz').total, 0);
    });

    test('a search over the whole Quran is fast', () {
      final watch = Stopwatch()..start();
      for (var i = 0; i < 20; i++) {
        search.search('الذين امنوا وعملوا الصالحات');
      }
      watch.stop();
      expect(watch.elapsedMilliseconds / 20, lessThan(50));
    });
  });

  group('parser', () {
    final counts = [2, 1];

    test('accepts a minimal valid file and skips comments', () {
      expect(QuranTextParser.parse('1|1|a\n1|2|b\n2|1|c\n# note\n\n', counts), [
        'a',
        'b',
        'c',
      ]);
    });

    test('rejects gaps, wrong order, and wrong counts', () {
      expect(
        () => QuranTextParser.parse('1|1|a\n1|3|b\n2|1|c', counts),
        throwsA(isA<QuranTextFormatException>()),
      );
      expect(
        () => QuranTextParser.parse('1|1|a\n2|1|c', counts),
        throwsA(isA<QuranTextFormatException>()),
      );
      expect(
        () => QuranTextParser.parse('1|1|a\n1|2|b', counts),
        throwsA(isA<QuranTextFormatException>()),
      );
      expect(
        () => QuranTextParser.parse('garbage', counts),
        throwsA(isA<QuranTextFormatException>()),
      );
    });
  });
}
