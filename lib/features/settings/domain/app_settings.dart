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
  });

  final AppThemePreference theme;
  final String localeCode;
  final bool reduceMotion;
  final bool useArabicDigits;
  final bool crashReportsEnabled;

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
  }) => AppSettings(
    theme: theme ?? this.theme,
    localeCode: localeCode ?? this.localeCode,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    useArabicDigits: useArabicDigits ?? this.useArabicDigits,
    crashReportsEnabled: crashReportsEnabled ?? this.crashReportsEnabled,
  );
}

/// User-selectable color treatments.
enum AppThemePreference { system, light, dark, sepia }
