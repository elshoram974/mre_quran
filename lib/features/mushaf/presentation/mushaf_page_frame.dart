import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_tokens.dart';
import '../../quran_index/domain/quran_metadata.dart';
import 'reader_page_labels.dart';

/// The room around a Mushaf page, shared by the typeset and the printed
/// reader: a narrow side margin, and, for a page with [labels], fixed room
/// above and below where the page's own labels (surah, juz, page number)
/// sit, so they never cover the text. The labels belong to the page, so
/// they turn with it.
class MushafPageFrame extends StatelessWidget {
  /// Creates the frame around [child].
  const MushafPageFrame({
    super.key,
    required this.metadata,
    required this.page,
    required this.onTap,
    required this.child,
    this.spread = false,
    this.gutter = AppTokens.readerGutter,
    this.labels = true,
  });

  /// Quran structure, for the labels.
  final QuranMetadata metadata;

  /// Page number, 1–604.
  final int page;

  /// Called when the page is tapped.
  final VoidCallback onTap;

  /// The page body.
  final Widget child;

  /// Margin at each side of the page body.
  final double gutter;

  /// Whether the page carries its own labels, with room kept for them
  /// above and below. Without them the body runs almost from top to bottom.
  final bool labels;

  /// Whether this page faces another. Its onward arrow then only shows on the
  /// outer edge.
  final bool spread;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: labels
                  ? AppTokens.readerHeaderExtent
                  : AppTokens.readerEdgePrinted,
              bottom: labels
                  ? AppTokens.readerFooterExtent
                  : AppTokens.readerEdgePrinted,
              start: gutter,
              end: gutter,
            ),
            child: child,
          ),
        ),
        if (labels)
          Positioned.fill(
            child: ReaderPageLabels(
              metadata: metadata,
              page: page,
              spread: spread,
            ),
          ),
      ],
    ),
  );
}
