import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/quran_colors.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/domain/ayah_range.dart';
import '../../quran_text/domain/ayah_share_text.dart';
import '../../quran_text/domain/ayah_texts.dart';
import 'ayah_share_format.dart';
import 'surah_banner.dart';
import '../../settings/domain/app_settings.dart';

/// Ayahs set as a card to share as a picture: each surah's name in its
/// frame, its ayahs one under another in the Mushaf's own script with their
/// numbers, and below them where they are found.
///
/// It is drawn at [width] logical pixels whatever the screen, so the picture
/// comes out the same everywhere. A long choice is cut into several cards;
/// [part] and [parts] then say which this is.
class AyahShareCard extends StatelessWidget {
  /// Creates the card of [refs], ayahs in Quran order.
  const AyahShareCard({
    super.key,
    required this.text,
    required this.refs,
    required this.digits,
    this.frame = SurahFrameStyle.cartouche,
    this.width = 360,
    this.part = 1,
    this.parts = 1,
  });

  /// The frame drawn around the surah's name.
  final SurahFrameStyle frame;

  /// The reading's text.
  final AyahTexts text;

  /// The ayahs shown, in order.
  final List<AyahRef> refs;

  /// Formats a number in the reader's digits.
  final String Function(int) digits;

  /// Width of the card, in logical pixels.
  final double width;

  /// Which card of the choice this is, from 1, of [parts].
  final int part;

  /// How many cards the choice takes.
  final int parts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = QuranColors.of(context);
    final runs = AyahOrder.of(text).runs(AyahRange(refs.first, refs.last));
    final verse = TextStyle(
      fontFamily: text.fontFamily,
      fontSize: 22,
      height: 1.9,
      color: colors.ink,
    );
    final caption = theme.textTheme.labelMedium?.copyWith(
      color: colors.ink.withValues(alpha: 0.7),
    );
    final first = runs.first;
    final last = runs.last;
    final place = runs.length == 1
        ? '${l10n.surahTitle(text.metadata.surah(first.surah).arabicName)} · '
              '${l10n.ayahNumber(runAyahs(context, first, digits))}'
        : rangePlace(context, text, AyahRange(refs.first, refs.last), digits);
    final pages = (
      first: AyahShareText.pages(text, first).first,
      last: AyahShareText.pages(text, last).last,
    );
    final page = pages.first == pages.last
        ? l10n.pageNumber(digits(pages.first))
        : l10n.pageRange(digits(pages.first), digits(pages.last));

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.paper,
          border: Border.all(color: colors.ayahNumber.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final run in runs) ...[
                if (run != first) const SizedBox(height: 10),
                SizedBox(
                  // Room for the name and, under it, the surah's count.
                  height: 64,
                  child: SurahBanner(
                    surah: text.metadata.surah(run.surah),
                    // The reading's own count and script.
                    ayahCount: text.ayahCount(run.surah),
                    fontFamily: text.fontFamily,
                    number: digits,
                    style: frame,
                    ink: colors.ink,
                    paper: colors.paper,
                    band: colors.ayahNumber.withValues(alpha: 0.12),
                    stroke: colors.ayahNumber.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 14),
                // The Quran reads right to left in every app language.
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // From its first ayah, a surah opens with its basmala.
                      if (run.first == 1)
                        if (text.basmalaDisplay(run.surah) case final basmala?)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              bottom: 6,
                            ),
                            child: Text(
                              basmala,
                              textAlign: TextAlign.center,
                              textScaler: TextScaler.noScaling,
                              style: verse.copyWith(fontSize: 19),
                            ),
                          ),
                      _Verses(
                        text: text,
                        run: run,
                        digits: digits,
                        style: verse,
                        markColor: colors.ayahNumber,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Divider(color: colors.ayahNumber.withValues(alpha: 0.35)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      place,
                      textScaler: TextScaler.noScaling,
                      style: caption,
                    ),
                  ),
                  Text(page, textScaler: TextScaler.noScaling, style: caption),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                parts == 1
                    ? l10n.appTitle
                    : '${l10n.appTitle} · '
                          '${l10n.sharePicture(digits(part), digits(parts))}',
                textAlign: TextAlign.center,
                textScaler: TextScaler.noScaling,
                style: caption?.copyWith(
                  color: colors.ayahNumber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ties an ayah's number to its last word: a line never ends on an ayah and
/// starts the next with its number.
const String _joiner = '\u00A0';

/// The ayahs of one surah, flowing one after another as on a Mushaf page,
/// each followed by its number. A passage of several lines is justified, so
/// both edges are straight; one short line is centred instead.
class _Verses extends StatelessWidget {
  const _Verses({
    required this.text,
    required this.run,
    required this.digits,
    required this.style,
    required this.markColor,
  });

  final AyahTexts text;
  final SurahRun run;
  final String Function(int) digits;
  final TextStyle style;
  final Color markColor;

  @override
  Widget build(BuildContext context) {
    final span = TextSpan(
      style: style,
      children: [
        for (var ayah = run.first; ayah <= run.last; ayah++) ...[
          TextSpan(text: text.display(AyahRef(run.surah, ayah))),
          // The Mushaf font's own ayah-number ornament, or the number in
          // brackets without it.
          TextSpan(
            text: switch (text.mark(AyahRef(run.surah, ayah))) {
              final String mark => '$_joiner$mark',
              null => '$_joiner﴿${digits(ayah)}﴾',
            },
            style: TextStyle(color: markColor),
          ),
          if (ayah < run.last) const TextSpan(text: ' '),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: span,
            textDirection: TextDirection.rtl,
            textScaler: TextScaler.noScaling,
          )..layout(maxWidth: constraints.maxWidth);
          final oneLine = painter.computeLineMetrics().length == 1;
          painter.dispose();
          return Text.rich(
            span,
            textAlign: oneLine ? TextAlign.center : TextAlign.justify,
            textScaler: TextScaler.noScaling,
          );
        },
      ),
    );
  }
}
