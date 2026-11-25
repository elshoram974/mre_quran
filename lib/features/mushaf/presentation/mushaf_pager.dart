import 'dart:async';

import '../../../core/widgets/app_snack_bar.dart';

import 'dart:ui' show DisplayFeature, DisplayFeatureType;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bookmarks/application/bookmarks_provider.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/domain/ayah_range.dart';
import '../../quran_text/domain/quran_text.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/application/digits_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../application/reader_immersive_provider.dart';
import '../application/reading_position_provider.dart';
import '../../../core/l10n/l10n.dart';
import '../application/ayah_selection_provider.dart';
import '../application/highlighted_ayah_provider.dart';
import '../application/mushaf_packs.dart';
import '../application/page_elsewhere.dart';
import '../application/page_prefetcher.dart';
import '../application/printed_fallback.dart';
import '../application/svg_page_providers.dart';
import '../../startup/application/startup_providers.dart';
import '../../quran_text/application/ayah_texts_provider.dart';
import 'ayah_actions_sheet.dart';
import 'ayah_share_format.dart';
import 'flip/book_flip.dart';
import 'mushaf_page_view.dart';
import 'page_elsewhere_options.dart';
import 'reader_orientation.dart';
import 'svg_page_view.dart';

/// Window width from which two pages are shown side by side.
const double mushafSpreadMinWidth = 700;

/// Shortest side a screen needs before "automatic" may choose two pages. A
/// phone turned on its side is wide enough for two pages and far too small to
/// read them, so it keeps one; tablets start at 600.
const double mushafSpreadMinShortestSide = 600;

/// How tall a window may be for its width and still open as a book: the
/// near-square inner screen of a foldable (an iPhone Duo, a Galaxy or Pixel
/// Fold opened like a book) gives each page about a phone's width, which
/// reads well. A tablet held tall is taller than this and keeps one page.
const double mushafSpreadMaxTallness = 1.15;

/// Whether the reader shows two facing pages in a window of [size], whose
/// display has [features] (a foldable's fold or hinge).
///
/// Automatic opens the Mushaf as a book where it reads like one: a tablet held
/// wide, the near-square inner screen of a foldable, and any screen whose fold
/// stands upright between two halves, a page on each side of it, as a printed
/// Mushaf opens at its spine. A tall window (a portrait tablet, a phone) and a
/// phone on its side show one page. A person's own choice always wins, so a
/// facing spread can be asked for on a small screen and a single page on a
/// large one.
bool resolveMushafSpread(
  ReaderPageLayout layout,
  Size size, {
  List<DisplayFeature> features = const [],
}) => switch (layout) {
  ReaderPageLayout.auto =>
    _uprightFold(features, size) ||
        (size.width >= mushafSpreadMinWidth &&
            size.shortestSide >= mushafSpreadMinShortestSide &&
            size.height <= size.width * mushafSpreadMaxTallness),
  ReaderPageLayout.single => false,
  ReaderPageLayout.spread => true,
};

/// Whether the Mushaf turns its pages like paper ([BookFlip.realistic]) in a
/// window of [size] that shows two facing pages when [spread] is true.
///
/// Automatic turns them like paper where the Mushaf reads like a book: two
/// facing pages, and a single page on a screen as large as a tablet's (its
/// shortest side at least [mushafSpreadMinShortestSide], the same line the
/// automatic spread draws). A phone slides its pages. A person's own choice
/// always wins.
bool resolveRealisticPageTurn(
  PageTurnStyle style,
  Size size, {
  required bool spread,
}) => switch (style) {
  PageTurnStyle.auto =>
    spread || size.shortestSide >= mushafSpreadMinShortestSide,
  PageTurnStyle.realistic => true,
  PageTurnStyle.slide => false,
};

/// Whether a fold or hinge runs top to bottom near the middle of [size].
bool _uprightFold(List<DisplayFeature> features, Size size) {
  for (final feature in features) {
    if (feature.type != DisplayFeatureType.fold &&
        feature.type != DisplayFeatureType.hinge) {
      continue;
    }
    final bounds = feature.bounds;
    final upright = bounds.height >= size.height * 0.9;
    final central = (bounds.center.dx - size.width / 2).abs() < size.width / 8;
    if (upright && central) return true;
  }
  return false;
}

/// The Mushaf as a book that turns its pages (see [BookFlip]).
///
/// Wide windows show a two-page spread: an odd page on the right and the even
/// page on its left, so the first spread is pages 1 and 2. Narrow windows show
/// one page. The pager saves every turn and follows page changes made
/// elsewhere (index, search, bookmarks).
class MushafPager extends StatelessWidget {
  /// How long the message turning the Mushaf to text waits to learn whether
  /// another reading has the page.
  @visibleForTesting
  static Duration lookupWait = const Duration(milliseconds: 300);

