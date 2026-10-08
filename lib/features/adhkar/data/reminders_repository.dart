import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reminder_setting.dart';

/// Stores the reminder choices on the device, keyed by collection id.
abstract interface class RemindersRepository {
  /// Returns the saved settings. Unreadable entries are skipped.
  Future<Map<String, ReminderSetting>> load();

  /// Replaces the saved settings.
  Future<void> save(Map<String, ReminderSetting> settings);
}

/// SharedPreferences-backed [RemindersRepository].
class LocalRemindersRepository implements RemindersRepository {
  /// Creates a repository over [preferences].
  LocalRemindersRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _key = 'adhkar.reminders';

  @override
  Future<Map<String, ReminderSetting>> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return const {};
      return {
        for (final entry in decoded.entries)
          entry.key: ?ReminderSetting.tryFromJson(entry.value),
      };
    } on FormatException {
      return const {};
    }
  }

  @override
  Future<void> save(Map<String, ReminderSetting> settings) =>
      _preferences.setString(
        _key,
        jsonEncode({
          for (final entry in settings.entries) entry.key: entry.value.toJson(),
        }),
      );
}
