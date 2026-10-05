import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/quran_metadata.dart';
import 'quran_metadata_parser.dart';

/// Raised when the bundled file does not match the recorded checksum.
class QuranIntegrityException implements Exception {
  /// Creates the exception.
  const QuranIntegrityException(this.actual);

  /// SHA-256 that was computed.
  final String actual;

  @override
  String toString() =>
      'QuranIntegrityException: unexpected checksum $actual for '
      '${QuranMetadataSource.assetPath}';
}

/// Loads the Tanzil metadata asset after verifying its checksum.
///
/// Provenance: https://tanzil.net/res/text/metadata/quran-data.xml, licence
/// `cc-by` (declared in the file), copyright Tanzil.info. The file is bundled
/// unmodified. See `docs/QURAN_SOURCES.md`.
class QuranMetadataSource {
  /// Creates a source reading from [bundle], the root bundle by default.
  QuranMetadataSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  /// Asset path of the bundled file.
  static const String assetPath = 'assets/quran/quran-data.xml';

  /// SHA-256 of the bundled file.
  static const String sha256Hex =
      '8867c1d88191472adec9db694b3cd9f135b1a2ef580574d32cf888dcb22c5c7a';

  final AssetBundle _bundle;

  /// Reads, verifies, and parses the file. Parsing runs off the main isolate.
  Future<QuranMetadata> load() async {
    final data = await _bundle.load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final actual = sha256.convert(bytes).toString();
    if (actual != sha256Hex) throw QuranIntegrityException(actual);
    return compute(_parse, bytes);
  }

  static QuranMetadata _parse(Uint8List bytes) =>
      QuranMetadataParser.parse(utf8.decode(bytes));
}
