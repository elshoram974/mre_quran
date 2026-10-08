import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores the lists the reader starred, oldest first.
abstract interface class AdhkarFavoritesRepository {
  /// Returns the starred collection ids. Unreadable data gives an empty list.
  Future<List<String>> load();

  /// Replaces the starred ids.
  Future<void> save(List<String> ids);
}

/// SharedPreferences-backed [AdhkarFavoritesRepository].
class LocalAdhkarFavoritesRepository implements AdhkarFavoritesRepository {
  /// Creates a repository over [preferences].
  LocalAdhkarFavoritesRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _key = 'adhkar.favorites';

  @override
  Future<List<String>> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<Object?>) return const [];
      return [
        for (final item in decoded)
          if (item is String) item,
      ];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> save(List<String> ids) =>
      _preferences.setString(_key, jsonEncode(ids));
}
