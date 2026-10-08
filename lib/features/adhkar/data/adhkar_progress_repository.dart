import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/adhkar_progress.dart';

/// Stores today's adhkar counts on the device.
abstract interface class AdhkarProgressRepository {
  /// Returns the saved progress for [day], or an empty one when the saved data
  /// is from another day or unreadable.
  Future<AdhkarProgress> load(String day);

  /// Replaces the saved progress.
  Future<void> save(AdhkarProgress progress);
}

/// SharedPreferences-backed [AdhkarProgressRepository].
class LocalAdhkarProgressRepository implements AdhkarProgressRepository {
  /// Creates a repository over [preferences].
  LocalAdhkarProgressRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _key = 'adhkar.progress';

  @override
  Future<AdhkarProgress> load(String day) async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return AdhkarProgress(day: day);
    try {
      return AdhkarProgress.fromJson(jsonDecode(raw), day: day);
    } on FormatException {
      return AdhkarProgress(day: day);
    }
  }

  @override
  Future<void> save(AdhkarProgress progress) =>
      _preferences.setString(_key, jsonEncode(progress.toJson()));
}
