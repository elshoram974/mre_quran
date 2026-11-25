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
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_surface_card.dart';
import '../../quran_text/application/tafsir_provider.dart';
import '../../quran_text/domain/ayah_range.dart';
import '../../quran_text/domain/ayah_texts.dart';
import '../domain/mushaf_edition.dart';
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

/// Opens the occasion of revelation of [ayah] of [edition], as the tafsir
/// opens: the ayah above in the reading's own script, the occasion under it
/// (or that none is recorded), and a step to the ayah before or after.
Future<void> showAyahAsbab(
  BuildContext context,
  MushafEdition edition,
  AyahTexts text,
  AyahRef ayah,
) => AppSheet.showFilling<void>(
  context: context,
  builder: (_, scroll) => AyahAsbabSheet(
    edition: edition,
    text: text,
    initial: ayah,
    scroll: scroll,
  ),
);

/// The body of an ayah's occasion sheet; it steps through the ayahs as the
/// tafsir does.
class AyahAsbabSheet extends ConsumerStatefulWidget {
  /// Creates the sheet on [initial].
  const AyahAsbabSheet({
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
  ConsumerState<AyahAsbabSheet> createState() => _AyahAsbabSheetState();
}

class _AyahAsbabSheetState extends ConsumerState<AyahAsbabSheet> {
  late final AyahOrder _order = AyahOrder.of(widget.text);
  late AyahRef _ayah = widget.initial;
  late final PageController _pages = PageController(
    initialPage: _order.indexOf(_ayah),
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _step(int by) {
    final page = _order.indexOf(_order.step(_ayah, by));
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: AppTokens.motionMedium,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = QuranColors.of(context);
    final digits = ref.watch(digitsFormatterProvider);
    final place =
        '${widget.text.metadata.surah(_ayah.surah).arabicName} · '
        '${l10n.ayahNumber(digits(_ayah.ayah))}';
    final index = _order.indexOf(_ayah);
    return AdhkarPinch(
      child: Column(
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
                        Text(
                          l10n.asbabTitle,
                          style: theme.textTheme.titleLarge,
                        ),
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
            child: PageView.builder(
              controller: _pages,
              itemCount: _order.total,
              onPageChanged: (page) {
                setState(() => _ayah = _order.at(page));
              },
              itemBuilder: (context, page) {
                final ayah = _order.at(page);
                return Consumer(
                  builder: (context, ref, _) {
                    final asbab = ref.watch(asbabProvider);
                    final hafs = ref
                        .watch(hafsAyahsProvider((widget.edition, ayah)))
                        .value;
                    return ListView(
                      key: ValueKey(ayah),
                      primary: false,
                      controller: page == _order.indexOf(_ayah)
                          ? widget.scroll
                          : null,
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
                                  TextSpan(text: widget.text.display(ayah)),
                                  TextSpan(
                                    text: switch (widget.text.mark(ayah)) {
                                      final String mark => ' $mark',
                                      null => ' ﴿${digits(ayah.ayah)}﴾',
                                    },
                                    style: TextStyle(color: colors.ayahNumber),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: widget.text.fontFamily,
                                fontSize:
                                    22 * ref.watch(adhkarFontScaleProvider),
                                height: 1.9,
                                color: colors.ink,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTokens.spaceMedium),
                        switch ((asbab, hafs)) {
                          (AsyncValue(:final value?), final List<AyahRef> hafs)
                              when value.passages(hafs).isNotEmpty =>
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final (i, passage)
                                    in value.passages(hafs).indexed) ...[
                                  if (i > 0) const Divider(height: 32),
                                  if (passage.ayahs.length > 1)
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        bottom: AppTokens.spaceTiny,
                                      ),
                                      child: Text(
                                        AsbabSheet._which(
                                          context,
                                          passage.ayahs,
                                          digits,
                                        ),
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    ),
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
                          // Said plainly: the book records no occasion for it.
                          (AsyncValue(hasValue: true), List<AyahRef>()) =>
                            AppNotice(l10n.asbabNone, icon: Icons.info_outline),
                          (AsyncValue(hasError: true), _) => AppNotice(
                            l10n.readerLoadError,
                            error: true,
                          ),
                          _ => const Padding(
                            padding: EdgeInsetsDirectional.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        },
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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
