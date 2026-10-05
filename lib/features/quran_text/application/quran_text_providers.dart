import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../quran_index/application/quran_metadata_provider.dart';
import '../data/quran_text_source.dart';
import '../domain/ayah_search.dart';
import '../domain/quran_text.dart';

/// Provides the text source. Tests override it.
final quranTextSourceProvider = Provider<QuranTextSource>(
  (ref) => QuranTextSource(),
);

/// Verified text and search keys, loaded once and kept for the session.
final quranTextDataProvider = FutureProvider<QuranTextData>((ref) async {
  final metadata = await ref.watch(quranMetadataProvider.future);
  return ref.watch(quranTextSourceProvider).load([
    for (final surah in metadata.surahs) surah.ayahCount,
  ]);
});

/// The Quran text indexed by surah and ayah.
final quranTextProvider = FutureProvider<QuranText>((ref) async {
  final metadata = await ref.watch(quranMetadataProvider.future);
  final data = await ref.watch(quranTextDataProvider.future);
  return QuranText(
    metadata: metadata,
    uthmani: data.uthmani,
    clean: data.clean,
  );
});

/// Ayah search over the verified text, without needing tashkeel.
final ayahSearchIndexProvider = FutureProvider<AyahSearchIndex>((ref) async {
  final text = await ref.watch(quranTextProvider.future);
  final data = await ref.watch(quranTextDataProvider.future);
  return AyahSearchIndex(
    text: text,
    keys: data.keys,
    uthmaniKeys: data.uthmaniKeys,
  );
});
