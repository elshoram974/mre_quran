import 'package:material_ui/material_ui.dart';

/// The colours the Mushaf reader paints with: the paper, the ink of the
/// ayahs, the ayah-number marks, and the highlight over a chosen ayah.
///
/// Derived from the theme's paper and accent, so a change of theme or accent
/// re-colours the Mushaf, and `MaterialApp` animates it like the rest of the
/// theme. Read it with [QuranColors.of].
@immutable
class QuranColors extends ThemeExtension<QuranColors> {
  /// Creates a reader palette.
  const QuranColors({
    required this.paper,
    required this.ink,
    required this.ayahNumber,
    required this.ayahNumberFill,
    required this.highlight,
  });

  /// Derives the palette for [scheme]: ink from the paper's text colour, ayah
  /// numbers and highlights from the accent.
  factory QuranColors.from(ColorScheme scheme) => QuranColors(
    paper: scheme.surface,
    ink: scheme.onSurface,
    ayahNumber: scheme.primary,
    ayahNumberFill: scheme.primary.withValues(alpha: 0.12),
    highlight: scheme.primary.withValues(
      alpha: scheme.brightness == Brightness.dark ? 0.28 : 0.18,
    ),
  );

  /// Background of the page.
  final Color paper;

  /// Colour of the Quran text.
  final Color ink;

  /// Colour of the ayah-number ornament and digits.
  final Color ayahNumber;

  /// Soft fill inside the ayah-number ornament.
  final Color ayahNumberFill;

  /// Wash over a selected or playing ayah; translucent, so the ink shows.
  final Color highlight;

  /// The palette of the nearest theme. It is a pure function of the colour
  /// scheme, so a theme built outside `AppTheme` gets the same derivation.
  static QuranColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<QuranColors>() ??
        QuranColors.from(theme.colorScheme);
  }

  @override
  QuranColors copyWith({
    Color? paper,
    Color? ink,
    Color? ayahNumber,
    Color? ayahNumberFill,
    Color? highlight,
  }) => QuranColors(
    paper: paper ?? this.paper,
    ink: ink ?? this.ink,
    ayahNumber: ayahNumber ?? this.ayahNumber,
    ayahNumberFill: ayahNumberFill ?? this.ayahNumberFill,
    highlight: highlight ?? this.highlight,
  );

  @override
  QuranColors lerp(QuranColors? other, double t) {
    if (other == null) return this;
    return QuranColors(
      paper: Color.lerp(paper, other.paper, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ayahNumber: Color.lerp(ayahNumber, other.ayahNumber, t)!,
      ayahNumberFill: Color.lerp(ayahNumberFill, other.ayahNumberFill, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
    );
  }
}
