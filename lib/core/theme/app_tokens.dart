import 'package:flutter/widgets.dart';

/// Shared design tokens. Every themed surface, field, and sheet reads these so
/// the whole app keeps one radius, spacing, and size rhythm.
abstract final class AppTokens {
  /// Font family for Quran text: Amiri Quran (SIL OFL 1.1), bundled in
  /// `assets/fonts/amiri_quran`. See `docs/QURAN_SOURCES.md`.
  static const String quranFontFamily = 'AmiriQuran';

  /// Corner radius of fields, buttons, and list rows.
  static const double radiusField = 16;

  /// Corner radius of cards and glass panels.
  static const double radiusCard = 24;

  /// Corner radius of bottom sheets.
  static const double radiusSheet = 28;

  /// Corner radius of the floating iOS sheet.
  static const double radiusSheetFloating = 38;

  /// Gap between a floating iOS sheet and the screen edges.
  static const double sheetInset = 8;

  /// Minimum touch target height.
  static const double minTarget = 48;

  /// Inner padding of a filled field.
  static const EdgeInsetsDirectional fieldPadding =
      EdgeInsetsDirectional.symmetric(horizontal: 18, vertical: 14);

  /// Page gutter on compact widths.
  static const double gutterCompact = 16;

  /// Page gutter on medium and expanded widths.
  static const double gutterWide = 24;

  /// Height of the floating glass app bar, excluding the status bar.
  static const double appBarHeight = 44;

  /// Space reserved below scrollable content for the floating glass bar.
  static const double barClearance = 96;
}
