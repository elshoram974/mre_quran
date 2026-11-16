import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Persisted choices that affect the whole application.
@immutable
class AppSettings {
  const AppSettings({
    this.theme = AppThemePreference.sepia,
    this.accent = AppAccent.gold,
    this.localeCode = 'ar',
    this.reduceMotion = false,
    this.hapticsEnabled = true,
    this.useArabicDigits = true,
    this.crashReportsEnabled = false,
    this.startupBehavior = StartupBehavior.lastTab,
    this.readerFontScale = 1,
    this.realisticPageTurn = false,
    this.readerMode = ReaderMode.printed,
    this.readerPageLayout = ReaderPageLayout.auto,
    this.mushafEdition = MushafEdition.hafs,
  });

  /// The reading (riwaya) whose printed pages the reader shows.
  final MushafEdition mushafEdition;

  /// The page theme (paper colour) of the app and the Mushaf.
  final AppThemePreference theme;

  /// The accent: ayah numbers, highlights, and buttons.
  final AppAccent accent;
  final String localeCode;
  final bool reduceMotion;

  /// Whether the app vibrates for counts and finished steps.
  final bool hapticsEnabled;
  final bool useArabicDigits;
  final bool crashReportsEnabled;

  /// Which tab the app opens on.
  final StartupBehavior startupBehavior;

  /// Smallest [readerFontScale].
  static const double minReaderFontScale = 0.8;

  /// Largest [readerFontScale].
  static const double maxReaderFontScale = 1.6;

  /// Size of Mushaf text relative to the default, between
  /// [minReaderFontScale] and [maxReaderFontScale].
  final double readerFontScale;

  /// Whether Mushaf pages bend and turn like paper instead of sliding.
  final bool realisticPageTurn;

  /// Whether the Mushaf shows typeset text or printed page images.
  final ReaderMode readerMode;

  /// How the printed Mushaf uses the available reading area.
  final ReaderPageLayout readerPageLayout;

  Locale get locale => Locale(localeCode);

  /// Whether the app follows the system, or keeps the paper's brightness.
  ThemeMode get materialThemeMode => switch (theme) {
    AppThemePreference.system => ThemeMode.system,
    _ when theme.dayPaper.brightness == Brightness.dark => ThemeMode.dark,
    _ => ThemeMode.light,
  };

  AppSettings copyWith({
    AppThemePreference? theme,
    AppAccent? accent,
    String? localeCode,
    bool? reduceMotion,
    bool? hapticsEnabled,
    bool? useArabicDigits,
    bool? crashReportsEnabled,
    StartupBehavior? startupBehavior,
    double? readerFontScale,
    bool? realisticPageTurn,
    ReaderMode? readerMode,
    ReaderPageLayout? readerPageLayout,
    MushafEdition? mushafEdition,
  }) => AppSettings(
    theme: theme ?? this.theme,
    accent: accent ?? this.accent,
    localeCode: localeCode ?? this.localeCode,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    useArabicDigits: useArabicDigits ?? this.useArabicDigits,
    crashReportsEnabled: crashReportsEnabled ?? this.crashReportsEnabled,
    startupBehavior: startupBehavior ?? this.startupBehavior,
    readerFontScale: readerFontScale ?? this.readerFontScale,
    realisticPageTurn: realisticPageTurn ?? this.realisticPageTurn,
    readerMode: readerMode ?? this.readerMode,
    readerPageLayout: readerPageLayout ?? this.readerPageLayout,
    mushafEdition: mushafEdition ?? this.mushafEdition,
  );
}

/// User-selectable color treatments.
enum AppThemePreference {
  /// Cream by day and navy by night, following the system.
  system(AppPaper.cream, AppPaper.navy),

  /// Warm cream paper.
  light(AppPaper.cream, AppPaper.cream),

  /// Plain white paper.
  white(AppPaper.white, AppPaper.white),

  /// Low-glare sepia paper.
  sepia(AppPaper.sepia, AppPaper.sepia),

  /// Soft green paper.
  green(AppPaper.green, AppPaper.green),

  /// Deep navy paper.
  dark(AppPaper.navy, AppPaper.navy),

  /// True black paper.
  black(AppPaper.black, AppPaper.black);

  const AppThemePreference(this.dayPaper, this.nightPaper);

  /// The paper while the system is light (or always, unless [system]).
  final AppPaper dayPaper;

  /// The paper while the system is dark; only differs for [system].
  final AppPaper nightPaper;
}

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

/// A reading (riwaya) of the Quran whose printed Mushaf the app can show.
///
/// All five are the King Fahd Complex's own Mushafs, with the same 604 pages
/// and every surah starting on the same page. The wording differs between
/// readings, and three of them number some ayahs differently.
enum MushafEdition {
  /// Hafs from Asim: the reading of the app's text, search and tafsir.
  hafs('hafs-kfqc'),

  /// Shu'bah from Asim.
  shubah('shubah-kfqc'),

  /// Warsh from Nafi'.
  warsh('warsh-kfqc'),

  /// Qalun from Nafi'.
  qalon('qalon-kfqc'),

  /// Al-Duri from Abu Amr.
  douri('douri-kfqc');

  const MushafEdition(this.id);

  /// The edition's name in its source, its folder on the device, and the
  /// value saved in the settings.
  final String id;

  /// Whether the app's own text matches these pages word for word and ayah
  /// for ayah. Only then may a page's ayah be copied, explained, bookmarked
  /// or highlighted from the app's text, and the text stand in for a page.
  bool get matchesAppText => this == MushafEdition.hafs;

  /// Whether this edition's pages have their lines spread to fill a tall
  /// screen. Only an edition whose files draw the script line by line on
  /// nearly every page does; the others are shown at their printed height
  /// throughout, so that neighbouring pages never differ. The check that
  /// decides this is `tool/check_svg_lines.dart`.
  bool get spreadsLines => this == MushafEdition.hafs;
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
