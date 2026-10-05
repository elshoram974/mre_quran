import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';

/// Stores application settings locally on the device.
abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

/// SharedPreferences-backed [SettingsRepository].
class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _themeKey = 'settings.theme';
  static const _localeKey = 'settings.locale';
  static const _reduceMotionKey = 'settings.reduce_motion';
  static const _arabicDigitsKey = 'settings.arabic_digits';
  static const _crashReportsKey = 'settings.crash_reports';
  static const _startupKey = 'settings.startup';

  @override
  Future<AppSettings> load() async {
    final theme = await _preferences.getString(_themeKey);
    final locale = await _preferences.getString(_localeKey);
    final reduceMotion = await _preferences.getBool(_reduceMotionKey);
    final useArabicDigits = await _preferences.getBool(_arabicDigitsKey);
    final crashReportsEnabled = await _preferences.getBool(_crashReportsKey);
    final startup = await _preferences.getString(_startupKey);
    return AppSettings(
      theme: AppThemePreference.values.firstWhere(
        (item) => item.name == theme,
        orElse: () => AppThemePreference.system,
      ),
      localeCode: locale == 'en' ? 'en' : 'ar',
      reduceMotion: reduceMotion ?? false,
      useArabicDigits: useArabicDigits ?? true,
      crashReportsEnabled: crashReportsEnabled ?? false,
      startupBehavior: StartupBehavior.values.firstWhere(
        (item) => item.name == startup,
        orElse: () => StartupBehavior.lastTab,
      ),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await Future.wait([
      _preferences.setString(_themeKey, settings.theme.name),
      _preferences.setString(_localeKey, settings.localeCode),
      _preferences.setBool(_reduceMotionKey, settings.reduceMotion),
      _preferences.setBool(_arabicDigitsKey, settings.useArabicDigits),
      _preferences.setBool(_crashReportsKey, settings.crashReportsEnabled),
      _preferences.setString(_startupKey, settings.startupBehavior.name),
    ]);
  }
}
