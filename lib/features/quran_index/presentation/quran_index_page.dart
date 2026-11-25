import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_fields/mre_fields.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/theme/app_tokens.dart';
import '../../bookmarks/presentation/bookmarks_list.dart';
import '../../quran_text/application/ayah_texts_provider.dart';
import '../../quran_text/application/quran_text_providers.dart';
import '../../quran_text/domain/quran_text.dart';
import '../../settings/application/digits_provider.dart';
import '../application/quran_metadata_provider.dart';
import '../domain/index_search.dart';
import '../domain/quran_metadata.dart';
import '../domain/reader_destination.dart';
import 'index_skeleton.dart';
import 'index_tiles.dart';
import 'surah_info_sheet.dart';

enum _IndexTab { surahs, juz, hizb, sajda, bookmarks }

/// Where the index opens when the reader opens it.
enum IndexOpening {
  /// At the top of the surah list.
  top,

  /// On the surah list, at the surah being read.
  surah,

  /// On the juz list, at the juz being read.
  juz,
}

/// The surah, juz and hizb of the page being read, which the index marks.
typedef _Here = ({int surah, int juz, int hizb});

/// Which surahs the surah list shows.
enum _SurahFilter { all, meccan, medinan }

/// Surah, juz, hizb, sajda and bookmark index. Pops with where to go.
///
/// The five lists are pages of a tab view: swipe between them, or pick one
/// above. The tabs and the search field stay at the top while a list
/// scrolls under them. The surahs can be narrowed to the Meccan or the
/// Medinan ones and put in the order of revelation, and each has a sheet of
/// facts about it.
class QuranIndexPage extends ConsumerStatefulWidget {
  const QuranIndexPage({
    super.key,
    this.sheetScroll,
    this.openOnBookmarks = false,
    this.readerPage,
    this.opening = IndexOpening.top,
  });

  /// Controller supplied when the index is displayed in a draggable sheet.
  final ScrollController? sheetScroll;

  /// Whether the index opens on the bookmarks, as the reader's bookmarks
  /// button asks.
  final bool openOnBookmarks;

  /// The page being read: its surah, juz and hizb are marked in the lists.
  final int? readerPage;

  /// Where the index opens: at the top, or at the reader's surah or juz,
  /// scrolled to it. Only with [readerPage].
  final IndexOpening opening;

  @override
  ConsumerState<QuranIndexPage> createState() => _QuranIndexPageState();
}

class _QuranIndexPageState extends ConsumerState<QuranIndexPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _search = TextEditingController();
  _SurahFilter _filter = _SurahFilter.all;
  bool _byRevelation = false;
  late final TabController _tabs = TabController(
    length: _IndexTab.values.length,
    vsync: this,
    initialIndex: widget.openOnBookmarks
        ? _IndexTab.bookmarks.index
        : widget.opening == IndexOpening.juz
        ? _IndexTab.juz.index
        : _IndexTab.surahs.index,
  )..addListener(_onTab);

  /// The tab the index opened on, the only one scrolled to the reader's place.
  late final int _openedOn = _tabs.index;

  void _onTab() {
    // Rebuild once the tab settles, so the selector follows a swipe.
    if (!_tabs.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTab)
      ..dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searcher = ref.watch(indexSearcherProvider);
    final body = ContentContainer(
      child: searcher.when(
        loading: () => const IndexSkeleton(),
        error: (_, _) => Center(
          child: EmptyState(
            icon: Icons.error_outline,
            title: l10n.indexLoadError,
            message: '',
            actionLabel: l10n.retry,
            onAction: () => ref.invalidate(quranMetadataProvider),
          ),
        ),
        data: (data) {
          final metadata = data.metadata;
          final page = widget.readerPage;
          final _Here? here = page == null
              ? null
              : (
                  surah: metadata.surahAtPage(page).number,
                  juz: metadata.juzOfPage(page).number,
                  hizb: metadata.hizbOf(metadata.ayahsOnPage(page).first),
                );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.sheetScroll != null)
                AppSheetDragArea(
                  child: ListTile(
                    title: Text(l10n.quranIndex),
                    trailing: IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                    ),
                  ),
                ),
              AppSheetDragArea(
                child: _IndexHeader(
                  tab: _IndexTab.values[_tabs.index],
                  controller: _search,
                  onTab: (tab) => _tabs.animateTo(
                    tab.index,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : null,
                  ),
                  onQuery: () => setState(() {}),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    for (final tab in _IndexTab.values)
                      _IndexList(
                        key: PageStorageKey<_IndexTab>(tab),
                        searcher: data,
                        tab: tab,
                        query: _search.text,
                        filter: _filter,
                        byRevelation: _byRevelation,
                        onFilter: (filter) => setState(() => _filter = filter),
                        onByRevelation: (on) =>
                            setState(() => _byRevelation = on),
                        scroll: tab.index == _tabs.index
                            ? widget.sheetScroll
                            : null,
                        inSheet: widget.sheetScroll != null,
                        here: here,
                        openAtHere:
                            widget.opening != IndexOpening.top &&
                            tab.index == _openedOn,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    if (widget.sheetScroll != null) return body;
    return AppPageScaffold(title: l10n.quranIndex, body: body);
  }
}

/// The tabs and the search field, kept above the lists.
class _IndexHeader extends StatelessWidget {
  const _IndexHeader({
    required this.tab,
    required this.controller,
    required this.onTab,
    required this.onQuery,
  });

  final _IndexTab tab;
  final TextEditingController controller;
  final ValueChanged<_IndexTab> onTab;
  final VoidCallback onQuery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final padding = pagePadding(context);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          padding.start,
          padding.top,
          padding.end,
          8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSegmentedControl<_IndexTab>(
              value: tab,
              onChanged: onTab,
              segments: {
                _IndexTab.surahs: l10n.indexSurahs,
                _IndexTab.juz: l10n.indexJuz,
                _IndexTab.hizb: l10n.indexHizb,
                _IndexTab.sajda: l10n.indexSajda,
                _IndexTab.bookmarks: l10n.bookmarks,
              },
            ),
            const SizedBox(height: 12),
            MRETextField(
              controller: controller,
              hintText: l10n.indexSearchHint,
              prefixIcon: const Icon(Icons.search),
              showClearButton: true,
              textInputAction: TextInputAction.search,
              onChanged: (_) => onQuery(),
            ),
          ],
        ),
      ),
    );
  }
}

