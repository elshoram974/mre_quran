import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../mushaf/application/highlighted_ayah_provider.dart';
import '../../mushaf/application/reading_position_provider.dart';
import '../../quran_text/application/quran_text_providers.dart';
import '../../quran_text/presentation/ayah_result_tile.dart';
import '../../settings/application/digits_provider.dart';
import '../application/bookmarks_provider.dart';

/// The reader's bookmarks, newest first. Tapping one opens its page.
class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bookmarks = ref.watch(bookmarksProvider);
    final text = ref.watch(quranTextProvider);
    final digits = ref.watch(digitsFormatterProvider);

    final items = bookmarks.value;
    final quran = text.value;
    if (bookmarks.hasError || text.hasError) {
      return EmptyState(
        icon: Icons.error_outline,
        title: l10n.readerLoadError,
        message: '',
        actionLabel: l10n.retry,
        onAction: () {
          ref
            ..invalidate(bookmarksProvider)
            ..invalidate(quranTextDataProvider);
        },
      );
    }
    if (items == null || quran == null) {
      return Padding(
        padding: pagePadding(context),
        child: AppShimmer(
          child: Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                const SkeletonBox(height: 110),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.bookmark_border,
        title: l10n.noBookmarksTitle,
        message: l10n.noBookmarksBody,
      );
    }

    final sorted = [...items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final metadata = quran.metadata;
    return ListView.builder(
      padding: pagePadding(context),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final bookmark = sorted[index];
        final ref0 = bookmark.ref;
        final page = metadata.pageOf(ref0.surah, ref0.ayah);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Dismissible(
            key: ValueKey(ref0),
            background: ColoredBox(
              color: Theme.of(context).colorScheme.errorContainer,
            ),
            onDismissed: (_) =>
                ref.read(bookmarksProvider.notifier).remove(ref0),
            child: AyahResultTile(
              surahName: metadata.surah(ref0.surah).arabicName,
              ayahNumber: digits(ref0.ayah),
              page: digits(page),
              text: quran.uthmani(ref0),
              onTap: () async {
                ref.read(highlightedAyahProvider.notifier).show(ref0);
                await ref.read(readingPositionProvider.notifier).setPage(page);
                if (context.mounted) context.go(AppRoute.reader.path);
              },
            ),
          ),
        );
      },
    );
  }
}
