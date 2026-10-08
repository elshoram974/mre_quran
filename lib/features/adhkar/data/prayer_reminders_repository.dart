import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/prayer_reminders.dart';

/// Stores the after-prayer choices and the last place, on the device only.
abstract interface class PrayerRemindersRepository {
  /// Returns the saved choices.
  Future<PrayerReminderSettings> loadSettings();

  /// Replaces the saved choices.
  Future<void> saveSettings(PrayerReminderSettings settings);

  /// Returns the last place worked out, if any.
  Future<PrayerPlace?> loadPlace();

  /// Replaces the saved place.
  Future<void> savePlace(PrayerPlace place);
}

/// SharedPreferences-backed [PrayerRemindersRepository].
class LocalPrayerRemindersRepository implements PrayerRemindersRepository {
  /// Creates a repository over [preferences].
  LocalPrayerRemindersRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _settingsKey = 'adhkar.prayer_reminders';
  static const _placeKey = 'adhkar.prayer_place';

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
  Future<PrayerReminderSettings> loadSettings() async =>
      PrayerReminderSettings.fromJson(await _read(_settingsKey));

  @override
  Future<void> saveSettings(PrayerReminderSettings settings) =>
      _preferences.setString(_settingsKey, jsonEncode(settings.toJson()));

  @override
  Future<PrayerPlace?> loadPlace() async =>
      PrayerPlace.tryFromJson(await _read(_placeKey));

  @override
  Future<void> savePlace(PrayerPlace place) =>
      _preferences.setString(_placeKey, jsonEncode(place.toJson()));
}
