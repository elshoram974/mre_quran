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
import 'index_skeleton.dart';
import 'index_tiles.dart';

enum _IndexTab { surahs, juz }

/// Surah and juz index. Pops with the chosen Mushaf page number.
class QuranIndexPage extends ConsumerStatefulWidget {
  const QuranIndexPage({super.key});

  @override
  ConsumerState<QuranIndexPage> createState() => _QuranIndexPageState();
}

class _QuranIndexPageState extends ConsumerState<QuranIndexPage> {
  final TextEditingController _search = TextEditingController();
  _IndexTab _tab = _IndexTab.surahs;

  @override
  void dispose() {
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
          data: (data) => _Loaded(
            searcher: data,
            tab: _tab,
            controller: _search,
            onTab: (tab) => setState(() => _tab = tab),
            onQuery: () => setState(() {}),
          ),
        ),
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({
    required this.searcher,
    required this.tab,
    required this.controller,
    required this.onTab,
    required this.onQuery,
  });

  final IndexSearcher searcher;
  final _IndexTab tab;
  final TextEditingController controller;
  final ValueChanged<_IndexTab> onTab;
  final VoidCallback onQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final metadata = searcher.metadata;
    final digits = ref.watch(digitsFormatterProvider);
    final padding = pagePadding(context);
    final surahs = tab == _IndexTab.surahs
        ? searcher.surahs(controller.text)
        : const <Surah>[];
    final juzs = tab == _IndexTab.juz
        ? searcher.juzs(controller.text)
        : const <Juz>[];
    final count = tab == _IndexTab.surahs ? surahs.length : juzs.length;

    void open(int page) => context.pop(page);

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(
            padding.start,
            padding.top,
            padding.end,
            8,
          ),
          sliver: SliverList.list(
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
        if (count == 0)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(l10n.noResults)),
          )
        else
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              padding.start,
              4,
              padding.end,
              padding.bottom,
            ),
            sliver: SliverList.builder(
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
            ),
          ),
      ],
    );
  }
}
