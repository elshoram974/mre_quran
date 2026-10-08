import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../domain/adhkar_collection.dart';
import '../domain/dhikr.dart';
import 'adhkar_parser.dart';

/// Raised when a bundled adhkar file does not match its recorded checksum.
class AdhkarIntegrityException implements Exception {
  /// Creates the exception.
  const AdhkarIntegrityException(this.asset, this.actual);

  /// Asset that failed.
  final String asset;

  /// SHA-256 that was computed.
  final String actual;

  @override
  String toString() =>
      'AdhkarIntegrityException: unexpected checksum $actual for $asset';
}

/// Loads the bundled adhkar after verifying every file against the manifest.
///
/// Add or change content by editing `assets/adhkar/` only; see
/// `docs/ADHKAR_SOURCES.md`. The morning and evening file is the unmodified
/// `ar.json` of Seen-Arabic/Morning-And-Evening-Adhkar-DB (MIT).
class AdhkarSource {
  /// Creates a source reading from [bundle], the root bundle by default.
  AdhkarSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  /// Folder holding the manifest and the entry files.
  static const String folder = 'assets/adhkar';

  /// Asset path of the manifest.
  static const String manifestAsset = '$folder/manifest.json';

  final AssetBundle _bundle;

  /// Reads, verifies, and parses every collection.
  ///
  /// The files are small (under 100 KB), so parsing stays on the main isolate.
  Future<AdhkarCatalog> load() async {
    final specs = AdhkarParser.parseManifest(
      await _bundle.loadString(manifestAsset),
    );
    final parsed = <String, List<Dhikr>>{};
    for (final spec in specs) {
      if (parsed.containsKey(spec.file)) continue;
      final asset = '$folder/${spec.file}';
      final data = await _bundle.load(asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final actual = sha256.convert(bytes).toString();
      if (actual != spec.sha256) throw AdhkarIntegrityException(asset, actual);
      parsed[spec.file] = AdhkarParser.parseEntries(utf8.decode(bytes));
    }
    return AdhkarCatalog([
      for (final spec in specs) spec.build(parsed[spec.file]!),
    ]);
  }
}