/// One list of the index, filtered by [query].
class _IndexList extends ConsumerWidget {
  const _IndexList({
    super.key,
    required this.searcher,
    required this.tab,
    required this.query,
    required this.filter,
    required this.byRevelation,
    required this.onFilter,
    required this.onByRevelation,
    required this.scroll,
    required this.inSheet,
    required this.here,
    required this.openAtHere,
  });

  final IndexSearcher searcher;
  final _IndexTab tab;
  final String query;
  final _SurahFilter filter;
  final bool byRevelation;
  final ValueChanged<_SurahFilter> onFilter;
  final ValueChanged<bool> onByRevelation;
  final ScrollController? scroll;
  final bool inSheet;

  /// The reader's place, marked in the list; none when not opened from it.
  final _Here? here;

  /// Whether the list opens scrolled to the reader's place.
  final bool openAtHere;

  /// Whether [line] is the reader's place.
  bool _isHere(_IndexLine line) => switch (line) {
    _SurahRow(:final surah) => surah.number == here?.surah,
    _JuzRow(:final juz) => juz.number == here?.juz,
    _HizbRow(:final hizb) => hizb.number == here?.hizb,
    _ => false,
  };

  /// The surahs the search and the filter leave, in the Mushaf's order or
  /// the order of revelation.
  List<Surah> _surahs() {
    final found = [
      for (final surah in searcher.surahs(query))
        if (switch (filter) {
          _SurahFilter.all => true,
          _SurahFilter.meccan => surah.revelation == Revelation.meccan,
          _SurahFilter.medinan => surah.revelation == Revelation.medinan,
        })
          surah,
    ];
    if (byRevelation) {
      found.sort((a, b) => a.revelationOrder - b.revelationOrder);
    }
    return found;
  }

  /// The lines of this list. Without a search, the surahs and the hizb sit
  /// under the juz they begin in, divided by its heading; a search lists
  /// what it finds.
  List<_IndexLine> _lines() {
    final metadata = searcher.metadata;
    final grouped = query.trim().isEmpty;
    return switch (tab) {
      _IndexTab.surahs => [
        const _SurahFilters(),
        ..._withJuzHeadings<Surah>(
          _surahs(),
          // In the order of revelation the juz no longer follow each other.
          grouped: grouped && !byRevelation,
          juz: (surah) => metadata.juzOf(AyahRef(surah.number, 1)),
          row: _SurahRow.new,
        ),
      ],
      _IndexTab.juz => [for (final juz in searcher.juzs(query)) _JuzRow(juz)],
      _IndexTab.hizb => _withJuzHeadings<Hizb>(
        searcher.hizbs(query),
        grouped: grouped,
        juz: (hizb) => hizb.juz,
        row: _HizbRow.new,
      ),
      _IndexTab.sajda => [
        for (final sajda in searcher.sajdas(query)) _SajdaRow(sajda),
      ],
      // Listed by their own widget.
      _IndexTab.bookmarks => const [],
    };
  }

