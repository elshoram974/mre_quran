import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quran_metadata_source.dart';
import '../domain/index_search.dart';
import '../domain/quran_metadata.dart';

/// Provides the metadata source. Tests override it.
final quranMetadataSourceProvider = Provider<QuranMetadataSource>(
  (ref) => QuranMetadataSource(),
);

/// Verified Quran index data, loaded once and kept for the session.
final quranMetadataProvider = FutureProvider<QuranMetadata>(
  (ref) => ref.watch(quranMetadataSourceProvider).load(),
);

/// Search keys for the index, built once after the metadata loads.
final indexSearcherProvider = FutureProvider<IndexSearcher>((ref) async {
  final metadata = await ref.watch(quranMetadataProvider.future);
  return IndexSearcher(metadata);
});
