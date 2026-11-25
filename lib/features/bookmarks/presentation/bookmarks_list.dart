import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_index/domain/reader_destination.dart';
import '../../quran_text/application/ayah_texts_provider.dart';
import '../../quran_text/application/quran_text_providers.dart';
import '../../quran_text/presentation/ayah_result_tile.dart';
import '../../settings/application/digits_provider.dart';
import '../application/bookmarks_provider.dart';

/// The bookmarked ayahs, newest first, as a section of the index. A tap opens
/// one where it is in the Mushaf; a swipe removes it.
class BookmarksList extends ConsumerWidget {
  /// Creates the list. [surahs], when given, keeps only the bookmarks in those
  /// surahs (what the index's search found).
  const BookmarksList({
    super.key,
    required this.onOpen,
    this.surahs,
    this.scroll,
  });

  /// Called with where the chosen bookmark is.
  final ValueChanged<ReaderDestination> onOpen;

  /// The surahs to keep, by number; all when null.
  final Set<int>? surahs;

  /// The sheet's scroll controller, when the index is in a sheet.
  final ScrollController? scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bookmarks = ref.watch(bookmarksProvider);
    final text = ref.watch(quranTextProvider);
    final digits = ref.watch(digitsFormatterProvider);
    final padding = pagePadding(context);

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
        padding: padding,
        child: AppShimmer(
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                const SkeletonBox(height: 110),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      );
    }
    final kept = [
      for (final bookmark in items)
        if (surahs?.contains(bookmark.ref.surah) ?? true) bookmark,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (kept.isEmpty) {
      if (surahs != null) return Center(child: Text(l10n.noResults));
      return EmptyState(
        icon: Icons.bookmark_border,
        title: l10n.noBookmarksTitle,
        message: l10n.noBookmarksBody,
      );
    }

    final metadata = quran.metadata;
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
      itemCount: kept.length,
      itemBuilder: (context, index) {
        final AyahRef ayah = kept[index].ref;
        final page = metadata.pageOf(ayah.surah, ayah.ayah);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Dismissible(
            key: ValueKey(ayah),
            background: ColoredBox(
              color: Theme.of(context).colorScheme.errorContainer,
            ),
            onDismissed: (_) =>
                ref.read(bookmarksProvider.notifier).remove(ayah),
            child: AyahResultTile(
              surahName: metadata.surah(ayah.surah).arabicName,
              ayahNumber: digits(ayah.ayah),
              page: digits(page),
              text: quran.mushaf(ayah),
              fontFamily: appQuranFont(quran),
              onTap: () => onOpen(ReaderDestination(page: page, ayah: ayah)),
            ),
          ),
        );
      },
    );
  }
}
