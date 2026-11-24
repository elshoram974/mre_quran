import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/custom_reminder.dart';

/// Stores the reminders the person made, on the device only.
abstract interface class CustomRemindersRepository {
  /// Returns the saved reminders. Unreadable entries are skipped.
  Future<List<CustomReminder>> load();

  /// Replaces the saved reminders.
  Future<void> save(List<CustomReminder> reminders);
}

/// SharedPreferences-backed [CustomRemindersRepository].
class LocalCustomRemindersRepository implements CustomRemindersRepository {
  /// Creates a repository over [preferences].
  LocalCustomRemindersRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _key = 'reminders.custom';

  @override
  Future<List<CustomReminder>> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return const [];
    try {
      return parseCustomReminders(jsonDecode(raw));
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> save(List<CustomReminder> reminders) => _preferences.setString(
    _key,
    jsonEncode([for (final reminder in reminders) reminder.toJson()]),
  );
}
