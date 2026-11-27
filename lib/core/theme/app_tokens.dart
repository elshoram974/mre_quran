import 'package:flutter/widgets.dart';

/// Shared design tokens. Every themed surface, field, and sheet reads these so
/// the whole app keeps one radius, spacing, and size rhythm.
abstract final class AppTokens {
  /// Font family for Quran text: Amiri Quran (SIL OFL 1.1), bundled in
  /// `assets/fonts/amiri_quran`. See `docs/QURAN_SOURCES.md`.
  static const String quranFontFamily = 'AmiriQuran';

  /// Font family for the Mushaf reader: KFGQPC Uthmanic Script Hafs, bundled
  /// in `assets/fonts/kfgqpc_hafs`. It draws the King Fahd Complex text and
  /// its ayah-number glyphs. See `docs/QURAN_SOURCES.md`.
  static const String mushafFontFamily = 'KfgqpcHafs';

  /// Corner radius of fields, buttons, and list rows.
  static const double radiusField = 16;

  /// Corner radius of cards and glass panels.
  static const double radiusCard = 24;

  /// Corner radius of a small icon badge.
  static const double radiusBadge = 12;

  /// Side of a small icon badge, as used in list rows.
  static const double badgeSmall = 36;

  /// Side of a standard icon badge, as used in tile cards.
  static const double badgeMedium = 44;

  /// Side of a large icon badge, as used in empty states.
  static const double badgeLarge = 72;

  /// Inner padding of cards that hold free content.
  static const double cardPadding = 16;

  /// Inner padding of hero panels.
  static const double heroPadding = 20;

  /// Text scale from which a row's leading badge moves above its text, so
  /// large text keeps the full width of the row.
  static const double stackTextScale = 1.5;

  /// Duration of state changes on cards (highlight, completion).
  static const Duration motionMedium = Duration(milliseconds: 250);

  /// How quickly a pressed card gives under the finger, and returns.
  static const Duration motionPress = Duration(milliseconds: 120);

  /// The size a pressed card gives to, as a share of its own.
  static const double pressScale = 0.97;

  /// How long a page's centrepiece takes to arrive when the page opens: long
  /// enough for its soft overshoot to be seen.
  static const Duration motionEntrance = Duration(milliseconds: 450);

  /// The size an arriving centrepiece grows from, as a share of its own.
  static const double entranceScale = 0.7;

  /// How much of itself a page shows while what it needs is still loading:
  /// all in place, and plainly not live yet.
  static const double inertOpacity = 0.5;

  /// How long a wait lasts before a bar says the page is loading. A shorter
  /// one shows no loader at all.
  static const Duration loaderDelay = Duration(milliseconds: 150);

  /// Thickness of the loading line on the bottom edge of a Material bar.
  static const double barProgressHeight = 3;

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

  /// Height of the big tap-to-count button on an adhkar card.
  static const double counterButtonHeight = 56;

  /// Page gutter on compact widths.
  static const double gutterCompact = 16;

  /// Page gutter on medium and expanded widths.
  static const double gutterWide = 24;

  /// Small gaps between related controls.
  static const double spaceSmall = 8;

  /// Standard gap between adjacent sections.
  static const double spaceMedium = 12;

  /// Height of the floating glass app bar, excluding the status bar.
  static const double appBarHeight = 44;

  /// Space reserved below scrollable content for the floating glass bar.
  static const double barClearance = 96;

  /// Height of the floating tab bar on Android.
  static const double floatingBarHeight = 68;

  /// Space between the floating tab bar and the bottom of the screen.
  static const double floatingBarGap = 12;

  /// Room above a Mushaf page for its header chips (surah, juz, hizb).
  static const double readerHeaderExtent = 48;

  /// Room below a Mushaf page for its page-number chip.
  static const double readerFooterExtent = 44;

  /// Height of a reader chip.
  static const double readerChipHeight = 32;

  /// Padding at each side of a reader chip's text. In a row too short for
  /// its chips it closes up to [spaceSmall] before any text is cut.
  static const double readerChipPadding = 14;

  /// Side margin of the Mushaf text.
  static const double readerGutter = 12;

  /// Side margin of a printed Mushaf page. The artwork carries its own
  /// margin, so the page runs almost edge to edge, as a printed copy does.
  static const double readerGutterPrinted = 2;

  /// Margin above and below a printed Mushaf page.
  static const double readerEdgePrinted = 4;

  /// The most a printed page's lines are spread to fill a tall screen, as a
  /// multiple of the printed page's height. Past this the lines drift too
  /// far apart to read as a page.
  static const double readerMaxLineSpread = 1.4;

  /// Height of a surah-name frame drawn as a sample in its chooser.
  static const double frameSampleHeight = 30;

  /// Narrowest a frame sample in the chooser may be; as many fit in a row
  /// as the room allows, between two and four.
  static const double frameSampleMinWidth = 132;

  /// A small icon beside a label, and the gap between them.
  static const double iconSmall = 16;
  static const double spaceTiny = 4;

  /// Outline of a chosen option.
  static const double selectedOutline = 2;

  /// The longest the native launch screen stays while the first screen
  /// loads.
  static const Duration launchMost = Duration(seconds: 4);
}
