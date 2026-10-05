import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../quran_text/application/quran_text_providers.dart';
import '../../settings/application/digits_provider.dart';
import '../../quran_index/domain/reader_destination.dart';
import '../application/highlighted_ayah_provider.dart';
import '../application/reader_immersive_provider.dart';
import '../application/reading_position_provider.dart';
import 'display_options_sheet.dart';
import 'mushaf_pager.dart';
import 'reader_bar.dart';

/// The Mushaf tab: the pages themselves, with a bar for the index, search,
/// and display options. A tap on the page hides or shows the bars.
class MushafPage extends ConsumerWidget {
  const MushafPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = ref.watch(quranTextProvider);
    final page = ref.watch(readingPositionProvider).value;
    final immersive = ref.watch(readerImmersiveProvider);
    final media = MediaQuery.of(context);

    Future<void> open(AppRoute route) async {
      final chosen = await context.push<ReaderDestination>(route.path);
      if (chosen != null) {
        final highlight = ref.read(highlightedAyahProvider.notifier);
        if (chosen.ayah == null) {
          highlight.clear();
        } else {
          highlight.show(chosen.ayah!);
        }
        await ref.read(readingPositionProvider.notifier).setPage(chosen.page);
      }
    }

    if (text.hasError) {
      return EmptyState(
        icon: Icons.error_outline,
        title: l10n.readerLoadError,
        message: '',
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(quranTextDataProvider),
      );
    }
    final data = text.value;
    if (data == null || page == null) return const _ReaderSkeleton();

    final metadata = data.metadata;
    final digits = ref.watch(digitsFormatterProvider);
    final surah = metadata.surahAtPage(page);
    final juz = metadata.juzOfPage(page);
    final bar = ReaderBar(
      title: l10n.surahTitle(surah.arabicName),
      subtitle:
          '${l10n.juzTitle(digits(juz.number))} · ${l10n.pageNumber(digits(page))}',
      menuTooltip: l10n.readerMenu,
      onMenu: () => open(AppRoute.quranIndex),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: l10n.searchQuran,
          onPressed: () => open(AppRoute.quranSearch),
        ),
        IconButton(
          icon: const Icon(Icons.text_format),
          tooltip: l10n.displayOptions,
          onPressed: () => showDisplayOptions(context),
        ),
      ],
    );

    // The page keeps one size: it fills the screen inside the system insets,
    // and the bars slide over it. Hiding them never re-lays out the page.
    final safe = media.viewPadding;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                top: safe.top,
                bottom: safe.bottom,
              ),
              child: MushafPager(text: data, initialPage: page),
            ),
          ),
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: IgnorePointer(
              ignoring: immersive,
              child: AnimatedSlide(
                offset: immersive ? const Offset(0, -1) : Offset.zero,
                duration: duration,
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: immersive ? 0 : 1,
                  duration: duration,
                  child: bar,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderSkeleton extends StatelessWidget {
  const _ReaderSkeleton();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: AppShimmer(
        child: Column(
          children: [
            const SkeletonBox(height: 48),
            const SizedBox(height: 24),
            for (var i = 0; i < 9; i++) ...[
              const SkeletonBox(height: 22),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    ),
  );
}
