import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/ayah_search.dart';
import '../domain/basmala_split.dart';
import 'kfgqpc_hafs_parser.dart';
import 'quran_text_parser.dart';

/// Raised when a bundled text file does not match its recorded checksum.
class QuranTextIntegrityException implements Exception {
  /// Creates the exception.
  const QuranTextIntegrityException(this.asset, this.actual);

  /// Asset that failed.
  final String asset;

  /// SHA-256 that was computed.
  final String actual;

  @override
  String toString() =>
      'QuranTextIntegrityException: unexpected checksum $actual for $asset';
}

/// Parsed text lists. The folded search keys are built from them only when
/// search is first used ([QuranSearchKeys.build]), so start-up does not wait
/// for them.
class QuranTextData {
  /// Creates the data.
  const QuranTextData({
    required this.uthmani,
    required this.clean,
    required this.basmala,
    required this.prefixed,
    required this.mushaf,
    required this.marks,
    required this.plain,
  });

  /// The basmala as written in ayah 1:1.
  final String basmala;

  /// Per surah (index 0 is surah 1): whether the source prefixed the basmala to
  /// its first ayah. The prefix is already removed from [uthmani] and [clean].
  final List<bool> prefixed;

  /// Display text, one entry per ayah, with tashkeel and no basmala prefix.
  final List<String> uthmani;

  /// Text without diacritics, one entry per ayah, no basmala prefix.
  final List<String> clean;

  /// The ayahs in the King Fahd Complex Mushaf script, for the reader. Drawn
  /// with the Complex's own font; one entry per ayah, no basmala prefix.
  final List<String> mushaf;

  /// The ayah-number glyph that ends each entry of [mushaf] in print.
  final List<String> marks;

  /// The Complex's plain spelling of each ayah, for search.
  final List<String> plain;
}

/// The folded search keys of the three spellings: [keys] from the text
/// without diacritics, [uthmaniKeys] from the Uthmani text, [plainKeys] from
/// the Complex's plain spelling.
typedef QuranSearchKeys = ({
  List<String> keys,
  List<String> uthmaniKeys,
  List<String> plainKeys,
});

/// Builds [QuranSearchKeys] off the main isolate.
Future<QuranSearchKeys> buildQuranSearchKeys(QuranTextData data) => compute(
  _searchKeys,
  (clean: data.clean, uthmani: data.uthmani, plain: data.plain),
);

QuranSearchKeys _searchKeys(
  ({List<String> clean, List<String> uthmani, List<String> plain}) text,
) => (
  keys: AyahSearchIndex.buildKeys(text.clean),
  uthmaniKeys: AyahSearchIndex.buildKeys(text.uthmani),
  plainKeys: AyahSearchIndex.buildKeys(text.plain),
);

/// Loads the bundled Quran text after verifying every checksum: the Tanzil
/// text (copying, sharing, adhkar, search) and the King Fahd Complex Mushaf
/// script (the reader, and a third search spelling).
///
/// Provenance: https://tanzil.net/download, texts "Uthmani" and "Simple
/// Clean", format `txt-2`, version 1.1, Creative Commons Attribution 3.0,
/// copyright Tanzil Project. Both files are bundled unmodified, copyright
/// block included. The Mushaf script is the Complex's "Tafseer Mouaser"
/// data, version 3, bundled unmodified. See `docs/QURAN_SOURCES.md`.
class QuranTextSource {
  /// Creates a source reading from [bundle], the root bundle by default.
  QuranTextSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  /// Asset path of the Uthmani text.
  static const String uthmaniAsset = 'assets/quran/quran-uthmani.txt';

  /// Asset path of the text without diacritics.
  static const String cleanAsset = 'assets/quran/quran-simple-clean.txt';

  /// Asset path of the King Fahd Complex Mushaf-script data.
  static const String mushafAsset =
      'assets/quran/kfgqpc/tafseerMouaser_v03.txt';

  /// SHA-256 of [mushafAsset].
  static const String mushafSha256 =
      'df92e4e2c86b0a57cf67c31e710b55db00f04ba0ee6f18c497bb5f8b1b1be0cc';

  /// SHA-256 of [uthmaniAsset].
  static const String uthmaniSha256 =
      '6933e133dd56db778c801bf738848454e43648105a151e8d84d86a7cae39ec5f';

  /// SHA-256 of [cleanAsset].
  static const String cleanSha256 =
      '228df2a717671aeb9d2ff573002bd28d6b3f973f4bc7153554e3a81663d67610';

  final AssetBundle _bundle;

  /// Reads the three files at once, then verifies and parses them off the
  /// main isolate, so start-up never waits on the main thread.
  ///
  /// [surahAyahCounts] holds the expected ayah count of each surah.
  Future<QuranTextData> load(List<int> surahAyahCounts) async {
    final (uthmani, clean, mushaf) = await (
      _bytes(uthmaniAsset),
      _bytes(cleanAsset),
      _bytes(mushafAsset),
    ).wait;
    return compute(verifyAndParse, (
      uthmani: uthmani,
      clean: clean,
      mushaf: mushaf,
      counts: surahAyahCounts,
    ));
  }

  Future<Uint8List> _bytes(String asset) async {
    final data = await _bundle.load(asset);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// Checks each file against its SHA-256, then parses them. Throws a
  /// [QuranTextIntegrityException] for a file that differs.
  static QuranTextData verifyAndParse(
    ({Uint8List uthmani, Uint8List clean, Uint8List mushaf, List<int> counts})
    input,
  ) {
    for (final (asset, bytes, expected) in [
      (uthmaniAsset, input.uthmani, uthmaniSha256),
      (cleanAsset, input.clean, cleanSha256),
      (mushafAsset, input.mushaf, mushafSha256),
    ]) {
      final actual = sha256.convert(bytes).toString();
      if (actual != expected) throw QuranTextIntegrityException(asset, actual);
    }
    return parse(input);
  }

  /// Parses the three verified files into text lists.
  /// Public so tests can run it on the real files without an asset bundle.
  static QuranTextData parse(
    ({Uint8List uthmani, Uint8List clean, Uint8List mushaf, List<int> counts})
    input,
  ) {
    final uthmani = QuranTextParser.parse(
      utf8.decode(input.uthmani),
      input.counts,
    );
    final clean = QuranTextParser.parse(utf8.decode(input.clean), input.counts);
    final split = splitBasmala(
      surahAyahCounts: input.counts,
      uthmani: uthmani,
      clean: clean,
    );
    final mushaf = KfgqpcHafsParser.parse(
      utf8.decode(input.mushaf),
      input.counts,
    );
    return QuranTextData(
      uthmani: split.uthmani,
      clean: split.clean,
      basmala: split.basmala,
      prefixed: split.prefixed,
      mushaf: mushaf.text,
      marks: mushaf.marks,
      plain: mushaf.plain,
    );
  }
}
