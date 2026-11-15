import 'package:flutter/material.dart';

/// The page colour of a theme: the paper the whole app, and the Mushaf, sit
/// on, with its ink and surfaces.
enum AppPaper {
  /// Warm cream paper.
  cream(Brightness.light),

  /// Plain white paper.
  white(Brightness.light),

  /// Low-glare reader paper.
  sepia(Brightness.light),

  /// Soft green paper.
  green(Brightness.light),

  /// Deep navy night paper.
  navy(Brightness.dark),

  /// True black, for OLED screens at night.
  black(Brightness.dark);

  const AppPaper(this.brightness);

  /// Whether the paper is light or dark.
  final Brightness brightness;
}

/// The accent colour: ayah numbers, highlights, buttons, and selection.
enum AppAccent {
  /// Gold, the default.
  gold,

  /// Emerald green.
  emerald,

  /// Teal.
  teal,

  /// Blue.
  blue,

  /// Indigo.
  indigo,

  /// Rose.
  rose,

  /// Crimson.
  crimson,

  /// Brown.
  brown,
}

/// Hand-authored colours for every paper and accent.
///
/// This file is the only place a raw colour literal may live. A theme is one
/// paper plus one accent; the accent has one tone for light paper and one for
/// dark, each chosen so its text pairs meet WCAG AA on every paper of that
/// brightness. `test/core/theme/app_palette_test.dart` checks every pair.
abstract final class AppPalette {
  /// The complete scheme for [paper] with [accent].
  static ColorScheme scheme(AppPaper paper, AppAccent accent) {
    final ink = _papers[paper]!;
    final dark = paper.brightness == Brightness.dark;
    final tone = (dark ? _darkAccents : _lightAccents)[accent]!;
    final base = dark ? _darkBase : _lightBase;
    return base.copyWith(
      primary: tone.primary,
      onPrimary: tone.onPrimary,
      primaryContainer: tone.container,
      onPrimaryContainer: tone.onContainer,
      inversePrimary: tone.inverse,
      surface: ink.surface,
      onSurface: ink.onSurface,
      onSurfaceVariant: ink.onSurfaceVariant,
      surfaceContainerLowest: ink.lowest,
      surfaceContainerLow: ink.low,
      surfaceContainer: ink.container,
      surfaceContainerHigh: ink.high,
      surfaceContainerHighest: ink.highest,
      // Neutral selection that takes the paper's own hue.
      secondary: ink.onSurfaceVariant,
      onSecondary: ink.surface,
      secondaryContainer: ink.high,
      onSecondaryContainer: ink.onSurface,
      outline: ink.outline,
      outlineVariant: ink.outlineVariant,
      shadow: ink.shadow,
      inverseSurface: ink.inverseSurface,
      onInverseSurface: ink.surface,
    );
  }

