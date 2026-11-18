import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../settings/domain/app_settings.dart';
import 'mushaf_ornaments.dart';

/// The frame of a surah's opening (see [SurahFramePainter]), with the
/// surah's name in its plaque and, under the name, where it was revealed
/// and how many ayahs it has.
///
/// It fills the box it is given. The printed pages draw the surah's name in
/// their own calligraphy; there the frame goes under it with [showTitle]
/// off, so only the frame is drawn and the page's name sits in the
/// plaque.
class SurahBanner extends StatelessWidget {
  /// Creates the banner of [surah].
  const SurahBanner({
    super.key,
    required this.surah,
    required this.number,
    this.style = SurahFrameStyle.cartouche,
    this.showTitle = true,
    this.nameWidth = 0,
    this.paper,
    this.band,
    this.stroke,
    this.ink,
    this.ayahCount,
    this.fontFamily,
  });

  /// The surah.
  final Surah surah;

  /// Formats a number in the reader's digits.
  final String Function(int) number;

  /// Which frame to draw.
  final SurahFrameStyle style;

  /// Whether the name is written in the frame's plaque.
  final bool showTitle;

  /// Width of a name the page itself prints, which the plaque must hold,
  /// in logical pixels; 0 when the banner writes the name.
  final double nameWidth;

  /// Colours of the cartouche, the panel, the lines and the writing; from
  /// the theme when not given.
  final Color? paper;
  final Color? band;
  final Color? stroke;
  final Color? ink;

  /// How many ayahs the reading shown counts in the surah; the app's own
  /// (Hafs) count when null. Readings count some surahs differently.
  final int? ayahCount;

  /// The font the name is written in: the reading's own script, so a
  /// picture of its ayahs is all in one hand. The app's Quran font when
  /// null.
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final writing = ink ?? scheme.onSurface;
    final lines = stroke ?? scheme.primary.withValues(alpha: 0.8);
    // Line heights leave room for the Quran font's deep descenders, so the
    // caption never runs into the name above it.
    TextStyle quran(
      double size, {
      required double height,
      double? opacity,
      String family = AppTokens.quranFontFamily,
    }) => TextStyle(
      fontFamily: family,
      fontSize: size,
      height: height,
      color: opacity == null ? writing : writing.withValues(alpha: opacity),
    );
    final count = ayahCount ?? surah.ayahCount;
    final revelation = surah.revelation == Revelation.meccan
        ? l10n.revelationMeccan
        : l10n.revelationMedinan;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final name = SurahFrameGeometry.name(size, style);
        return CustomPaint(
          painter: SurahFramePainter(
            style: style,
            nameWidth: nameWidth,
            paper: paper ?? scheme.surface,
            band: band ?? lines.withValues(alpha: 0.1),
            stroke: lines,
          ),
          child: !showTitle
              ? const SizedBox.expand()
              : Center(
                  child: SizedBox(
                    // The plaque's ends are left clear.
                    width: name.width,
                    height: name.height,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.surahTitle(surah.arabicName),
                            textScaler: TextScaler.noScaling,
                            // The caption stays in the app's font: the
                            // Mushaf fonts draw digits as ayah medallions.
                            style: quran(
                              22,
                              height: 1.6,
                              family: fontFamily ?? AppTokens.quranFontFamily,
                            ),
                          ),
                          Text(
                            '$revelation · '
                            '${l10n.selectionCount(count, number(count))}',
                            textScaler: TextScaler.noScaling,
                            style: quran(11, height: 1.3, opacity: 0.75),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
