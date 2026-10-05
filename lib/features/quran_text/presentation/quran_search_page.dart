import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_fields/mre_fields.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../quran_index/presentation/index_tiles.dart';
import '../../settings/application/digits_provider.dart';
import '../application/quran_text_providers.dart';
import '../domain/ayah_search.dart';
import '../domain/quran_search.dart';
import '../domain/quran_text.dart';
import 'ayah_result_tile.dart';

/// Search by surah, ayah, or words. Pops with the chosen Mushaf page number.
class QuranSearchPage extends ConsumerStatefulWidget {
  const QuranSearchPage({super.key});

  @override
  ConsumerState<QuranSearchPage> createState() => _QuranSearchPageState();
}

class _QuranSearchPageState extends ConsumerState<QuranSearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.l10n.searchQuran,
      body: ContentContainer(
        child: Builder(builder: (context) => _body(context)),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    final padding = pagePadding(context);
    final search = ref.watch(quranSearchProvider);
    return Column(
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            padding.start,
            padding.top,
            padding.end,
            8,
          ),
          child: MRETextField(
            controller: _controller,
            autofocus: true,
            hintText: l10n.searchQuranHint,
            prefixIcon: const Icon(Icons.search),
            showClearButton: true,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: search.when(
            loading: () => const _Skeleton(),
            error: (_, _) => EmptyState(
              icon: Icons.error_outline,
              title: l10n.searchLoadError,
              message: '',
              actionLabel: l10n.retry,
              onAction: () => ref.invalidate(quranTextDataProvider),
            ),
            data: (data) => _Results(
              outcome: data.outcome(_controller.text),
              empty: _controller.text.trim().isEmpty,
              text: data.ayahs.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({
    required this.outcome,
    required this.empty,
    required this.text,
  });

  final QuranSearchOutcome outcome;
  final bool empty;
  final QuranText text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final digits = ref.watch(digitsFormatterProvider);
    final padding = pagePadding(context);
    if (empty) {
      return EmptyState(
        icon: Icons.manage_search,
        title: l10n.searchPromptTitle,
        message: l10n.searchPromptBody,
      );
    }
    if (outcome.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: l10n.searchNoResultsTitle,
        message: l10n.searchNoResultsBody,
      );
    }
    final metadata = text.metadata;
    final matches = outcome.text.matches;
    final goTo = outcome.direct != null || outcome.surahs.isNotEmpty;

    Widget ayahTile(AyahMatch match) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AyahResultTile(
        surahName: metadata.surah(match.ref.surah).arabicName,
        ayahNumber: digits(match.ref.ayah),
        page: digits(match.page),
        text: text.uthmani(match.ref),
        onTap: () => context.pop(match.page),
      ),
    );

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(
            padding.start,
            8,
            padding.end,
            padding.bottom,
          ),
          sliver: SliverList.list(
            children: [
              if (goTo) _Header(l10n.searchGoTo),
              if (outcome.direct != null) ayahTile(outcome.direct!),
              for (final surah in outcome.surahs)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: SurahTile(
                    surah: surah,
                    digits: digits,
                    onTap: () => context.pop(surah.startPage),
                  ),
                ),
              if (matches.isNotEmpty) ...[
                _Header(
                  '${l10n.searchTextResults} · '
                  '${l10n.searchTextCount(outcome.text.total, digits(outcome.text.total))}',
                ),
                for (final match in matches) ayahTile(match),
                if (outcome.text.total > matches.length)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.searchShowingFirst(
                        digits(matches.length),
                        digits(outcome.text.total),
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(4, 14, 4, 6),
    child: Semantics(
      header: true,
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final padding = pagePadding(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(padding.start, 8, padding.end, 0),
      child: AppShimmer(
        child: Column(
          children: [
            for (var i = 0; i < 5; i++) ...[
              const SkeletonBox(height: 96),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}
