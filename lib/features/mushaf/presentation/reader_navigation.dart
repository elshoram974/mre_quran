import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../quran_index/domain/reader_destination.dart';
import '../../quran_index/presentation/quran_index_page.dart';
import '../application/highlighted_ayah_provider.dart';
import '../application/reading_position_provider.dart';

/// Opens the index or search over the reader and, when the person picks a
/// place, goes there and highlights the ayah if one was chosen.
Future<void> openReaderRoute(
  BuildContext context,
  WidgetRef ref,
  AppRoute route,
) async {
  final chosen = route == AppRoute.quranIndex
      // The index rises all the way, under the status bar, from the surah's
      // name: it is a long list, read better whole.
      ? await AppSheet.showFilling<ReaderDestination>(
          context: context,
          initialSize: 1,
          builder: (_, scroll) => QuranIndexPage(sheetScroll: scroll),
        )
      : await context.push<ReaderDestination>(route.path);
  if (chosen == null || !context.mounted) return;
  await _go(ref, chosen);
}

/// Opens the index on the bookmarks, over the reader, and goes where the
/// person picks.
Future<void> openReaderBookmarks(BuildContext context, WidgetRef ref) async {
  final chosen = await AppSheet.showFilling<ReaderDestination>(
    context: context,
    initialSize: 1,
    builder: (_, scroll) =>
        QuranIndexPage(sheetScroll: scroll, openOnBookmarks: true),
  );
  if (chosen == null || !context.mounted) return;
  await _go(ref, chosen);
}

Future<void> _go(WidgetRef ref, ReaderDestination chosen) async {
  final highlight = ref.read(highlightedAyahProvider.notifier);
  if (chosen.ayah == null) {
    highlight.clear();
  } else {
    highlight.show(chosen.ayah!);
  }
  await ref.read(readingPositionProvider.notifier).setPage(chosen.page);
}

/// Goes to [page] and clears the ayah highlight.
void goToReaderPage(WidgetRef ref, int page) {
  ref.read(highlightedAyahProvider.notifier).clear();
  ref.read(readingPositionProvider.notifier).setPage(page);
}
