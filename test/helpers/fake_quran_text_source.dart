import 'dart:io';

import 'package:mre_quran/features/quran_text/data/quran_text_parser.dart';
import 'package:mre_quran/features/quran_text/data/quran_text_source.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_search.dart';
import 'package:mre_quran/features/quran_text/domain/basmala_split.dart';

/// Reads the real text files synchronously so widget tests finish loading.
class FakeQuranTextSource extends QuranTextSource {
  @override
  Future<QuranTextData> load(List<int> surahAyahCounts) async {
    final split = splitBasmala(
      surahAyahCounts: surahAyahCounts,
      uthmani: QuranTextParser.parse(
        File(QuranTextSource.uthmaniAsset).readAsStringSync(),
        surahAyahCounts,
      ),
      clean: QuranTextParser.parse(
        File(QuranTextSource.cleanAsset).readAsStringSync(),
        surahAyahCounts,
      ),
    );
    return QuranTextData(
      uthmani: split.uthmani,
      clean: split.clean,
      keys: AyahSearchIndex.buildKeys(split.clean),
      uthmaniKeys: AyahSearchIndex.buildKeys(split.uthmani),
      basmala: split.basmala,
      prefixed: split.prefixed,
    );
  }
}
