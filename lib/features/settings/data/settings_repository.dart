import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SettingsRepository {
  Future<ThemeMode> loadThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
}

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _themeKey = 'settings.theme_mode';

  @override
  Future<ThemeMode> loadThemeMode() async {
    final stored = await _preferences.getString(_themeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) =>
      _preferences.setString(_themeKey, mode.name);
}
