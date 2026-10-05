import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/ayah_search.dart';
import '../domain/basmala_split.dart';
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

/// Parsed text lists plus the folded search keys.
class QuranTextData {
  /// Creates the data.
  const QuranTextData({
    required this.uthmani,
    required this.clean,
    required this.keys,
    required this.uthmaniKeys,
    required this.basmala,
    required this.prefixed,
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

  /// Folded search keys built from [clean].
  final List<String> keys;

  /// Folded search keys built from [uthmani].
  final List<String> uthmaniKeys;
}

/// Loads the bundled Tanzil text after verifying both checksums.
///
/// Provenance: https://tanzil.net/download, texts "Uthmani" and "Simple
/// Clean", format `txt-2`, version 1.1, Creative Commons Attribution 3.0,
/// copyright Tanzil Project. Both files are bundled unmodified, copyright
/// block included. See `docs/QURAN_SOURCES.md`.
class QuranTextSource {
  /// Creates a source reading from [bundle], the root bundle by default.
  QuranTextSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  /// Asset path of the Uthmani text.
  static const String uthmaniAsset = 'assets/quran/quran-uthmani.txt';

  /// Asset path of the text without diacritics.
  static const String cleanAsset = 'assets/quran/quran-simple-clean.txt';

  /// SHA-256 of [uthmaniAsset].
  static const String uthmaniSha256 =
      '6933e133dd56db778c801bf738848454e43648105a151e8d84d86a7cae39ec5f';

  /// SHA-256 of [cleanAsset].
  static const String cleanSha256 =
      '228df2a717671aeb9d2ff573002bd28d6b3f973f4bc7153554e3a81663d67610';

  final AssetBundle _bundle;

  /// Reads, verifies, and parses both files off the main isolate.
  ///
  /// [surahAyahCounts] holds the expected ayah count of each surah.
  Future<QuranTextData> load(List<int> surahAyahCounts) async {
    final uthmani = await _verified(uthmaniAsset, uthmaniSha256);
    final clean = await _verified(cleanAsset, cleanSha256);
    return compute(_parse, (
      uthmani: uthmani,
      clean: clean,
      counts: surahAyahCounts,
    ));
  }

  Future<Uint8List> _verified(String asset, String expected) async {
    final data = await _bundle.load(asset);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final actual = sha256.convert(bytes).toString();
    if (actual != expected) throw QuranTextIntegrityException(asset, actual);
    return bytes;
  }

  static QuranTextData _parse(
    ({Uint8List uthmani, Uint8List clean, List<int> counts}) input,
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
