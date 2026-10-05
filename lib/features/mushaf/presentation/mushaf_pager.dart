import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../quran_text/domain/quran_text.dart';
import '../../settings/application/settings_provider.dart';
import '../application/reader_immersive_provider.dart';
import '../application/reading_position_provider.dart';
import 'mushaf_page_view.dart';

/// Swipeable Mushaf pages, right to left like a printed Mushaf.
///
/// Opens at the saved page, saves every page turn, and follows page changes
/// made elsewhere (index, search).
class MushafPager extends ConsumerStatefulWidget {
  /// Creates the pager over [text], opening at [initialPage].
  const MushafPager({super.key, required this.text, required this.initialPage});

  /// The verified text.
  final QuranText text;

  /// Page to open at, 1–604.
  final int initialPage;

  @override
  ConsumerState<MushafPager> createState() => _MushafPagerState();
}

class _MushafPagerState extends ConsumerState<MushafPager> {
  late final PageController _controller = PageController(
    initialPage: widget.initialPage - 1,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(readingPositionProvider, (_, next) {
      final page = next.value;
      if (page == null || !_controller.hasClients) return;
      if ((_controller.page?.round() ?? -1) != page - 1) {
        _controller.jumpToPage(page - 1);
      }
    });
    final fontScale = ref.watch(
      settingsProvider.select((s) => s.value?.readerFontScale ?? 1),
    );
    return Directionality(
      // The Mushaf turns right to left in every app language.
      textDirection: TextDirection.rtl,
      child: PageView.builder(
        controller: _controller,
        allowImplicitScrolling: true,
        itemCount: widget.text.metadata.pageCount,
        onPageChanged: (index) =>
            ref.read(readingPositionProvider.notifier).setPage(index + 1),
        itemBuilder: (context, index) => RepaintBoundary(
          child: MushafPageView(
            key: ValueKey<int>(index),
            text: widget.text,
            page: index + 1,
            fontScale: fontScale,
            onTap: () => ref.read(readerImmersiveProvider.notifier).toggle(),
          ),
        ),
      ),
    );
  }
}
