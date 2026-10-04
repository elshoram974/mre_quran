import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/settings/presentation/settings_controller.dart';

import 'helpers/memory_settings_repository.dart';

void main() {
  test('Saved theme survives creating a new controller', () async {
    final repository = MemorySettingsRepository();
    final first = SettingsController(repository);
    final second = SettingsController(repository);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await first.setThemeMode(ThemeMode.dark);
    await second.load();
    expect(second.themeMode, ThemeMode.dark);
  });

  test('Read failure uses system theme and retry clears error', () async {
    final repository = MemorySettingsRepository()..fail = true;
    final settings = SettingsController(repository);
    addTearDown(settings.dispose);
    await settings.load();
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.error, isNotNull);
    repository.fail = false;
    await settings.load();
    expect(settings.error, isNull);
  });

  test('Write failure retains theme and permits retry', () async {
    final repository = MemorySettingsRepository()..fail = true;
    final settings = SettingsController(repository);
    addTearDown(settings.dispose);
    await settings.setThemeMode(ThemeMode.dark);
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.error, isNotNull);
    expect(settings.saving, isFalse);
    repository.fail = false;
    await settings.setThemeMode(ThemeMode.dark);
    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.error, isNull);
  });
}
