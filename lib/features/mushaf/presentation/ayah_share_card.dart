import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/quran_colors.dart';
import '../../quran_text/domain/ayah_span.dart';
import '../../quran_text/domain/quran_text.dart';
import 'surah_banner.dart';

/// Ayahs set as a card to share as a picture: the surah's name in its
/// frame, the ayahs one under another in the Mushaf's own script with their
/// numbers, and below them where they are found.
///
/// It is drawn at [width] logical pixels whatever the screen, so the picture
/// comes out the same everywhere.
class AyahShareCard extends StatelessWidget {
  /// Creates the card of [span].
  const AyahShareCard({
    super.key,
    required this.text,
    required this.span,
    required this.digits,
    this.width = 360,
  });

  /// The verified text.
  final QuranText text;

  /// The ayahs shown.
  final AyahSpan span;

  /// Formats a number in the reader's digits.
  final String Function(int) digits;

  /// Width of the card, in logical pixels.
  final double width;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = QuranColors.of(context);
    final surah = text.metadata.surah(span.surah);
    final pages = AyahShareText.pages(text, span);
    final family = text.hasMushafScript
        ? AppTokens.mushafFontFamily
        : AppTokens.quranFontFamily;
    final verse = TextStyle(
      fontFamily: family,
      fontSize: 22,
      height: 1.9,
      color: colors.ink,
    );
    final caption = theme.textTheme.labelMedium?.copyWith(
      color: colors.ink.withValues(alpha: 0.7),
    );
    final page = pages.first == pages.last
        ? l10n.pageNumber(digits(pages.first))
        : l10n.pageRange(digits(pages.first), digits(pages.last));
    final ayahs = span.length == 1
        ? digits(span.first)
        : l10n.ayahRange(digits(span.first), digits(span.last));

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
              SizedBox(
                height: 56,
                child: SurahBanner(
                  surah: surah,
                  number: digits,
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
                    for (final ref in span.refs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: text.mushaf(ref)),
                              // The Mushaf font's own ayah-number ornament,
                              // or the number in brackets without it.
                              TextSpan(
                                text: switch (text.mark(ref)) {
                                  final String mark => ' $mark',
                                  null => ' ﴿${digits(ref.ayah)}﴾',
                                },
                                style: TextStyle(color: colors.ayahNumber),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.noScaling,
                          style: verse,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: colors.ayahNumber.withValues(alpha: 0.35)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.surahTitle(surah.arabicName)} · '
                      '${l10n.ayahNumber(ayahs)}',
                      textScaler: TextScaler.noScaling,
                      style: caption,
                    ),
                  ),
                  Text(page, textScaler: TextScaler.noScaling, style: caption),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.appTitle,
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
