import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/quran_colors.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../adhkar/application/adhkar_font_scale_provider.dart';
import '../../adhkar/presentation/adhkar_pinch.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/application/asbab_provider.dart';
import '../../settings/application/digits_provider.dart';

/// Opens the occasions of revelation of [ayahs] (Hafs numbering), under
/// [place]: one ayah's, from its actions, or a surah's, from its sheet.
Future<void> showAsbab(
  BuildContext context, {
  required List<AyahRef> ayahs,
  required String place,
}) => AppSheet.showFilling<void>(
  context: context,
  builder: (_, scroll) =>
      AsbabSheet(ayahs: ayahs, place: place, scroll: scroll),
);

/// The body of the occasions sheet: each passage once, under the ayahs it is
/// about, the ayahs it quotes coloured, and where it comes from. Two fingers
/// change the size of the words, as in the tafsir and the adhkar.
class AsbabSheet extends ConsumerWidget {
  /// Creates the sheet.
  const AsbabSheet({
    super.key,
    required this.ayahs,
    required this.place,
    required this.scroll,
  });

  /// The ayahs whose occasions are shown.
  final List<AyahRef> ayahs;

  /// Where they are, said under the title.
  final String place;

  /// The sheet's scroll controller, for the part that scrolls.
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final digits = ref.watch(digitsFormatterProvider);
    final asbab = ref.watch(asbabProvider);
    final padding = const EdgeInsetsDirectional.fromSTEB(
      AppTokens.gutterCompact,
      0,
      AppTokens.gutterCompact,
      AppTokens.gutterCompact,
    );
    return AdhkarPinch(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetDragArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppTokens.gutterCompact,
                0,
                AppTokens.gutterCompact,
                AppTokens.spaceSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.asbabTitle, style: theme.textTheme.titleLarge),
                  Text(
                    place,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: switch (asbab) {
              AsyncValue(:final value?) => ListView(
                controller: scroll,
                primary: false,
                padding: padding,
                children: [
                  for (final (index, passage)
                      in value.passages(ayahs).indexed) ...[
                    if (index > 0) const Divider(height: 32),
                    Text(
                      _which(context, passage.ayahs, digits),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceTiny),
                    _AsbabText(passage.text),
                  ],
                  const SizedBox(height: AppTokens.spaceMedium),
                  Text(
                    l10n.asbabSource(value.version),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              AsyncValue(error: _?) => EmptyState(
                icon: Icons.error_outline,
                title: l10n.readerLoadError,
                message: '',
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(asbabProvider),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }

  /// Which ayahs a passage is about: one, a run, or several.
  static String _which(
    BuildContext context,
    List<AyahRef> ayahs,
    String Function(int) digits,
  ) {
    final l10n = context.l10n;
    if (ayahs.length == 1) return l10n.asbabAyah(digits(ayahs.single.ayah));
    final first = ayahs.first.ayah;
    final last = ayahs.last.ayah;
    final run = last - first + 1 == ayahs.length;
    return run
        ? l10n.asbabAyahRange(digits(first), digits(last))
        : l10n.asbabAyahList(ayahs.map((ayah) => digits(ayah.ayah)).join('، '));
  }
}

/// A passage, the ayahs it quotes (inside ﴿ ﴾) in the colour of the ayahs.
class _AsbabText extends ConsumerWidget {
  const _AsbabText(this.text);

  final String text;

  static final RegExp _quote = RegExp('﴿[^﴾]*﴾');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = QuranColors.of(context);
    // The size the person chose for the words they read, as in the adhkar.
    final size = ref.watch(adhkarFontScaleProvider);
    final base = theme.textTheme.bodyLarge;
    final spans = <TextSpan>[];
    var at = 0;
    for (final match in _quote.allMatches(text)) {
      if (match.start > at) {
        spans.add(TextSpan(text: text.substring(at, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(color: colors.ayahNumber),
        ),
      );
      at = match.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Directionality(
      // The book is Arabic in every app language.
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.justify,
        style: base?.copyWith(
          fontSize: (base.fontSize ?? 16) * size,
          height: 1.9,
        ),
      ),
    );
  }
}
