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
    this.readerPageLayout = ReaderPageLayout.auto,
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

  /// How the printed Mushaf uses the available reading area.
  final ReaderPageLayout readerPageLayout;

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
    ReaderPageLayout? readerPageLayout,
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
    readerPageLayout: readerPageLayout ?? this.readerPageLayout,
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

/// The arrangement of pages in the printed Mushaf reader.
enum ReaderPageLayout {
  /// One page on compact widths and a two-page spread where it fits.
  auto,

  /// A full-width page that can scroll vertically when needed.
  single,

  /// Two facing pages when the reading area is wide enough.
  spread,
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
