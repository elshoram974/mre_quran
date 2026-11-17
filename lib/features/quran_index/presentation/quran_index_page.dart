import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_fields/mre_fields.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/empty_state.dart';
import '../../settings/application/digits_provider.dart';
import '../application/quran_metadata_provider.dart';
import '../domain/index_search.dart';
import '../domain/quran_metadata.dart';
import '../domain/reader_destination.dart';
import 'index_skeleton.dart';
import 'index_tiles.dart';

enum _IndexTab { surahs, juz }

/// Surah and juz index. Pops with the chosen Mushaf page number.
///
/// The two lists are pages of a tab view: swipe between them, or pick one
/// above. The tabs and the search field stay at the top while a list
/// scrolls under them.
class QuranIndexPage extends ConsumerStatefulWidget {
  const QuranIndexPage({super.key});

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
    return AppPageScaffold(
      title: l10n.quranIndex,
      body: ContentContainer(
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
              _IndexHeader(
                tab: _IndexTab.values[_tabs.index],
                controller: _search,
                onTab: (tab) => _tabs.animateTo(tab.index),
                onQuery: () => setState(() {}),
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
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  });

  final IndexSearcher searcher;
  final _IndexTab tab;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final metadata = searcher.metadata;
    final digits = ref.watch(digitsFormatterProvider);
    final padding = pagePadding(context);
    final surahs = tab == _IndexTab.surahs
        ? searcher.surahs(query)
        : const <Surah>[];
    final juzs = tab == _IndexTab.juz ? searcher.juzs(query) : const <Juz>[];
    final count = tab == _IndexTab.surahs ? surahs.length : juzs.length;

    void open(int page) => context.pop(ReaderDestination(page: page));

    if (count == 0) return Center(child: Text(l10n.noResults));
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsetsDirectional.fromSTEB(
        padding.start,
        4,
        padding.end,
        padding.bottom,
      ),
      itemCount: count,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: tab == _IndexTab.surahs
            ? SurahTile(
                surah: surahs[index],
                digits: digits,
                onTap: () => open(surahs[index].startPage),
              )
            : JuzTile(
                juz: juzs[index],
                surahName: metadata.surah(juzs[index].surah).arabicName,
                digits: digits,
                onTap: () => open(juzs[index].startPage),
              ),
      ),
    );
  }
}
