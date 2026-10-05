import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the last top-level tab the reader used.
abstract interface class LastTabRepository {
  /// Returns the saved tab path, or null if none was saved.
  Future<String?> load();

  /// Saves [path] as the last used tab.
  Future<void> save(String path);
}

/// SharedPreferences-backed [LastTabRepository].
class LocalLastTabRepository implements LastTabRepository {
  /// Creates a repository over [preferences].
  LocalLastTabRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _key = 'navigation.last_tab';

  @override
  Future<String?> load() => _preferences.getString(_key);

  @override
  Future<void> save(String path) => _preferences.setString(_key, path);
}
