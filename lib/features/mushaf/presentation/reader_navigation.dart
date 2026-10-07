import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../quran_index/domain/reader_destination.dart';
import '../application/highlighted_ayah_provider.dart';
import '../application/reading_position_provider.dart';

/// Opens the index or search over the reader and, when the person picks a
/// place, goes there and highlights the ayah if one was chosen.
Future<void> openReaderRoute(
  BuildContext context,
  WidgetRef ref,
  AppRoute route,
) async {
  final chosen = await context.push<ReaderDestination>(route.path);
  if (chosen == null) return;
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
