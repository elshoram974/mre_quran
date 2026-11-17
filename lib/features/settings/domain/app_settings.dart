import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_palette.dart';
import '../../mushaf/domain/mushaf_edition.dart';

export '../../mushaf/domain/mushaf_edition.dart';

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
    this.mushafEdition = MushafEditions.hafs,
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

/// The arrangement of pages in the printed Mushaf reader.
enum ReaderPageLayout {
  /// One page on compact widths and a two-page spread where it fits.
  auto,

  /// A full-width page that can scroll vertically when needed.
  single,

  /// Two facing pages when the reading area is wide enough.
  spread,
}
