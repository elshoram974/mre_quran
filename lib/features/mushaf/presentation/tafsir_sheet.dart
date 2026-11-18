import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/quran_colors.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_surface_card.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/application/tafsir_provider.dart';
import '../../quran_text/domain/ayah_range.dart';
import '../../quran_text/domain/ayah_share_text.dart';
import '../../quran_text/domain/ayah_texts.dart';
import '../../quran_text/domain/tafsir.dart';
import '../domain/mushaf_edition.dart';
import '../../settings/application/digits_provider.dart';

/// Opens Al-Tafsir Al-Muyassar of [ayah] of [edition], with the ayah above
/// it in the reading's own script, and steps to the ayah before or after it.
/// An ayah of a reading that numbers it otherwise gets the tafsir of the
/// Hafs ayah(s) it is.
Future<void> showTafsir(
  BuildContext context,
  MushafEdition edition,
  AyahTexts text,
  AyahRef ayah,
) => AppSheet.showFilling<void>(
  context: context,
  builder: (_, scroll) =>
      TafsirSheet(edition: edition, text: text, initial: ayah, scroll: scroll),
);

/// The body of the tafsir sheet.
class TafsirSheet extends ConsumerStatefulWidget {
  /// Creates the sheet on [initial].
  const TafsirSheet({
    super.key,
    required this.edition,
    required this.text,
    required this.initial,
    required this.scroll,
  });

  /// The reading the ayah is from.
  final MushafEdition edition;

  /// That reading's text.
  final AyahTexts text;

  /// The ayah the sheet opens on.
  final AyahRef initial;

  /// The sheet's scroll controller, for the part that scrolls.
  final ScrollController scroll;

  @override
  ConsumerState<TafsirSheet> createState() => _TafsirSheetState();
}

class _TafsirSheetState extends ConsumerState<TafsirSheet> {
  late final AyahOrder _order = AyahOrder.of(widget.text);
  late AyahRef _ayah = widget.initial;

  void _step(int by) {
    setState(() => _ayah = _order.step(_ayah, by));
    if (widget.scroll.hasClients) widget.scroll.jumpTo(0);
  }

  /// The tafsir to paste: its words, the quoted Quran in the usual ornate
  /// brackets (the source writes them in the Mushaf font's own glyphs), and
  /// where it is from.
  String _copyText(List<({AyahRef hafs, Tafsir tafsir})> tafsir, String place) {
    final words = tafsir
        .map((entry) => entry.tafsir.plain)
        .join('\n')
        .replaceAll('ﵡ', '﴿')
        .replaceAll('ﵠ', '﴾');
    return AyahShareText.rightToLeft(
      '$words\n[${context.l10n.tafsirTitle} · $place]',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = QuranColors.of(context);
    final digits = ref.watch(digitsFormatterProvider);
    final tafsir = ref.watch(readingTafsirProvider((widget.edition, _ayah)));
    final place =
        '${widget.text.metadata.surah(_ayah.surah).arabicName} · '
        '${l10n.ayahNumber(digits(_ayah.ayah))}';
    final index = _order.indexOf(_ayah);
    final messenger = ScaffoldMessenger.maybeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSheetDragArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppTokens.gutterCompact,
              0,
              8,
              AppTokens.spaceSmall,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.tafsirTitle, style: theme.textTheme.titleLarge),
                      Text(
                        place,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.previousAyah,
                  onPressed: index > 0 ? () => _step(-1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  tooltip: l10n.nextAyah,
                  onPressed: index < _order.total - 1 ? () => _step(1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.scroll,
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppTokens.gutterCompact,
              0,
              AppTokens.gutterCompact,
              AppTokens.gutterCompact,
            ),
            children: [
              // The ayah, whole, in the Mushaf's script.
              AppSurfaceCard(
                padding: const EdgeInsetsDirectional.all(14),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: widget.text.display(_ayah)),
                        TextSpan(
                          text: switch (widget.text.mark(_ayah)) {
                            final String mark => ' $mark',
                            null => ' ﴿${digits(_ayah.ayah)}﴾',
                          },
                          style: TextStyle(color: colors.ayahNumber),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: widget.text.fontFamily,
                      fontSize: 22,
                      height: 1.9,
                      color: colors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spaceMedium),
              switch (tafsir) {
                AsyncValue(:final value?) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in value) ...[
                      // Said when the tafsir is of another number, as Hafs
                      // counts it.
                      if (value.length > 1 || entry.hafs != _ayah)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(bottom: 4),
                          child: Text(
                            l10n.tafsirOfHafsAyah(digits(entry.hafs.ayah)),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      _TafsirText(
                        tafsir: entry.tafsir,
                        quranFont: AppTokens.mushafFontFamily,
                      ),
                      const SizedBox(height: AppTokens.spaceSmall),
                    ],
                  ],
                ),
                AsyncValue(hasError: true) => Text(l10n.tafsirLoadError),
                _ => const Padding(
                  padding: EdgeInsetsDirectional.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              },
              const SizedBox(height: AppTokens.spaceMedium),
              Text(
                l10n.tafsirCredit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AppSheetDragArea(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppTokens.gutterCompact,
              AppTokens.spaceSmall,
              AppTokens.gutterCompact,
              MediaQuery.paddingOf(context).bottom + 12,
            ),
            child: OutlinedButton.icon(
              onPressed: tafsir.value == null
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(text: _copyText(tafsir.value!, place)),
                      );
                      messenger?.showSnackBar(
                        SnackBar(content: Text(l10n.tafsirCopied)),
                      );
                    },
              icon: const Icon(Icons.copy_outlined),
              label: Text(l10n.tafsirCopy),
            ),
          ),
        ),
      ],
    );
  }
}

/// The tafsir's words, right to left, with the Quran it quotes in the
/// Mushaf's script and accent colour.
class _TafsirText extends StatelessWidget {
  const _TafsirText({required this.tafsir, required this.quranFont});

  final Tafsir tafsir;
  final String quranFont;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = QuranColors.of(context);
    final body = theme.textTheme.bodyLarge?.copyWith(height: 1.9);
    return Directionality(
      // The tafsir is Arabic in every app language.
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(
          children: [
            for (final part in tafsir.parts)
              TextSpan(
                text: part.text,
                style: part.quran
                    ? TextStyle(fontFamily: quranFont, color: colors.ayahNumber)
                    : null,
              ),
          ],
        ),
        textAlign: TextAlign.justify,
        style: body,
      ),
    );
  }
}
