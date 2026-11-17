import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../quran_index/domain/quran_metadata.dart';
import 'mushaf_ornaments.dart';

/// The frame of a surah's opening (see [SurahFramePainter]), with the
/// surah's name in its cartouche and, under the name, where it was revealed
/// and how many ayahs it has.
///
/// It fills the box it is given. The printed pages draw the surah's name in
/// their own calligraphy; there the frame goes under it with [showTitle]
/// off, so only the frame is drawn and the page's name sits in the
/// cartouche.
class SurahBanner extends StatelessWidget {
  /// Creates the banner of [surah].
  const SurahBanner({
    super.key,
    required this.surah,
    required this.number,
    this.showTitle = true,
    this.paper,
    this.band,
    this.stroke,
    this.ink,
  });

  /// The surah.
  final Surah surah;

  /// Formats a number in the reader's digits.
  final String Function(int) number;

  /// Whether the name is written in the cartouche.
  final bool showTitle;

  /// Colours of the cartouche, the panel, the lines and the writing; from
  /// the theme when not given.
  final Color? paper;
  final Color? band;
  final Color? stroke;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final writing = ink ?? scheme.onSurface;
    final lines = stroke ?? scheme.primary.withValues(alpha: 0.8);
    // Line heights leave room for the Quran font's deep descenders, so the
    // caption never runs into the name above it.
    TextStyle quran(double size, {required double height, double? opacity}) =>
        TextStyle(
          fontFamily: AppTokens.quranFontFamily,
          fontSize: size,
          height: height,
          color: opacity == null ? writing : writing.withValues(alpha: opacity),
        );
    final revelation = surah.revelation == Revelation.meccan
        ? l10n.revelationMeccan
        : l10n.revelationMedinan;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final cartouche = SurahFrameGeometry.cartouche(size);
        return CustomPaint(
          painter: SurahFramePainter(
            paper: paper ?? scheme.surface,
            band: band ?? lines.withValues(alpha: 0.1),
            stroke: lines,
          ),
          child: !showTitle
              ? const SizedBox.expand()
              : Center(
                  child: SizedBox(
                    // The pointed ends are left clear.
                    width: cartouche.width - cartouche.height * 1.1,
                    height: cartouche.height * 0.9,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.surahTitle(surah.arabicName),
                            textScaler: TextScaler.noScaling,
                            style: quran(22, height: 1.6),
                          ),
                          Text(
                            '$revelation · '
                            '${number(surah.ayahCount)} '
                            '${l10n.surahAyahsCaption}',
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
