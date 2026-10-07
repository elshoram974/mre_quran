import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bookmarks/application/bookmarks_provider.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/domain/quran_text.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../application/reader_immersive_provider.dart';
import '../application/reading_position_provider.dart';
import '../../../core/l10n/l10n.dart';
import '../application/highlighted_ayah_provider.dart';
import '../application/page_prefetcher.dart';
import 'ayah_actions_sheet.dart';
import 'flip/book_flip.dart';
import 'mushaf_page_view.dart';
import 'printed_page_view.dart';

/// Window width from which two pages are shown side by side.
const double mushafSpreadMinWidth = 700;

/// The Mushaf as a book that turns its pages (see [BookFlip]).
///
/// Wide windows show a two-page spread: an odd page on the right and the even
/// page on its left, so the first spread is pages 1 and 2. Narrow windows show
/// one page. The pager saves every turn and follows page changes made
/// elsewhere (index, search, bookmarks).
class MushafPager extends StatelessWidget {
  /// Creates the pager over [text], opening at [initialPage].
  const MushafPager({super.key, required this.text, required this.initialPage});

  /// The verified text.
  final QuranText text;

  /// Page to open at, 1–604.
  final int initialPage;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final spread = constraints.maxWidth >= mushafSpreadMinWidth;
      return _PagerBody(
        key: ValueKey<bool>(spread),
        text: text,
        spread: spread,
        initialPage: initialPage,
      );
    },
  );
}

class _PagerBody extends ConsumerStatefulWidget {
  const _PagerBody({
    super.key,
    required this.text,
    required this.spread,
    required this.initialPage,
  });

  final QuranText text;
  final bool spread;
  final int initialPage;

  @override
  ConsumerState<_PagerBody> createState() => _PagerBodyState();
}

class _PagerBodyState extends ConsumerState<_PagerBody> {
  AyahRef? _selected;
  ({MushafStyle style, int page, bool dark})? _prefetched;

  /// Starts downloading the printed pages around [page] once per change.
  void _prefetch(MushafStyle style, int page, bool dark) {
    final key = (style: style, page: page, dark: dark);
    if (key == _prefetched) return;
    _prefetched = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(pagePrefetcherProvider)
          .around(style: style, page: page, dark: dark, pageCount: _pageCount);
    });
  }

  int get _pageCount => widget.text.metadata.pageCount;

  Future<void> _showActions(AyahRef ayah) async {
    setState(() => _selected = ayah);
    await showAyahActions(context, widget.text, ayah);
    if (mounted) setState(() => _selected = null);
  }

  void _onTap() {
    ref.read(highlightedAyahProvider.notifier).clear();
    ref.read(readerImmersiveProvider.notifier).toggle();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final page = ref.watch(readingPositionProvider).value ?? widget.initialPage;
    final fontScale = ref.watch(
      settingsProvider.select((s) => s.value?.readerFontScale ?? 1),
    );
    final realistic = ref.watch(
      settingsProvider.select((s) => s.value?.realisticPageTurn ?? false),
    );
    final mode = ref.watch(
      settingsProvider.select((s) => s.value?.readerMode ?? ReaderMode.printed),
    );
    final style = ref.watch(
      settingsProvider.select(
        (s) => s.value?.mushafStyle ?? MushafStyle.madinah,
      ),
    );
    if (mode == ReaderMode.printed) {
      _prefetch(style, page, Theme.of(context).brightness == Brightness.dark);
    }
    final bookmarked = ref.watch(bookmarkedRefsProvider);
    final highlighted = ref.watch(highlightedAyahProvider);

    return Directionality(
      // The Mushaf turns right to left in every app language.
      textDirection: TextDirection.rtl,
      child: BookFlip(
        pageCount: _pageCount,
        spread: widget.spread,
        realistic: realistic,
        page: page,
        nextLabel: l10n.nextPage,
        previousLabel: l10n.previousPage,
        // The bars would be in the snapshot of the sheet; put them away first.
        onTurnStart: () => ref.read(readerImmersiveProvider.notifier).hide(),
        onPageChanged: (turned) =>
            ref.read(readingPositionProvider.notifier).setPage(turned),
        pageBuilder: (context, number) => switch (mode) {
          ReaderMode.text => MushafPageView(
            text: widget.text,
            page: number,
            fontScale: fontScale,
            bookmarked: bookmarked,
            selected: _selected ?? highlighted,
            onAyahLongPress: _showActions,
            onTap: _onTap,
          ),
          ReaderMode.printed => PrintedPageView(
            metadata: widget.text.metadata,
            style: style,
            page: number,
            bookmarked: bookmarked,
            selected: _selected ?? highlighted,
            onAyahLongPress: _showActions,
            onTap: _onTap,
          ),
        },
      ),
    );
  }
}
