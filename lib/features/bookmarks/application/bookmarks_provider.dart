import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../data/bookmarks_repository.dart';
import '../domain/bookmark.dart';

/// Provides the bookmark store.
final bookmarksRepositoryProvider = Provider<BookmarksRepository>(
  (ref) => LocalBookmarksRepository(SharedPreferencesAsync()),
);

/// The reader's bookmarks, oldest first.
final bookmarksProvider =
    AsyncNotifierProvider<BookmarksNotifier, List<Bookmark>>(
      BookmarksNotifier.new,
    );

/// Ayahs that are bookmarked, for marking them on the page.
final bookmarkedRefsProvider = Provider<Set<AyahRef>>((ref) {
  final bookmarks = ref.watch(bookmarksProvider).value ?? const <Bookmark>[];
  return {for (final bookmark in bookmarks) bookmark.ref};
});

/// Owns the bookmarks. Changes show at once and are saved in the background;
/// a failed save restores the previous list.
class BookmarksNotifier extends AsyncNotifier<List<Bookmark>> {
  BookmarksRepository get _repository => ref.read(bookmarksRepositoryProvider);

  @override
  Future<List<Bookmark>> build() => _repository.load();

  /// Bookmarks [target], or removes the bookmark if it already exists.
  Future<void> toggle(AyahRef target) {
    final current = state.value ?? const <Bookmark>[];
    final exists = current.any((bookmark) => bookmark.ref == target);
    return _apply(
      exists
          ? [
              for (final bookmark in current)
                if (bookmark.ref != target) bookmark,
            ]
          : [
              ...current,
              Bookmark(ref: target, createdAt: DateTime.now().toUtc()),
            ],
    );
  }

  /// Removes the bookmark of [target], if any.
  Future<void> remove(AyahRef target) => _apply([
    for (final bookmark in state.value ?? const <Bookmark>[])
      if (bookmark.ref != target) bookmark,
  ]);

  Future<void> _apply(List<Bookmark> next) async {
    final previous = state.value;
    state = AsyncData(next);
    try {
      await _repository.save(next);
    } on Object catch (error) {
      AppLogger.debug('Bookmarks save failed: ${error.runtimeType}');
      if (previous != null) state = AsyncData(previous);
    }
  }
}
