import 'package:flutter/material.dart';
import 'package:mre_quran/features/settings/data/settings_repository.dart';

class MemorySettingsRepository implements SettingsRepository {
  ThemeMode mode = ThemeMode.system;
  bool fail = false;

  @override
  Future<ThemeMode> loadThemeMode() async {
    if (fail) throw StateError('Storage unavailable');
    return mode;
  }

  @override
  Future<void> saveThemeMode(ThemeMode value) async {
    if (fail) throw StateError('Storage unavailable');
    mode = value;
  }
}
