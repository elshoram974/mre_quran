import 'package:mre_quran/features/bookmarks/data/bookmarks_repository.dart';
import 'package:mre_quran/features/bookmarks/domain/bookmark.dart';

class MemoryBookmarksRepository implements BookmarksRepository {
  List<Bookmark> items = [];
  bool fail = false;

  @override
  Future<List<Bookmark>> load() async => items;

  @override
  Future<void> save(List<Bookmark> bookmarks) async {
    if (fail) throw StateError('Storage unavailable');
    items = bookmarks;
  }
}
