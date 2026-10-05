import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the Mushaf page the reader was on.
abstract interface class ReadingPositionRepository {
  /// Returns the saved page, or null if none was saved.
  Future<int?> loadPage();

  /// Saves [page] as the current page.
  Future<void> savePage(int page);
}

/// SharedPreferences-backed [ReadingPositionRepository].
class LocalReadingPositionRepository implements ReadingPositionRepository {
  /// Creates a repository over [preferences].
  LocalReadingPositionRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _key = 'reader.last_page';

  @override
  Future<int?> loadPage() => _preferences.getInt(_key);

  @override
  Future<void> savePage(int page) => _preferences.setInt(_key, page);
}
