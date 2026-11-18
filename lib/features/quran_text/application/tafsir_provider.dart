import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../quran_index/domain/quran_metadata.dart';
import '../data/kfgqpc_tafsir_parser.dart';
import '../data/quran_text_source.dart';
import '../domain/tafsir.dart';
import 'quran_text_providers.dart';

/// Reads the bytes of the tafsir's file. Tests replace it.
final tafsirBytesProvider = Provider<Future<Uint8List> Function()>(
  (ref) => () async {
    final data = await rootBundle.load(QuranTextSource.mushafAsset);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  },
);

/// Al-Tafsir Al-Muyassar of every ayah, read the first time it is asked
/// for, never at start-up: checked against its SHA-256 and parsed on
/// another isolate.
final tafsirTextProvider = FutureProvider<List<String>>((ref) async {
  final text = await ref.watch(quranTextProvider.future);
  final bytes = await ref.read(tafsirBytesProvider)();
  final count = text.metadata.surahs.fold(0, (sum, s) => sum + s.ayahCount);
  return Isolate.run(() {
    final actual = sha256.convert(bytes).toString();
    if (actual != QuranTextSource.mushafSha256) {
      throw QuranTextIntegrityException(QuranTextSource.mushafAsset, actual);
    }
    return KfgqpcTafsirParser.parse(utf8.decode(bytes), ayahCount: count);
  });
});

/// The tafsir of one ayah of the app's own (Hafs) text.
final ayahTafsirProvider = FutureProvider.family<Tafsir, AyahRef>((
  ref,
  ayah,
) async {
  final text = await ref.watch(quranTextProvider.future);
  final all = await ref.watch(tafsirTextProvider.future);
  return Tafsir.parse(all[text.indexOf(ayah)]);
});
