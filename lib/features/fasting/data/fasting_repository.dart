import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/sunnah_fasts.dart';

/// Keeps the fasting reminders' choices.
abstract interface class FastingRepository {
  /// The saved choices, or the defaults.
  Future<FastingSettings> load();

  /// Saves [settings].
  Future<void> save(FastingSettings settings);
}

/// [FastingRepository] on the device's preferences.
class LocalFastingRepository implements FastingRepository {
  /// Creates the store over [preferences].
  LocalFastingRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const String _key = 'fasting.reminders';

  @override
  Future<FastingSettings> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return const FastingSettings();
    try {
      return FastingSettings.fromJson(jsonDecode(raw));
    } on FormatException {
      return const FastingSettings();
    }
  }

  @override
  Future<void> save(FastingSettings settings) =>
      _preferences.setString(_key, jsonEncode(settings.toJson()));
}
