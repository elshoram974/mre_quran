import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bookmarks/application/bookmarks_provider.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/domain/quran_text.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/application/digits_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../application/reader_immersive_provider.dart';
import '../application/reading_position_provider.dart';
import '../../../core/l10n/l10n.dart';
import '../application/highlighted_ayah_provider.dart';
import '../application/page_prefetcher.dart';
import '../application/svg_page_providers.dart';
import 'ayah_actions_sheet.dart';
import 'flip/book_flip.dart';
import 'mushaf_page_view.dart';
import 'svg_page_view.dart';

/// Window width from which two pages are shown side by side.
const double mushafSpreadMinWidth = 700;

/// Shortest side a screen needs before "automatic" may choose two pages. A
/// phone turned on its side is wide enough for two pages and far too small to
/// read them, so it keeps one; tablets start at 600.
const double mushafSpreadMinShortestSide = 600;

/// Whether the reader shows two facing pages in a window of [size].
///
/// Automatic is for a tablet held wide: the screen is wider than tall and big
/// enough to read two pages. A tall window (a portrait tablet, a phone) shows
/// one page that fills it. A person's own choice always wins, so a facing
/// spread can be asked for on a small screen and a single page on a large one.
bool resolveMushafSpread(ReaderPageLayout layout, Size size) =>
    switch (layout) {
      ReaderPageLayout.auto =>
        size.width >= mushafSpreadMinWidth &&
            size.shortestSide >= mushafSpreadMinShortestSide &&
            size.width > size.height,
      ReaderPageLayout.single => false,
      ReaderPageLayout.spread => true,
    };

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
      return _PagerBody(
        text: text,
        availableWidth: constraints.maxWidth,
        availableHeight: constraints.maxHeight,
        initialPage: initialPage,
      );
    },
  );
}

class _PagerBody extends ConsumerStatefulWidget {
  const _PagerBody({
    required this.text,
    required this.availableWidth,
    required this.availableHeight,
    required this.initialPage,
  });

  final QuranText text;
  final double availableWidth;
  final double availableHeight;
  final int initialPage;

  @override
  ConsumerState<_PagerBody> createState() => _PagerBodyState();
}

class _PagerBodyState extends ConsumerState<_PagerBody> {
  AyahRef? _selected;
  int? _prefetched;

  /// The page shown at the last build, and whether the reader last turned
  /// back rather than on.
  int? _lastPage;
  bool _backward = false;

  /// Starts downloading the printed pages around [page] once per change.
  void _prefetch(int page) {
    if (page == _prefetched) return;
    _prefetched = page;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(pagePrefetcherProvider)
          .around(page: page, pageCount: _pageCount);
    });
  }

  int get _pageCount => widget.text.metadata.pageCount;

  Future<void> _showActions(AyahRef ayah) async {
    setState(() => _selected = ayah);
    await showAyahActions(context, widget.text, ayah);
    if (mounted) setState(() => _selected = null);
  }

  /// Keeps the text size a pinch reached.
  void _saveFontScale(double scale) {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    ref
        .read(settingsProvider.notifier)
        .save(settings.copyWith(readerFontScale: scale));
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
    final digits = ref.watch(digitsFormatterProvider);
    final realistic = ref.watch(
      settingsProvider.select((s) => s.value?.realisticPageTurn ?? false),
    );
    final mode = ref.watch(
      settingsProvider.select((s) => s.value?.readerMode ?? ReaderMode.printed),
    );
    final layout = ref.watch(
      settingsProvider.select(
        (s) => s.value?.readerPageLayout ?? ReaderPageLayout.auto,
      ),
    );
    // Decided on the whole window, as the toolbar's toggle is, so the two
    // never disagree; the rail or bar beside the pages does not change it.
    final spread = resolveMushafSpread(layout, MediaQuery.sizeOf(context));
    if (mode == ReaderMode.printed) {
      _prefetch(page);
    }
    final edition = ref.watch(printedEditionProvider);
    final ownText = edition.matchesAppText;
    final bookmarked = ref.watch(bookmarkedRefsProvider);
    final highlighted = ref.watch(highlightedAyahProvider);

    final book = Directionality(
      // The Mushaf turns right to left in every app language.
      textDirection: TextDirection.rtl,
      child: BookFlip(
        key: ValueKey<bool>(spread),
        pageCount: _pageCount,
        spread: spread,
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
            digits: digits,
            bookmarked: bookmarked,
            selected: _selected ?? highlighted,
            onAyahLongPress: _showActions,
            onFontScaleChanged: _saveFontScale,
            onTap: _onTap,
            spread: spread,
          ),
          ReaderMode.printed when !ownText => SvgPageView(
            // Another reading: its ayahs are not the app's text, so nothing
            // of that text is tied to the page or stands in for it.
            metadata: widget.text.metadata,
            page: number,
            digits: digits,
            fillWidth: !spread,
            spreadLines: edition.spreadsLines,
            spread: spread,
            onTap: _onTap,
          ),
          ReaderMode.printed => SvgPageView(
            metadata: widget.text.metadata,
            page: number,
            digits: digits,
            fillWidth: !spread,
            spreadLines: edition.spreadsLines,
            spread: spread,
            bookmarked: bookmarked,
            selected: _selected ?? highlighted,
            onAyahLongPress: _showActions,
            onTap: _onTap,
            // Without its artwork the page still reads, as text.
            fallbackBuilder: (_) => MushafPageView(
              text: widget.text,
              page: number,
              fontScale: fontScale,
              digits: digits,
              bookmarked: bookmarked,
              selected: _selected ?? highlighted,
              onAyahLongPress: _showActions,
              onTap: _onTap,
              framed: false,
              spread: spread,
            ),
          ),
        },
      ),
    );
    if (mode != ReaderMode.printed) return book;
    final last = _lastPage;
    if (last != null && last != page) _backward = page < last;
    _lastPage = page;
    // The pages a turn away are laid out, unseen, in the same room. A page
    // on the device then has its artwork decoded and drawn before the
    // reader turns to it, instead of showing a placeholder for a moment.
    return Stack(
      children: [
        for (final near in _pagesToWarm(page, spread: spread))
          Positioned.fill(
            child: Offstage(
              child: SvgPageView(
                key: ValueKey<String>('warm-$near'),
                metadata: widget.text.metadata,
                page: near,
                digits: digits,
                fillWidth: !spread,
                spreadLines: edition.spreadsLines,
                spread: spread,
                onTap: () {},
              ),
            ),
          ),
        Positioned.fill(child: book),
      ],
    );
  }

  /// How many turns ahead of the reader, and behind, pages are made ready.
  /// Reading goes on more often than back.
  static const int _warmAhead = 3;
  static const int _warmBehind = 1;

  /// The pages a few turns from the ones on screen: more on the side the
  /// reader is going, fewer on the side they came from. The farthest comes
  /// first and the nearest last, as the page asked for last is prepared
  /// first.
  Iterable<int> _pagesToWarm(int page, {required bool spread}) {
    final shown = spread ? 2 : 1;
    // In a spread the odd page is on the right and its even page follows.
    final first = spread && page.isEven ? page - 1 : page;
    final turns = [
      for (var turn = _warmAhead; turn >= 1; turn--) ...[
        if (turn <= _warmBehind) (_backward ? turn : -turn),
        (_backward ? -turn : turn),
      ],
    ];
    return [
      for (final turn in turns)
        for (var i = 0; i < shown; i++) first + turn * shown + i,
    ].where((near) => near >= 1 && near <= _pageCount);
  }
}
