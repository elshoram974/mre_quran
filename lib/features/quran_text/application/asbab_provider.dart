import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quran_text_source.dart';
import '../domain/asbab.dart';

/// The bundled occasions of revelation (see `tool/build_asbab.py` and
/// `docs/QURAN_SOURCES.md`).
abstract final class AsbabAsset {
  /// Where they are.
  static const String path = 'assets/quran/asbab/wahidi.json.gz';

  /// Their SHA-256, checked before they are read.
  static const String sha256Hex =
      '62ca0e9e0dbcae8e3047cda3c655f56461d3acfb7de02209e84a8848eba31010';
}

/// Reads the bytes of the occasions' file. Tests replace it.
final asbabBytesProvider = Provider<Future<Uint8List> Function()>(
  (ref) => () async {
    final data = await rootBundle.load(AsbabAsset.path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  },
);

/// Al-Wahidi's occasions of revelation, read the first time they are asked
/// for, never at start-up: checked against their SHA-256, unpacked and parsed
/// on another isolate.
final asbabProvider = FutureProvider<Asbab>((ref) async {
  final bytes = await ref.read(asbabBytesProvider)();
  return Isolate.run(() => decodeAsbab(bytes));
});

/// [bytes] checked and read; throws when they are not the bundled file.
Asbab decodeAsbab(Uint8List bytes) {
  final actual = sha256.convert(bytes).toString();
  if (actual != AsbabAsset.sha256Hex) {
    throw QuranTextIntegrityException(AsbabAsset.path, actual);
  }
  return Asbab.parse(utf8.decode(gzip.decode(bytes)));
}
