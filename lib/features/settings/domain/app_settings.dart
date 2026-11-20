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
    this.crashReportsEnabled = true,
    this.startupBehavior = StartupBehavior.reader,
    this.readerFontScale = 1,
    this.adhkarFontScale = 1,
    this.realisticPageTurn = false,
    this.readerMode = ReaderMode.printed,
    this.readerPageLayout = ReaderPageLayout.auto,
    this.mushafEdition = MushafEditions.hafs,
    this.surahFrame = SurahFrameStyle.cartouche,
    this.widgetSeconds = false,
    this.widgetLocaleCode = 'app',
  });

  /// The language the home-screen widgets speak: `ar`, `en`, or `app` for
  /// the app's own.
  final String widgetLocaleCode;

  /// The language code the widgets use: their own choice, else the app's.
  String get widgetLanguage =>
      widgetLocaleCode == 'ar' || widgetLocaleCode == 'en'
      ? widgetLocaleCode
      : localeCode;

  /// Whether the home-screen prayer widgets count the time left down to the
  /// second. Off by default: a widget that redraws every second uses some
  /// battery while it is on screen. The app's own countdown always shows
  /// seconds.
  final bool widgetSeconds;

  /// The frame drawn around each surah's name in the Mushaf.
  final SurahFrameStyle surahFrame;

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

  /// Size of the words of the adhkar relative to the default, between the
  /// same bounds as [readerFontScale].
  final double adhkarFontScale;

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
    double? adhkarFontScale,
    bool? realisticPageTurn,
    ReaderMode? readerMode,
    ReaderPageLayout? readerPageLayout,
    MushafEdition? mushafEdition,
    SurahFrameStyle? surahFrame,
    bool? widgetSeconds,
    String? widgetLocaleCode,
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
    adhkarFontScale: adhkarFontScale ?? this.adhkarFontScale,
    realisticPageTurn: realisticPageTurn ?? this.realisticPageTurn,
    readerMode: readerMode ?? this.readerMode,
    readerPageLayout: readerPageLayout ?? this.readerPageLayout,
    mushafEdition: mushafEdition ?? this.mushafEdition,
    surahFrame: surahFrame ?? this.surahFrame,
    widgetSeconds: widgetSeconds ?? this.widgetSeconds,
    widgetLocaleCode: widgetLocaleCode ?? this.widgetLocaleCode,
  );
}

/// The frames the Mushaf can draw around a surah's name. Each is the app's
/// own design, after the ways printed Mushafs frame their surah titles.
enum SurahFrameStyle {
  /// A panel of small stars with a rosette at each end, around a cartouche
  /// with pointed ends.
  cartouche,

  /// A ruled panel with a chain of lozenges, around a plaque with cut
  /// corners.
  classic,

  /// A rounded panel with leaves, around a plaque with scalloped ends.
  arch,

  /// Two fine rules and a rounded plaque, with no panel.
  minimal,
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
  /// Always open the Mushaf tab. What the app does until the person chooses
  /// otherwise.
  reader,

  /// Reopen the tab the reader left from.
  lastTab,
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
