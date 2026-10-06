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
  static const _readerFontScaleKey = 'settings.reader_font_scale';
  static const _realisticTurnKey = 'settings.realistic_page_turn';
  static const _readerModeKey = 'settings.reader_mode';
  static const _mushafStyleKey = 'settings.mushaf_style';

  @override
  Future<AppSettings> load() async {
    final (
      theme,
      locale,
      reduceMotion,
      useArabicDigits,
      crashReports,
      startup,
      fontScale,
      realisticTurn,
      readerMode,
    ) = await (
      _preferences.getString(_themeKey),
      _preferences.getString(_localeKey),
      _preferences.getBool(_reduceMotionKey),
      _preferences.getBool(_arabicDigitsKey),
      _preferences.getBool(_crashReportsKey),
      _preferences.getString(_startupKey),
      _preferences.getDouble(_readerFontScaleKey),
      _preferences.getBool(_realisticTurnKey),
      _preferences.getString(_readerModeKey),
    ).wait;
    final mushafStyle = await _preferences.getString(_mushafStyleKey);
    return AppSettings(
      theme: AppThemePreference.values.firstWhere(
        (item) => item.name == theme,
        orElse: () => AppThemePreference.sepia,
      ),
      localeCode: locale == 'en' ? 'en' : 'ar',
      reduceMotion: reduceMotion ?? false,
      useArabicDigits: useArabicDigits ?? true,
      crashReportsEnabled: crashReports ?? false,
      startupBehavior: StartupBehavior.values.firstWhere(
        (item) => item.name == startup,
        orElse: () => StartupBehavior.lastTab,
      ),
      readerFontScale: (fontScale ?? 1).clamp(0.8, 1.6).toDouble(),
      realisticPageTurn: realisticTurn ?? true,
      readerMode: ReaderMode.values.firstWhere(
        (item) => item.name == readerMode,
        orElse: () => ReaderMode.text,
      ),
      mushafStyle: MushafStyle.values.firstWhere(
        (item) => item.name == mushafStyle,
        orElse: () => MushafStyle.madinah,
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
      _preferences.setDouble(_readerFontScaleKey, settings.readerFontScale),
      _preferences.setBool(_realisticTurnKey, settings.realisticPageTurn),
      _preferences.setString(_readerModeKey, settings.readerMode.name),
      _preferences.setString(_mushafStyleKey, settings.mushafStyle.name),
    ]);
  }
}
