import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../settings/application/digits_provider.dart';
import '../application/reader_immersive_provider.dart';
import 'go_to_page_sheet.dart';
import 'reader_bar.dart';
import 'reader_navigation.dart';

/// What a printed Mushaf prints on its own page: the surah and the juz above
/// the text, and the page number below it, with an arrow onward. They are
/// part of the page, so they turn with it and show on the sheet while it
/// turns. While the floating bars show they would lie under them, so they
/// step aside.
class ReaderPageLabels extends ConsumerWidget {
  /// Creates the labels of [page].
  const ReaderPageLabels({
    super.key,
    required this.metadata,
    required this.page,
    this.spread = false,
  });

  /// Quran structure, for the surah and juz of the page.
  final QuranMetadata metadata;

  /// Page number, 1–604.
  final int page;

  /// Whether this page faces another. The arrows then stay on the outer edges
  /// only: an odd page sits on the right and keeps "back", an even page sits
  /// on the left and keeps "onward". The arrow in the middle of the book
  /// would only point at the other page.
  final bool spread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final digits = ref.watch(digitsFormatterProvider);
    final barsShown = !ref.watch(readerImmersiveProvider);
    final surah = metadata.surahAtPage(page);
    final juz = metadata.juzOfPage(page);

    Future<void> goToPage() async {
      final chosen = await showGoToPage(
        context,
        page: page,
        pageCount: metadata.pageCount,
        digits: digits,
      );
      if (chosen != null) goToReaderPage(ref, chosen);
    }

    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    Widget aside(Widget child) => IgnorePointer(
      ignoring: barsShown,
      child: AnimatedOpacity(
        opacity: barsShown ? 0 : 1,
        duration: duration,
        child: child,
      ),
    );

    return Stack(
      children: [
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          child: aside(
            ReaderHeader(
              start: [
                ReaderChip(
                  label: surah.arabicName,
                  tooltip: l10n.quranIndex,
                  onPressed: () =>
                      openReaderRoute(context, ref, AppRoute.quranIndex),
                ),
                if (surah.number < metadata.surahs.length)
                  ReaderChip(
                    // The Mushaf turns right to left: onward is to the left.
                    icon: Icons.chevron_left_rounded,
                    tooltip: l10n.nextSurah,
                    onPressed: () => goToReaderPage(
                      ref,
                      metadata.surah(surah.number + 1).startPage,
                    ),
                  ),
              ],
              middle: const SizedBox.shrink(),
              end: [
                ReaderChip(
                  label: l10n.juzTitle(digits(juz.number)),
                  tooltip: l10n.quranIndex,
                  onPressed: () =>
                      openReaderRoute(context, ref, AppRoute.quranIndex),
                ),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          bottom: 0,
          start: 0,
          end: 0,
          child: aside(
            ReaderFooter(
              children: [
                // Fixed sides: back to the right, onward to the left.
                if (page > 1 && !(spread && page.isEven))
                  ReaderChip(
                    icon: Icons.chevron_right_rounded,
                    tooltip: l10n.previousPage,
                    onPressed: () => goToReaderPage(ref, page - 1),
                  )
                else
                  const SizedBox(width: 48),
                ReaderChip(
                  label: digits(page),
                  tooltip: l10n.goToPage,
                  onPressed: goToPage,
                ),
                if (page < metadata.pageCount && !(spread && page.isOdd))
                  ReaderChip(
                    icon: Icons.chevron_left_rounded,
                    tooltip: l10n.nextPage,
                    onPressed: () => goToReaderPage(ref, page + 1),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
