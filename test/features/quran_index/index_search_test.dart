import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_source.dart';
import 'package:mre_quran/features/quran_index/domain/index_search.dart';

void main() {
  final metadata = QuranMetadataParser.parse(
    File(QuranMetadataSource.assetPath).readAsStringSync(),
  );
  final searcher = IndexSearcher(metadata);

  group('normalizeSearchKey', () {
    test('ignores diacritics and unifies letter forms', () {
      expect(normalizeSearchKey('الرَّحْمَٰن'), normalizeSearchKey('الرحمن'));
      expect(normalizeSearchKey('أحمد'), normalizeSearchKey('احمد'));
      expect(normalizeSearchKey('مائدة'), normalizeSearchKey('مايدة'));
    });

    test('maps Arabic-Indic digits to Latin', () {
      expect(normalizeSearchKey('٢٥'), '25');
      expect(normalizeSearchKey('۱۲'), '12');
    });
  });

  group('searchSurahs', () {
    test('empty query returns everything', () {
      expect(searcher.surahs('  '), hasLength(114));
    });

    test('finds by Arabic name without diacritics', () {
      final names = searcher.surahs('بقره').map((s) => s.number);
      expect(names, contains(2));
    });

    test('finds by transliteration, English name, and number', () {
      expect(searcher.surahs('faatiha').single.number, 1);
      expect(searcher.surahs('the cow').single.number, 2);
      expect(searcher.surahs('36').single.number, 36);
    });
  });

  test('searchJuzs finds by number', () {
    expect(searcher.juzs('3').map((j) => j.number), contains(3));
    expect(searcher.juzs(''), hasLength(30));
  });
}