  /// The first words of the ayah at [ref], as the Mushaf prints them.
  static String? _opening(QuranText? text, AyahRef ref) {
    if (text == null) return null;
    final words = text.mushaf(ref).split(' ');
    return words.length <= _openingWords
        ? words.join(' ')
        : '${words.take(_openingWords).join(' ')} …';
  }

  static const int _openingWords = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final metadata = searcher.metadata;
    final digits = ref.watch(digitsFormatterProvider);
    final padding = pagePadding(context);

    void go(ReaderDestination destination) {
      if (inSheet) {
        Navigator.of(context, rootNavigator: true).pop(destination);
      } else {
        context.pop(destination);
      }
    }

    void open(int page) => go(ReaderDestination(page: page));

    if (tab == _IndexTab.bookmarks) {
      return BookmarksList(
        onOpen: go,
        scroll: scroll,
        surahs: query.trim().isEmpty
            ? null
            : {for (final surah in searcher.surahs(query)) surah.number},
      );
    }
    // The opening words of each juz and hizb, once the text has loaded.
    final text = tab == _IndexTab.juz || tab == _IndexTab.hizb
        ? ref.watch(quranTextProvider).value
        : null;
    final font = text == null ? null : appQuranFont(text);
    final lines = _lines();
    final surahCount = lines.whereType<_SurahRow>().length;

    if (lines.isEmpty || (tab == _IndexTab.surahs && surahCount == 0)) {
      return Column(
        children: [
          if (tab == _IndexTab.surahs)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                padding.start,
                4,
                padding.end,
                0,
              ),
              child: _filterBar(context, metadata, digits),
            ),
          Expanded(child: Center(child: Text(l10n.noResults))),
        ],
      );
    }
    final target = openAtHere && here != null ? lines.indexWhere(_isHere) : -1;
    return _OpensAt(
      scroll: scroll,
      target: target < 0 ? null : target,
      builder: (controller, mark) => ListView.builder(
        controller: controller,
        primary: false,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsetsDirectional.fromSTEB(
          padding.start,
          4,
          padding.end,
          padding.bottom,
        ),
        itemCount: lines.length,
        itemBuilder: (context, index) => mark(index, switch (lines[index]) {
          _SurahFilters() => _filterBar(context, metadata, digits),
          _JuzHeading(:final juz) => IndexSectionHeader(
            title: l10n.juzTitle(digits(juz)),
          ),
          _SurahRow(:final surah) => _rowPadding(
            SurahTile(
              surah: surah,
              current: surah.number == here?.surah,
              digits: digits,
              onTap: () => open(surah.startPage),
              onInfo: () async {
                final read = await showSurahInfo(
                  context,
                  metadata: metadata,
                  surah: surah,
                  digits: digits,
                );
                if (read) open(surah.startPage);
              },
            ),
          ),
          _JuzRow(:final juz) => _rowPadding(
            JuzTile(
              juz: juz,
              current: juz.number == here?.juz,
              surahName: metadata.surah(juz.surah).arabicName,
              digits: digits,
              opening: _opening(text, AyahRef(juz.surah, juz.ayah)),
              openingFont: font,
              onTap: () => open(juz.startPage),
            ),
          ),
          _HizbRow(:final hizb) => _rowPadding(
            HizbTile(
              hizb: hizb,
              current: hizb.number == here?.hizb,
              surahName: metadata.surah(hizb.surah).arabicName,
              digits: digits,
              opening: _opening(text, AyahRef(hizb.surah, hizb.ayah)),
              openingFont: font,
              onTap: () => open(hizb.startPage),
            ),
          ),
          _SajdaRow(:final sajda) => _rowPadding(
            SajdaTile(
              sajda: sajda,
              surahName: metadata.surah(sajda.surah).arabicName,
              juz: metadata.juzOf(AyahRef(sajda.surah, sajda.ayah)),
              digits: digits,
              onTap: () => open(sajda.startPage),
            ),
          ),
        }),
      ),
    );
  }

  static Widget _rowPadding(Widget row) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: row);

  /// All, Meccan or Medinan, each with how many surahs it has, and the
  /// order of revelation.
  Widget _filterBar(
    BuildContext context,
    QuranMetadata metadata,
    String Function(int) digits,
  ) {
    final l10n = context.l10n;
    int count(Revelation kind) =>
        metadata.surahs.where((surah) => surah.revelation == kind).length;
    Widget choice(_SurahFilter value, String label) => ChoiceChip(
      label: Text(label),
      selected: filter == value,
      onSelected: (_) => onFilter(value),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: AppTokens.spaceSmall,
        runSpacing: AppTokens.spaceTiny,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          choice(_SurahFilter.all, l10n.indexFilterAll),
          choice(
            _SurahFilter.meccan,
            l10n.indexFilterCount(
              l10n.revelationMeccan,
              digits(count(Revelation.meccan)),
            ),
          ),
          choice(
            _SurahFilter.medinan,
            l10n.indexFilterCount(
              l10n.revelationMedinan,
              digits(count(Revelation.medinan)),
            ),
          ),
          FilterChip(
            label: Text(l10n.indexSortRevelation),
            selected: byRevelation,
            onSelected: onByRevelation,
          ),
        ],
      ),
    );
  }
}

