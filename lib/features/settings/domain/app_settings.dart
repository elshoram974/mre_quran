import 'package:flutter/material.dart';

/// Persisted choices that affect the whole application.
@immutable
class AppSettings {
  const AppSettings({
    this.theme = AppThemePreference.sepia,
    this.localeCode = 'ar',
    this.reduceMotion = false,
    this.useArabicDigits = true,
    this.crashReportsEnabled = false,
    this.startupBehavior = StartupBehavior.lastTab,
    this.readerFontScale = 1,
    this.realisticPageTurn = false,
    this.readerMode = ReaderMode.printed,
    this.mushafStyle = MushafStyle.madinah,
    this.editionsIntroSeen = false,
  });

  final AppThemePreference theme;
  final String localeCode;
  final bool reduceMotion;
  final bool useArabicDigits;
  final bool crashReportsEnabled;

  /// Which tab the app opens on.
  final StartupBehavior startupBehavior;

  /// Size of Mushaf text relative to the default, 0.8 to 1.6.
  final double readerFontScale;

  /// Whether Mushaf pages bend and turn like paper instead of sliding.
  final bool realisticPageTurn;

  /// Whether the Mushaf shows typeset text or printed page images.
  final ReaderMode readerMode;

  /// Which printed edition the printed reader shows.
  final MushafStyle mushafStyle;

  /// Whether the person has been told about the other Mushaf editions.
  final bool editionsIntroSeen;

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
    double? readerFontScale,
    bool? realisticPageTurn,
    ReaderMode? readerMode,
    MushafStyle? mushafStyle,
    bool? editionsIntroSeen,
  }) => AppSettings(
    theme: theme ?? this.theme,
    localeCode: localeCode ?? this.localeCode,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    useArabicDigits: useArabicDigits ?? this.useArabicDigits,
    crashReportsEnabled: crashReportsEnabled ?? this.crashReportsEnabled,
    startupBehavior: startupBehavior ?? this.startupBehavior,
    readerFontScale: readerFontScale ?? this.readerFontScale,
    realisticPageTurn: realisticPageTurn ?? this.realisticPageTurn,
    readerMode: readerMode ?? this.readerMode,
    mushafStyle: mushafStyle ?? this.mushafStyle,
    editionsIntroSeen: editionsIntroSeen ?? this.editionsIntroSeen,
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

/// How the Mushaf pages are shown.
enum ReaderMode {
  /// Verified text typeset on the device; works offline from the start.
  text,

  /// Images of the printed Madinah Mushaf, downloaded page by page.
  printed,
}

/// Printed Mushaf editions the printed reader can show.
enum MushafStyle {
  /// Madinah Mushaf pages as used by the Quran.com apps, with exact ayah
  /// positions.
  madinah,

  /// Madinah Mushaf with tajweed colours.
  tajweed,

  /// Madinah Mushaf rendered from the KFGQPC V4 fonts at high resolution.
  madinahHd,
}
