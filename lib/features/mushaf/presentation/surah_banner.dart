import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../quran_index/domain/quran_metadata.dart';
import 'mushaf_ornaments.dart';

/// The frame of a surah's opening, as printed Mushafs set it: an ornate
/// panel holding the surah's name, with its order and its number of ayahs
/// in the two medallions.
///
/// It fills the box it is given. The printed pages draw the surah's name in
/// their own calligraphy; there the frame goes under it with [showTitle]
/// off, so only the frame and the medallions are drawn.
class SurahBanner extends StatelessWidget {
  /// Creates the banner of [surah].
  const SurahBanner({
    super.key,
    required this.surah,
    required this.number,
    this.showTitle = true,
    this.fill,
    this.stroke,
    this.ink,
  });

  /// The surah.
  final Surah surah;

  /// Formats a number in the reader's digits.
  final String Function(int) number;

  /// Whether the name is written in the middle.
  final bool showTitle;

  /// Colours of the panel, its lines and its writing; from the theme when
  /// not given.
  final Color? fill;
  final Color? stroke;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final writing = ink ?? scheme.onSurface;
    TextStyle quran(double size, {double? opacity}) => TextStyle(
      fontFamily: AppTokens.quranFontFamily,
      fontSize: size,
      height: 1.2,
      color: opacity == null ? writing : writing.withValues(alpha: opacity),
    );
    // A medallion holds a number over its caption.
    Widget medallion(double diameter, String value, String caption) => SizedBox(
      width: diameter,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, textScaler: TextScaler.noScaling, style: quran(17)),
              Text(
                caption,
                textScaler: TextScaler.noScaling,
                style: quran(10, opacity: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
    final revelation = surah.revelation == Revelation.meccan
        ? l10n.revelationMeccan
        : l10n.revelationMedinan;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        // The medallions sit where the painter draws their rings.
        final inset = SurahBannerGeometry.circleInset(width, height);
        final diameter = SurahBannerGeometry.circleDiameter(width, height);
        return CustomPaint(
          painter: SurahBannerPainter(
            fill: fill ?? scheme.secondaryContainer,
            stroke: stroke ?? scheme.primary.withValues(alpha: 0.75),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: inset),
            child: Row(
              children: [
                medallion(
                  diameter,
                  number(surah.number),
                  l10n.surahOrderCaption,
                ),
                Expanded(
                  child: showTitle
                      ? Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.surahTitle(surah.arabicName),
                                  textScaler: TextScaler.noScaling,
                                  style: quran(22),
                                ),
                                Text(
                                  revelation,
                                  textScaler: TextScaler.noScaling,
                                  style: quran(11, opacity: 0.75),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                medallion(
                  diameter,
                  number(surah.ayahCount),
                  l10n.surahAyahsCaption,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