/// A line of an index list: a juz heading, or an entry.
sealed class _IndexLine {
  const _IndexLine();
}

/// The filters at the top of the surah list.
class _SurahFilters extends _IndexLine {
  const _SurahFilters();
}

class _JuzHeading extends _IndexLine {
  const _JuzHeading(this.juz);

  final int juz;
}

class _SurahRow extends _IndexLine {
  const _SurahRow(this.surah);

  final Surah surah;
}

class _JuzRow extends _IndexLine {
  const _JuzRow(this.juz);

  final Juz juz;
}

class _HizbRow extends _IndexLine {
  const _HizbRow(this.hizb);

  final Hizb hizb;
}

class _SajdaRow extends _IndexLine {
  const _SajdaRow(this.sajda);

  final Sajda sajda;
}

/// [items] as list lines, with a heading before the first item of each juz
/// when [grouped]. A juz none of the items begins in has no heading.
List<_IndexLine> _withJuzHeadings<T>(
  List<T> items, {
  required bool grouped,
  required int Function(T item) juz,
  required _IndexLine Function(T item) row,
}) {
  final lines = <_IndexLine>[];
  int? current;
  for (final item in items) {
    final number = juz(item);
    if (grouped && number != current) {
      current = number;
      lines.add(_JuzHeading(number));
    }
    lines.add(row(item));
  }
  return lines;
}

/// A list that opens with line [target] in sight, a little below the top,
/// instead of at its start. Lines are built lazily and differ in height, so
/// it jumps to an estimate and steps until the line is built, then brings it
/// into view.
class _OpensAt extends StatefulWidget {
  const _OpensAt({
    required this.scroll,
    required this.target,
    required this.builder,
  });

  /// The list's controller when it has one (in a sheet); else the list gets
  /// its own.
  final ScrollController? scroll;

  /// The line to open at; none opens at the top.
  final int? target;

  /// Builds the list with its controller; `mark` wraps each line, so the
  /// target can be found and the built lines are known.
  final Widget Function(
    ScrollController? controller,
    Widget Function(int index, Widget line) mark,
  )
  builder;

  @override
  State<_OpensAt> createState() => _OpensAtState();
}

class _OpensAtState extends State<_OpensAt> {
  final GlobalKey _target = GlobalKey();
  ScrollController? _own;
  int _last = -1;

  /// A line's usual height, for the first jump only.
  static const double _estimate = 96;

  /// How many frames it may step before it settles where it is.
  static const int _steps = 12;

  ScrollController? get _controller => widget.scroll ?? _own;

  @override
  void initState() {
    super.initState();
    final target = widget.target;
    if (target == null) return;
    if (widget.scroll == null) {
      _own = ScrollController(initialScrollOffset: target * _estimate);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _controller;
      if (widget.scroll != null &&
          controller != null &&
          controller.hasClients) {
        final position = controller.position;
        controller.jumpTo(
          (target * _estimate).clamp(0, position.maxScrollExtent).toDouble(),
        );
      }
      _settle(_steps);
    });
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  void _settle(int left) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final found = _target.currentContext;
      if (found != null) {
        Scrollable.ensureVisible(found, alignment: 0.15);
        return;
      }
      final controller = _controller;
      final target = widget.target;
      if (left == 0 || target == null || controller == null) return;
      if (!controller.hasClients) return;
      final position = controller.position;
      final step = position.viewportDimension;
      final next = target > _last
          ? position.pixels + step
          : position.pixels - step;
      controller.jumpTo(next.clamp(0, position.maxScrollExtent).toDouble());
      _settle(left - 1);
    });
  }

  Widget _mark(int index, Widget line) {
    if (index > _last) _last = index;
    return index == widget.target
        ? KeyedSubtree(key: _target, child: line)
        : line;
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller, _mark);
}
