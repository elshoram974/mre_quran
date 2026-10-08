import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/prayer_alerts.dart';
import '../domain/prayer_times.dart';

/// Stores the after-prayer choices and the last place, on the device only.
abstract interface class PrayerRepository {
  /// Returns the saved choices.
  Future<PrayerSettings> loadSettings();

  /// Replaces the saved choices.
  Future<void> saveSettings(PrayerSettings settings);

  /// Returns the last place worked out, if any.
  Future<PrayerPlace?> loadPlace();

  /// Replaces the saved place.
  Future<void> savePlace(PrayerPlace place);
}

/// SharedPreferences-backed [PrayerRepository].
class LocalPrayerRepository implements PrayerRepository {
  /// Creates a repository over [preferences].
  LocalPrayerRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _settingsKey = 'prayer.settings';
  static const _placeKey = 'prayer.place';

  Future<Object?> _read(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<PrayerSettings> loadSettings() async =>
      PrayerSettings.fromJson(await _read(_settingsKey));

  @override
  Future<void> saveSettings(PrayerSettings settings) =>
      _preferences.setString(_settingsKey, jsonEncode(settings.toJson()));

  @override
  Future<PrayerPlace?> loadPlace() async =>
      PrayerPlace.tryFromJson(await _read(_placeKey));

  @override
  Future<void> savePlace(PrayerPlace place) =>
      _preferences.setString(_placeKey, jsonEncode(place.toJson()));
}
