import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bookmarks/application/bookmarks_provider.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/domain/quran_text.dart';
import '../../settings/application/settings_provider.dart';
import '../application/reader_immersive_provider.dart';
import '../application/reading_position_provider.dart';
import 'ayah_actions_sheet.dart';
import 'mushaf_page_view.dart';

/// Window width from which two pages are shown side by side.
const double mushafSpreadMinWidth = 700;

/// Swipeable Mushaf pages, right to left like a printed Mushaf.
///
/// Wide windows show a two-page spread like an open book: an odd page on the
/// right and the even page on its left, page 1 alone on the right. Narrow
/// windows show one page. The pager opens at the saved page, saves every turn,
/// and follows page changes made elsewhere (index, search, bookmarks).
class MushafPager extends StatelessWidget {
  /// Creates the pager over [text], opening at [initialPage].
  const MushafPager({super.key, required this.text, required this.initialPage});

  /// The verified text.
  final QuranText text;

  /// Page to open at, 1–604.
  final int initialPage;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final spread = constraints.maxWidth >= mushafSpreadMinWidth;
      return _PagerBody(
        key: ValueKey<bool>(spread),
        text: text,
        spread: spread,
        initialPage: initialPage,
      );
    },
  );
}

class _PagerBody extends ConsumerStatefulWidget {
  const _PagerBody({
    super.key,
    required this.text,
    required this.spread,
    required this.initialPage,
  });

  final QuranText text;
  final bool spread;
  final int initialPage;

  @override
  ConsumerState<_PagerBody> createState() => _PagerBodyState();
}

class _PagerBodyState extends ConsumerState<_PagerBody> {
  late final PageController _controller = PageController(
    initialPage: _indexOfPage(widget.initialPage),
  );
  AyahRef? _selected;

  int get _pageCount => widget.text.metadata.pageCount;

  /// Pager index of [page]. Spreads pair an odd page on the right with the
  /// even page before it, so page 1 is spread 0 and pages 2 and 3 are spread 1.
  int _indexOfPage(int page) => widget.spread ? page ~/ 2 : page - 1;

  /// The page saved when the pager rests on [index]: the right-hand page.
  int _pageOfIndex(int index) =>
      widget.spread ? (2 * index + 1).clamp(1, _pageCount) : index + 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showActions(AyahRef ayah) async {
    setState(() => _selected = ayah);
    await showAyahActions(context, widget.text, ayah);
    if (mounted) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(readingPositionProvider, (_, next) {
      final page = next.value;
      if (page == null || !_controller.hasClients) return;
      final target = _indexOfPage(page);
      if ((_controller.page?.round() ?? -1) != target) {
        _controller.jumpToPage(target);
      }
    });
    final fontScale = ref.watch(
      settingsProvider.select((s) => s.value?.readerFontScale ?? 1),
    );
    final bookmarked = ref.watch(bookmarkedRefsProvider);

    Widget pageView(int page) => MushafPageView(
      key: ValueKey<int>(page),
      text: widget.text,
      page: page,
      fontScale: fontScale,
      bookmarked: bookmarked,
      selected: _selected,
      onAyahLongPress: _showActions,
      onTap: () => ref.read(readerImmersiveProvider.notifier).toggle(),
    );

    final count = widget.spread ? _pageCount ~/ 2 + 1 : _pageCount;
    return Directionality(
      // The Mushaf turns right to left in every app language.
      textDirection: TextDirection.rtl,
      child: PageView.builder(
        controller: _controller,
        allowImplicitScrolling: true,
        itemCount: count,
        onPageChanged: (index) => ref
            .read(readingPositionProvider.notifier)
            .setPage(_pageOfIndex(index)),
        itemBuilder: (context, index) {
          if (!widget.spread) {
            return RepaintBoundary(child: pageView(index + 1));
          }
          final right = 2 * index + 1;
          final left = 2 * index;
          return RepaintBoundary(
            child: Row(
              children: [
                Expanded(
                  child: right <= _pageCount
                      ? pageView(right)
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: left >= 1 ? pageView(left) : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
