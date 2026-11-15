import 'dart:io';

import 'package:mre_quran/features/quran_text/data/quran_text_source.dart';

/// Reads the real text files synchronously so widget tests finish loading.
class FakeQuranTextSource extends QuranTextSource {
  @override
  Future<QuranTextData> load(List<int> surahAyahCounts) async =>
      QuranTextSource.parse((
        uthmani: File(QuranTextSource.uthmaniAsset).readAsBytesSync(),
        clean: File(QuranTextSource.cleanAsset).readAsBytesSync(),
        mushaf: File(QuranTextSource.mushafAsset).readAsBytesSync(),
        counts: surahAyahCounts,
      ));
}
