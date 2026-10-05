import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../data/reading_position_repository.dart';

/// Number of pages in the Madinah Mushaf.
const int mushafPageCount = 604;

/// Provides the reading-position store.
final readingPositionRepositoryProvider = Provider<ReadingPositionRepository>(
  (ref) => LocalReadingPositionRepository(SharedPreferencesAsync()),
);

/// The page the reader is on. Page 1 until the reader has read elsewhere.
final readingPositionProvider =
    AsyncNotifierProvider<ReadingPositionNotifier, int>(
      ReadingPositionNotifier.new,
    );

/// Owns the current Mushaf page.
class ReadingPositionNotifier extends AsyncNotifier<int> {
  ReadingPositionRepository get _repository =>
      ref.read(readingPositionRepositoryProvider);

  @override
  Future<int> build() async {
    final saved = await _repository.loadPage();
    return _valid(saved) ? saved! : 1;
  }

  /// Moves to [page] at once and saves it in the background.
  Future<void> setPage(int page) async {
    if (!_valid(page)) return;
    final previous = state.value;
    state = AsyncData(page);
    try {
      await _repository.savePage(page);
    } on Object catch (error) {
      AppLogger.debug('Reading position save failed: ${error.runtimeType}');
      if (previous != null) state = AsyncData(previous);
    }
  }

  static bool _valid(int? page) =>
      page != null && page >= 1 && page <= mushafPageCount;
}
