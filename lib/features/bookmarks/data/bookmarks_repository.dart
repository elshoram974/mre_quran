import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/bookmark.dart';

/// Stores the reader's bookmarks on the device.
abstract interface class BookmarksRepository {
  /// Returns the saved bookmarks, oldest first. Unreadable entries are skipped.
  Future<List<Bookmark>> load();

  /// Replaces the saved bookmarks.
  Future<void> save(List<Bookmark> bookmarks);
}

/// SharedPreferences-backed [BookmarksRepository].
class LocalBookmarksRepository implements BookmarksRepository {
  /// Creates a repository over [preferences].
  LocalBookmarksRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _key = 'bookmarks.items';

  @override
  Future<List<Bookmark>> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<Object?>) return const [];
      return [for (final item in decoded) ?Bookmark.tryFromJson(item)];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> save(List<Bookmark> bookmarks) => _preferences.setString(
    _key,
    jsonEncode([for (final bookmark in bookmarks) bookmark.toJson()]),
  );
}
