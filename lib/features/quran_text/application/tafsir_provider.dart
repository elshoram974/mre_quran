import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mushaf/domain/mushaf_edition.dart';
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

/// The Hafs ayah(s) an ayah of [edition] is, by its words: itself for Hafs
/// and for a reading that counts as Hafs, else from the reading's map.
final hafsAyahsProvider =
    FutureProvider.family<List<AyahRef>, (MushafEdition, AyahRef)>((
      ref,
      key,
    ) async {
      final (edition, ayah) = key;
      final map = await ref.watch(hafsMapProvider(edition).future);
      return map[ayah] ?? [ayah];
    });

/// The map of [edition]'s ayahs to Hafs's, where their numbers differ;
/// empty for Hafs and a reading that counts as Hafs.
final hafsMapProvider =
    FutureProvider.family<Map<AyahRef, List<AyahRef>>, MushafEdition>((
      ref,
      edition,
    ) async {
      final text = edition.text;
      final asset = text?.hafsMap;
      if (edition.matchesAppText || text == null || asset == null) {
        return const {};
      }
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (sha256.convert(bytes).toString() != text.hafsMapSha256) {
        throw StateError('$asset does not match its checksum');
      }
      return parseHafsMap(utf8.decode(bytes));
    });

/// Reads `surah|ayah|hafs,hafs` lines.
Map<AyahRef, List<AyahRef>> parseHafsMap(String source) {
  final map = <AyahRef, List<AyahRef>>{};
  for (final line in source.split('\n')) {
    if (line.trim().isEmpty) continue;
    final [surah, ayah, hafs] = line.split('|');
    final number = int.parse(surah);
    map[AyahRef(number, int.parse(ayah))] = [
      for (final value in hafs.split(','))
        if (value.isNotEmpty) AyahRef(number, int.parse(value)),
    ];
  }
  return map;
}

/// The tafsir of an ayah of [edition]: of each Hafs ayah it is, in order.
final readingTafsirProvider =
    FutureProvider.family<
      List<({AyahRef hafs, Tafsir tafsir})>,
      (MushafEdition, AyahRef)
    >((ref, key) async {
      final hafs = await ref.watch(hafsAyahsProvider(key).future);
      return [
        for (final ayah in hafs)
          (
            hafs: ayah,
            tafsir: await ref.watch(ayahTafsirProvider(ayah).future),
          ),
      ];
    });