  /// Roles shared by every light paper (tertiary, error, scrim).
  static const ColorScheme _lightBase = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF8A6416),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF615847),
    onSecondary: Color(0xFFFFFFFF),
    tertiary: Color(0xFF3F6A55),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDCEADF),
    onTertiaryContainer: Color(0xFF15301F),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFF6F1E7),
    onSurface: Color(0xFF2A251D),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0x00000000),
  );

  /// Roles shared by every dark paper (tertiary, error, scrim).
  static const ColorScheme _darkBase = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFD9B56A),
    onPrimary: Color(0xFF2B1E00),
    secondary: Color(0xFFA9A493),
    onSecondary: Color(0xFF161B26),
    tertiary: Color(0xFFA8CBB5),
    onTertiary: Color(0xFF13301F),
    tertiaryContainer: Color(0xFF2A3F33),
    onTertiaryContainer: Color(0xFFCDE9D6),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF161B26),
    onSurface: Color(0xFFECE6D9),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0x00000000),
  );

  static const Map<AppPaper, _Paper> _papers = {
    AppPaper.cream: _Paper(
      surface: Color(0xFFF6F1E7),
      onSurface: Color(0xFF2A251D),
      onSurfaceVariant: Color(0xFF615847),
      lowest: Color(0xFFFFFCF6),
      low: Color(0xFFF1EADC),
      container: Color(0xFFECE4D3),
      high: Color(0xFFE7DECB),
      highest: Color(0xFFE1D7C2),
      outline: Color(0xFF8C8270),
      outlineVariant: Color(0xFFE2D9C6),
      shadow: Color(0xFF2A1F0A),
      inverseSurface: Color(0xFF322C22),
    ),
    AppPaper.white: _Paper(
      surface: Color(0xFFFAFAF8),
      onSurface: Color(0xFF1F1F1D),
      onSurfaceVariant: Color(0xFF55554F),
      lowest: Color(0xFFFFFFFF),
      low: Color(0xFFF3F3F0),
      container: Color(0xFFEDEDEA),
      high: Color(0xFFE7E7E3),
      highest: Color(0xFFE1E1DC),
      outline: Color(0xFF7E7E76),
      outlineVariant: Color(0xFFE0E0DA),
      shadow: Color(0xFF1A1A1A),
      inverseSurface: Color(0xFF2F2F2C),
    ),
    AppPaper.sepia: _Paper(
      surface: Color(0xFFF4EBD8),
      onSurface: Color(0xFF2E2416),
      onSurfaceVariant: Color(0xFF5F5240),
      lowest: Color(0xFFFBF5E8),
      low: Color(0xFFEFE4CE),
      container: Color(0xFFEADEC5),
      high: Color(0xFFE5D8BD),
      highest: Color(0xFFDFD1B4),
      outline: Color(0xFF8A7B63),
      outlineVariant: Color(0xFFDDCFB3),
      shadow: Color(0xFF2E2416),
      inverseSurface: Color(0xFF3A3022),
    ),
    AppPaper.green: _Paper(
      surface: Color(0xFFEDF3EA),
      onSurface: Color(0xFF1E2A20),
      onSurfaceVariant: Color(0xFF4E5E51),
      lowest: Color(0xFFF7FBF5),
      low: Color(0xFFE6EEE3),
      container: Color(0xFFE0E9DC),
      high: Color(0xFFDAE4D6),
      highest: Color(0xFFD3DECF),
      outline: Color(0xFF76877A),
      outlineVariant: Color(0xFFD0DCCC),
      shadow: Color(0xFF13261A),
      inverseSurface: Color(0xFF2A352C),
    ),
    AppPaper.navy: _Paper(
      surface: Color(0xFF161B26),
      onSurface: Color(0xFFECE6D9),
      onSurfaceVariant: Color(0xFFA9A493),
      lowest: Color(0xFF11151E),
      low: Color(0xFF1C2230),
      container: Color(0xFF212838),
      high: Color(0xFF272F40),
      highest: Color(0xFF2E3749),
      outline: Color(0xFF7E8494),
      outlineVariant: Color(0xFF343C4E),
      shadow: Color(0xFF000000),
      inverseSurface: Color(0xFFECE6D9),
    ),
    AppPaper.black: _Paper(
      surface: Color(0xFF000000),
      onSurface: Color(0xFFE8E4DA),
      onSurfaceVariant: Color(0xFFA3A097),
      lowest: Color(0xFF000000),
      low: Color(0xFF121212),
      container: Color(0xFF181818),
      high: Color(0xFF1F1F1F),
      highest: Color(0xFF272727),
      outline: Color(0xFF7A776F),
      outlineVariant: Color(0xFF2E2E2E),
      shadow: Color(0xFF000000),
      inverseSurface: Color(0xFFE8E4DA),
    ),
  };

  static const Map<AppAccent, _Tone> _lightAccents = {
    AppAccent.gold: _Tone(
      primary: Color(0xFF8A6416),
      onPrimary: Color(0xFFFFFFFF),
      container: Color(0xFFF2E3BD),
      onContainer: Color(0xFF3D2C05),
      inverse: Color(0xFFE3C27A),
    ),
    AppAccent.emerald: _Tone(
      primary: Color(0xFF1F6B4A),
      onPrimary: Color(0xFFFFFFFF),
      container: Color(0xFFC9E8D5),
      onContainer: Color(0xFF0B2E1E),
      inverse: Color(0xFF8ED3AE),
    ),
    AppAccent.teal: _Tone(
      primary: Color(0xFF1B6670),
      onPrimary: Color(0xFFFFFFFF),
      container: Color(0xFFC4E5EA),
      onContainer: Color(0xFF06292E),
      inverse: Color(0xFF86CFD9),
    ),
    AppAccent.blue: _Tone(
      primary: Color(0xFF2858A8),
      onPrimary: Color(0xFFFFFFFF),
      container: Color(0xFFD6E2F7),
      onContainer: Color(0xFF0E2550),
      inverse: Color(0xFFA9C4F2),
    ),
    AppAccent.indigo: _Tone(
      primary: Color(0xFF4B45A6),
      onPrimary: Color(0xFFFFFFFF),
      container: Color(0xFFE0DEF7),
      onContainer: Color(0xFF1D1950),
      inverse: Color(0xFFBEB9F2),
    ),
    AppAccent.rose: _Tone(
      primary: Color(0xFFA23A6A),
      onPrimary: Color(0xFFFFFFFF),
      container: Color(0xFFF6D9E5),
      onContainer: Color(0xFF46102A),
      inverse: Color(0xFFF0A9C8),
    ),
    AppAccent.crimson: _Tone(
      primary: Color(0xFFA8322E),
      onPrimary: Color(0xFFFFFFFF),
      container: Color(0xFFF7DAD7),
      onContainer: Color(0xFF4A0F0C),
      inverse: Color(0xFFF2AAA4),
    ),
    AppAccent.brown: _Tone(
      primary: Color(0xFF7A5A2E),
      onPrimary: Color(0xFFFFFFFF),
      container: Color(0xFFEAD7B4),
      onContainer: Color(0xFF33230A),
      inverse: Color(0xFFDDBF8C),
    ),
  };

  static const Map<AppAccent, _Tone> _darkAccents = {
    AppAccent.gold: _Tone(
      primary: Color(0xFFD9B56A),
      onPrimary: Color(0xFF2B1E00),
      container: Color(0xFF3B3220),
      onContainer: Color(0xFFF3DFAF),
      inverse: Color(0xFF8A6416),
    ),
    AppAccent.emerald: _Tone(
      primary: Color(0xFF7DD3A6),
      onPrimary: Color(0xFF00391F),
      container: Color(0xFF1D3A2C),
      onContainer: Color(0xFFBFF0D4),
      inverse: Color(0xFF1F6B4A),
    ),
    AppAccent.teal: _Tone(
      primary: Color(0xFF7CCFDA),
      onPrimary: Color(0xFF00363D),
      container: Color(0xFF1A3A40),
      onContainer: Color(0xFFC0EEF4),
      inverse: Color(0xFF1B6670),
    ),
    AppAccent.blue: _Tone(
      primary: Color(0xFF9DBEF5),
      onPrimary: Color(0xFF0A2A5C),
      container: Color(0xFF22345A),
      onContainer: Color(0xFFD8E4FB),
      inverse: Color(0xFF2858A8),
    ),
    AppAccent.indigo: _Tone(
      primary: Color(0xFFB7B2F5),
      onPrimary: Color(0xFF231E63),
      container: Color(0xFF2E2B55),
      onContainer: Color(0xFFE2E0FC),
      inverse: Color(0xFF4B45A6),
    ),
    AppAccent.rose: _Tone(
      primary: Color(0xFFF2A8C8),
      onPrimary: Color(0xFF4F1530),
      container: Color(0xFF4A2236),
      onContainer: Color(0xFFFBDCE9),
      inverse: Color(0xFFA23A6A),
    ),
    AppAccent.crimson: _Tone(
      primary: Color(0xFFF2AAA4),
      onPrimary: Color(0xFF561410),
      container: Color(0xFF4D2220),
      onContainer: Color(0xFFFBDCD9),
      inverse: Color(0xFFA8322E),
    ),
    AppAccent.brown: _Tone(
      primary: Color(0xFFDDBF8C),
      onPrimary: Color(0xFF3A2A0E),
      container: Color(0xFF3E3222),
      onContainer: Color(0xFFF3E3C6),
      inverse: Color(0xFF7A5A2E),
    ),
  };
}

/// The ink and surfaces of one paper.
@immutable
class _Paper {
  const _Paper({
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.lowest,
    required this.low,
    required this.container,
    required this.high,
    required this.highest,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.inverseSurface,
  });

  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color lowest;
  final Color low;
  final Color container;
  final Color high;
  final Color highest;
  final Color outline;
  final Color outlineVariant;
  final Color shadow;
  final Color inverseSurface;
}

/// One accent at one brightness.
@immutable
class _Tone {
  const _Tone({
    required this.primary,
    required this.onPrimary,
    required this.container,
    required this.onContainer,
    required this.inverse,
  });

  final Color primary;
  final Color onPrimary;
  final Color container;
  final Color onContainer;
  final Color inverse;
}
