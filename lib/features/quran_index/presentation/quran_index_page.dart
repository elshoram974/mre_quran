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
import '../../settings/application/digits_provider.dart';
import '../application/quran_metadata_provider.dart';
import '../domain/index_search.dart';
import '../domain/quran_metadata.dart';
import '../domain/reader_destination.dart';
import 'index_skeleton.dart';
import 'index_tiles.dart';

enum _IndexTab { surahs, juz, hizb, sajda }

/// Surah, juz, hizb and sajda index. Pops with the chosen Mushaf page number.
///
/// The four lists are pages of a tab view: swipe between them, or pick one
/// above. The tabs and the search field stay at the top while a list
/// scrolls under them.
class QuranIndexPage extends ConsumerStatefulWidget {
  const QuranIndexPage({super.key, this.sheetScroll});

  /// Controller supplied when the index is displayed in a draggable sheet.
  final ScrollController? sheetScroll;

  @override
  ConsumerState<QuranIndexPage> createState() => _QuranIndexPageState();
}

class _QuranIndexPageState extends ConsumerState<QuranIndexPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _search = TextEditingController();
  late final TabController _tabs = TabController(
    length: _IndexTab.values.length,
    vsync: this,
  )..addListener(_onTab);

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
        data: (data) => Column(
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
                      scroll: tab.index == _tabs.index
                          ? widget.sheetScroll
                          : null,
                      inSheet: widget.sheetScroll != null,
                    ),
                ],
              ),
            ),
          ],
        ),
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
    required this.scroll,
    required this.inSheet,
  });

  final IndexSearcher searcher;
  final _IndexTab tab;
  final String query;
  final ScrollController? scroll;
  final bool inSheet;

  /// The lines of this list. Without a search, the surahs and the hizb sit
  /// under the juz they begin in, divided by its heading; a search lists
  /// what it finds.
  List<_IndexLine> _lines() {
    final metadata = searcher.metadata;
    final grouped = query.trim().isEmpty;
    return switch (tab) {
      _IndexTab.surahs => _withJuzHeadings<Surah>(
        searcher.surahs(query),
        grouped: grouped,
        juz: (surah) => metadata.juzOf(AyahRef(surah.number, 1)),
        row: _SurahRow.new,
      ),
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
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final metadata = searcher.metadata;
    final digits = ref.watch(digitsFormatterProvider);
    final padding = pagePadding(context);
    final lines = _lines();

    void open(int page) {
      final destination = ReaderDestination(page: page);
      if (inSheet) {
        Navigator.of(context, rootNavigator: true).pop(destination);
      } else {
        context.pop(destination);
      }
    }

    if (lines.isEmpty) return Center(child: Text(l10n.noResults));
    return ListView.builder(
      controller: scroll,
      primary: false,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsetsDirectional.fromSTEB(
        padding.start,
        4,
        padding.end,
        padding.bottom,
      ),
      itemCount: lines.length,
      itemBuilder: (context, index) => switch (lines[index]) {
        _JuzHeading(:final juz) => IndexSectionHeader(
          title: l10n.juzTitle(digits(juz)),
        ),
        _SurahRow(:final surah) => _rowPadding(
          SurahTile(
            surah: surah,
            digits: digits,
            onTap: () => open(surah.startPage),
          ),
        ),
        _JuzRow(:final juz) => _rowPadding(
          JuzTile(
            juz: juz,
            surahName: metadata.surah(juz.surah).arabicName,
            digits: digits,
            onTap: () => open(juz.startPage),
          ),
        ),
        _HizbRow(:final hizb) => _rowPadding(
          HizbTile(
            hizb: hizb,
            surahName: metadata.surah(hizb.surah).arabicName,
            digits: digits,
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
      },
    );
  }

  static Widget _rowPadding(Widget row) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: row);
}

/// A line of an index list: a juz heading, or an entry.
sealed class _IndexLine {
  const _IndexLine();
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