  /// Creates the pager over the Quran's [metadata], opening at
  /// [initialPage].
  const MushafPager({
    super.key,
    required this.metadata,
    required this.text,
    required this.initialPage,
  });

  /// The Quran's structure: all the printed pages need.
  final QuranMetadata metadata;

  /// The verified text, once read: the typeset reader needs it, and the
  /// printed pages fall back to it. Null while it is still being read.
  final QuranText? text;

  /// Page to open at, 1–604.
  final int initialPage;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      return _PagerBody(
        metadata: metadata,
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
    required this.metadata,
    required this.text,
    required this.availableWidth,
    required this.availableHeight,
    required this.initialPage,
  });

  final QuranMetadata metadata;
  final QuranText? text;
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

  int get _pageCount => widget.metadata.pageCount;

  int? _retried;

  /// While the Mushaf shows as text because it was offline, tries the
  /// printed pages again once per page the reader turns to.
  void _retryPrinted(int page) {
    if (page == _retried) return;
    _retried = page;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(printedFallbackProvider.notifier).retry(page);
    });
  }

  /// A printed page could not be had offline. Only a page the reader sees
  /// counts: one built out of sight for a turn does not switch the Mushaf.
  void _printedOffline(int number) {
    if (!mounted) return;
    final page = ref.read(readingPositionProvider).value;
    if (page == null) return;
    final spread = resolveMushafSpread(
      ref.read(settingsProvider).value?.readerPageLayout ??
          ReaderPageLayout.auto,
      MediaQuery.sizeOf(context),
      features: MediaQuery.displayFeaturesOf(context),
    );
    // In a spread an odd page and the even one after it face each other.
    final shown = spread
        ? (number - 1) ~/ 2 == (page - 1) ~/ 2
        : number == page;
    if (shown) ref.read(printedFallbackProvider.notifier).offline();
  }

  /// Says why the Mushaf changed how it shows, while the reader is the tab
  /// on screen: each case in its own words, so the reason is never wrong.
  /// Turned to text offline, it offers another reading that has the page on
  /// the phone, if one does.
  Future<void> _announce(PrintedFallbackEvent? event) async {
    if (event == null || !TickerMode.valuesOf(context).enabled) return;
    final language = Localizations.localeOf(context).languageCode;
    final edition = ref.read(printedEditionProvider);
    final reading = edition.name(language);
    MushafEdition? saved;
    final page = ref.read(readingPositionProvider).value;
    if (event.change == PrintedFallbackChange.toText && page != null) {
      // Held while it is worked out, or it would go before it answers; and
      // waited for only briefly, so the message is never late.
      final lookup = ref.listenManual(
        pageElsewhereProvider((edition: edition, page: page)).future,
        (_, _) {},
      );
      try {
        final elsewhere = await lookup.read().timeout(MushafPager.lookupWait);
        saved = elsewhere.readings.firstOrNull;
      } on Object {
        // Not known in time: the message goes without the offer.
      } finally {
        lookup.close();
      }
      if (!mounted) return;
    }
    final l10n = context.l10n;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        AppSnackBar(
          switch (event.change) {
            PrintedFallbackChange.toText => [
              l10n.printedSwitchedToText,
              if (saved != null) l10n.printedPageSavedIn(saved.name(language)),
            ].join(' '),
            PrintedFallbackChange.toTextChosen => l10n.printedTextInstead(
              reading,
            ),
            PrintedFallbackChange.toPrinted => l10n.printedBackOnline,
            PrintedFallbackChange.toPrintedSaved => l10n.printedBackSaved,
            PrintedFallbackChange.toSavedReading => l10n.printedShownIn(
              reading,
            ),
          },
          // A short label: the reading's name is in the message.
          action: saved == null
              ? null
              : SnackBarAction(
                  label: l10n.printedShowSaved,
                  onPressed: () => ref
                      .read(printedFallbackProvider.notifier)
                      .openReading(saved!),
                ),
        ),
      );
  }

  /// What a long press on an ayah of a page of [edition] does: open its
  /// actions, or, while ayahs are being chosen, take the choice to it.
  ValueChanged<AyahRef> _actionsOf(MushafEdition edition) => (ayah) {
    if (ref.read(ayahSelectionProvider) != null) {
      _extend(edition, ayah);
    } else {
      _showActions(edition, ayah);
    }
  };

  Future<void> _showActions(MushafEdition edition, AyahRef ayah) async {
    final texts = ref.read(editionTextsProvider(edition)).value;
    // In a reading whose text and pages count this surah differently, the
    // ayah is shown selected but its words are not offered.
    if (texts == null || !texts.has(ayah)) return;
    setState(() => _selected = ayah);
    await showAyahActions(
      context,
      texts,
      ayah,
      bookmarks: edition.matchesAppText,
      tafsir: edition,
      onSelectMore: () =>
          ref.read(ayahSelectionProvider.notifier).start(edition, texts, ayah),
    );
    if (mounted) setState(() => _selected = null);
  }

  /// Takes the ayahs being chosen to [ayah], on a page of [edition].
  void _extend(MushafEdition edition, AyahRef ayah) {
    final selection = ref.read(ayahSelectionProvider);
    if (selection == null || selection.edition != edition) return;
    if (!selection.texts.has(ayah)) return;
    final fits = ref
        .read(ayahSelectionProvider.notifier)
        .extendTo(ayah, limit: ayahShareLimit);
    if (fits) return;
    final l10n = context.l10n;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        AppSnackBar(
          l10n.selectionLimitReached(
            ref.read(digitsFormatterProvider)(ayahShareLimit),
          ),
        ),
      );
  }

  /// The ayahs to highlight on a page of [edition]: the ones being chosen,
  /// the one whose actions are open, or the one the reader arrived at.
  AyahRange? _highlightOn(
    MushafEdition edition,
    AyahSelection? selection,
    AyahRef? highlighted,
  ) {
    if (selection != null && selection.edition == edition) {
      return selection.range;
    }
    final single = _selected ?? highlighted;
    return single == null ? null : AyahRange.single(single);
  }

  /// Keeps the text size a pinch reached.
  void _saveFontScale(double scale) {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    ref
        .read(settingsProvider.notifier)
        .save(settings.copyWith(readerFontScale: scale));
  }

  DateTime? _suggestedAt;

  /// Two fingers spread on a printed page, which cannot be enlarged: suggest
  /// what does read bigger. Held upright, turning the phone sideways gives
  /// the page its wider side; held sideways, the typeset text does.
  void _suggestBiggerText() {
    final now = DateTime.now();
    final last = _suggestedAt;
    if (last != null && now.difference(last) < const Duration(seconds: 10)) {
      return;
    }
    final l10n = context.l10n;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final canUseText =
        widget.text != null && ref.read(printedEditionProvider).matchesAppText;
    if (landscape && !canUseText) return;
    _suggestedAt = now;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        AppSnackBar(
          landscape ? l10n.pinchTextHint : l10n.pinchLandscapeHint,
          action: SnackBarAction(
            label: landscape ? l10n.pinchTextAction : l10n.pinchLandscapeAction,
            onPressed: landscape ? _showAsText : turnReaderLandscape,
          ),
        ),
      );
  }

  void _showAsText() =>
      ref.read(settingsProvider.notifier).chooseReaderMode(ReaderMode.text);

  void _onTap() {
    ref.read(highlightedAyahProvider.notifier).clear();
    // An open page scrubber closes first; the bars stay.
    if (ref.read(readerScrubberProvider)) {
      ref.read(readerScrubberProvider.notifier).close();
      return;
    }
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
    final frame = ref.watch(
      settingsProvider.select(
        (s) => s.value?.surahFrame ?? SurahFrameStyle.cartouche,
      ),
    );
    final pageTurn = ref.watch(
      settingsProvider.select((s) => s.value?.pageTurn ?? PageTurnStyle.auto),
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
    final window = MediaQuery.sizeOf(context);
    final spread = resolveMushafSpread(
      layout,
      window,
      features: MediaQuery.displayFeaturesOf(context),
    );
    final realistic = resolveRealisticPageTurn(
      pageTurn,
      window,
      spread: spread,
    );
    // At start-up the page on screen comes first; the pages around it are
    // fetched and prepared once it is drawn, so they never slow it down.
    final settled = ref.watch(readerPaintedProvider);
    if (mode == ReaderMode.printed && settled) {
      _prefetch(page);
    }
    final edition = ref.watch(printedEditionProvider);
    // A Mushaf the system finished downloading while the app was closed is
    // unpacked once the first page is drawn, so it reads offline at once.
    if (settled) ref.listen(waitingPackProvider(edition), (_, _) {});
    ref.listen(
      printedFallbackProvider,
      (_, event) => unawaited(_announce(event)),
    );
    final textUntilOnline = ref.watch(
      settingsProvider.select((s) => s.value?.textUntilOnline ?? false),
    );
    if (mode == ReaderMode.text && textUntilOnline) {
      _retryPrinted(page);
    } else {
      _retried = null;
    }
    final ownText = edition.matchesAppText;
    // Its text is read ahead, so a long press finds it ready.
    final hasText = ref.watch(editionTextsProvider(edition)).value != null;
    final bookmarked = ref.watch(bookmarkedRefsProvider);
    final highlighted = ref.watch(highlightedAyahProvider);
    final selection = ref.watch(ayahSelectionProvider);
    // While ayahs are being chosen, a tap on one takes the choice to it.
    ValueChanged<AyahRef>? tapOf(MushafEdition edition) =>
        selection == null ? null : (ayah) => _extend(edition, ayah);

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
          // The page waits for the text it is set in: the reader shows only
          // once it is read.
          ReaderMode.text => MushafPageView(
            text: widget.text!,
            page: number,
            fontScale: fontScale,
            frame: frame,
            digits: digits,
            bookmarked: bookmarked,
            selected: _highlightOn(MushafEditions.hafs, selection, highlighted),
            // The typeset text and its stand-in are always Hafs.
            onAyahLongPress: _actionsOf(MushafEditions.hafs),
            onFontScaleChanged: _saveFontScale,
            onTap: _onTap,
            spread: spread,
          ),
          ReaderMode.printed when !ownText => SvgPageView(
            // Another reading: its ayahs are numbered its own way, so the
            // app's bookmarks and highlights (Hafs numbers) are not tied to
            // the page, and the app's text does not stand in for it. Its own
            // text is copied and shared.
            metadata: widget.metadata,
            page: number,
            digits: digits,
            onPinchOut: _suggestBiggerText,
            fillWidth: !spread,
            spread: spread,
            selected: _highlightOn(edition, selection, null),
            onAyahLongPress: hasText ? _actionsOf(edition) : null,
            onAyahTap: tapOf(edition),
            onTap: _onTap,
            // Its page cannot be had: the app's own text (Hafs) may be read
            // in its place, if the person asks.
            onReadText: widget.text == null
                ? null
                : (offline) => ref
                      .read(printedFallbackProvider.notifier)
                      .readTextInstead(offline: offline),
            offlineExtras: (_) =>
                PageElsewhereOptions(edition: edition, page: number),
          ),
          ReaderMode.printed => SvgPageView(
            metadata: widget.metadata,
            page: number,
            digits: digits,
            onPinchOut: _suggestBiggerText,
            fillWidth: !spread,
            spread: spread,
            bookmarked: bookmarked,
            selected: _highlightOn(MushafEditions.hafs, selection, highlighted),
            // The typeset text and its stand-in are always Hafs.
            onAyahLongPress: _actionsOf(MushafEditions.hafs),
            onAyahTap: tapOf(MushafEditions.hafs),
            onTap: _onTap,
            // Offline, the whole Mushaf turns to text, and says so.
            onOffline: () => _printedOffline(number),
            offlineExtras: (_) =>
                PageElsewhereOptions(edition: edition, page: number),
            // Without its artwork the page still reads, as text, once the
            // text is read.
            fallbackBuilder: widget.text == null
                ? null
                : (_) => MushafPageView(
                    text: widget.text!,
                    page: number,
                    fontScale: 1,
                    frame: frame,
                    digits: digits,
                    bookmarked: bookmarked,
                    selected: _highlightOn(
                      MushafEditions.hafs,
                      selection,
                      highlighted,
                    ),
                    // The typeset text and its stand-in are always Hafs.
                    onAyahLongPress: _actionsOf(MushafEditions.hafs),
                    onTap: _onTap,
                    framed: false,
                    spread: spread,
                  ),
          ),
        },
      ),
    );
    if (mode != ReaderMode.printed || !settled) return book;
    final last = _lastPage;
    if (last != null && last != page) _backward = page < last;
    _lastPage = page;
    // The pages a few turns away are prepared ahead: read from the device,
    // checked and compiled, so a turn finds them ready. They are held by a
    // listener here, never built as unseen widgets: a page view kept off
    // stage keeps provider subscriptions that the framework may pause and
    // close under it.
    final slot = Size(
      spread ? widget.availableWidth / 2 : widget.availableWidth,
      widget.availableHeight,
    );
    for (final near in _pagesToWarm(page, spread: spread)) {
      ref.listen(
        svgPageProvider(
          SvgPageView.requestIn(slot, page: near, fillWidth: !spread),
        ),
        (_, _) {},
        onError: (_, _) {},
      );
    }
    return book;
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
