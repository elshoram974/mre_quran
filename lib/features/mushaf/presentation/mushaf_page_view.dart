import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../quran_text/domain/quran_text.dart';
import '../../settings/application/digits_provider.dart';

/// One Mushaf page: header, surah openings, ayahs, and the page number.
///
/// The ayahs on a page follow the Madinah page starts. Line breaks are made by
/// the text layout, not by the printed Mushaf, until layout data is approved.
class MushafPageView extends StatelessWidget {
  /// Creates page [page] of [text].
  const MushafPageView({
    super.key,
    required this.text,
    required this.page,
    required this.fontScale,
    required this.onTap,
  });

  /// The verified text.
  final QuranText text;

  /// Page number, 1–604.
  final int page;

  /// Size of the text relative to the default.
  final double fontScale;

  /// Called when the page is tapped.
  final VoidCallback onTap;

  static const double _baseSize = 22;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final metadata = text.metadata;
    final ayahs = text.pageAyahs(page);
    final quranStyle = TextStyle(
      fontFamily: AppTokens.quranFontFamily,
      fontSize: _baseSize * fontScale,
      height: 2.1,
      color: scheme.onSurface,
    );
    final chromeStyle = theme.textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final blocks = <Widget>[];
    var spans = <InlineSpan>[];
    void flush() {
      if (spans.isEmpty) return;
      blocks.add(
        Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.justify,
          style: quranStyle,
        ),
      );
      spans = <InlineSpan>[];
    }

    for (final ayah in ayahs) {
      if (ayah.ref.ayah == 1) {
        flush();
        blocks.add(
          _SurahHeading(name: metadata.surah(ayah.ref.surah).arabicName),
        );
        if (text.hasBasmala(ayah.ref.surah)) {
          blocks.add(
            Text(text.basmala, textAlign: TextAlign.center, style: quranStyle),
          );
        }
      }
      spans
        ..add(TextSpan(text: '${ayah.text} '))
        ..add(
          TextSpan(
            text: '۝${formatDigits(ayah.ref.ayah, arabic: true)} ',
            style: TextStyle(color: scheme.primary),
            semanticsLabel: l10n.ayahNumber('${ayah.ref.ayah}'),
          ),
        );
    }
    flush();

    final juz = metadata.juzOfPage(page);
    final firstSurah = metadata.surah(ayahs.first.ref.surah);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.surahTitle(firstSurah.arabicName),
                    style: chromeStyle,
                  ),
                ),
                Text(
                  l10n.juzTitle(formatDigits(juz.number, arabic: true)),
                  style: chromeStyle,
                ),
              ],
            ),
            Divider(color: scheme.outlineVariant),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: blocks,
                ),
              ),
            ),
            Divider(color: scheme.outlineVariant),
            Text(formatDigits(page, arabic: true), style: chromeStyle),
          ],
        ),
      ),
    );
  }
}

class _SurahHeading extends StatelessWidget {
  const _SurahHeading({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusField),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
      ),
      child: Text(
        context.l10n.surahTitle(name),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTokens.quranFontFamily,
          fontSize: 22,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
