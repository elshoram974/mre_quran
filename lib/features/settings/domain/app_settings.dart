import 'package:flutter/material.dart';

/// Persisted choices that affect the whole application.
@immutable
class AppSettings {
  const AppSettings({
    this.theme = AppThemePreference.system,
    this.localeCode = 'ar',
    this.reduceMotion = false,
    this.useArabicDigits = true,
    this.crashReportsEnabled = false,
    this.startupBehavior = StartupBehavior.lastTab,
  });

  final AppThemePreference theme;
  final String localeCode;
  final bool reduceMotion;
  final bool useArabicDigits;
  final bool crashReportsEnabled;

  /// Which tab the app opens on.
  final StartupBehavior startupBehavior;

  Locale get locale => Locale(localeCode);

  ThemeMode get materialThemeMode => switch (theme) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light || AppThemePreference.sepia => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  AppSettings copyWith({
    AppThemePreference? theme,
    String? localeCode,
    bool? reduceMotion,
    bool? useArabicDigits,
    bool? crashReportsEnabled,
    StartupBehavior? startupBehavior,
  }) => AppSettings(
    theme: theme ?? this.theme,
    localeCode: localeCode ?? this.localeCode,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    useArabicDigits: useArabicDigits ?? this.useArabicDigits,
    crashReportsEnabled: crashReportsEnabled ?? this.crashReportsEnabled,
    startupBehavior: startupBehavior ?? this.startupBehavior,
  );
}

/// User-selectable color treatments.
enum AppThemePreference { system, light, dark, sepia }

/// Which tab the app opens on.
enum StartupBehavior {
  /// Reopen the tab the reader left from.
  lastTab,

  /// Always open the Mushaf tab.
  reader,
}
