import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../quran_index/domain/quran_metadata.dart';
import 'reader_page_labels.dart';

/// The room around a Mushaf page, shared by the typeset and the printed
/// reader: a narrow side margin, and fixed room above and below where the
/// page's own labels (surah, juz, page number) sit, so they never cover the
/// text. The labels belong to the page, so they turn with it.
class MushafPageFrame extends StatelessWidget {
  /// Creates the frame around [child].
  const MushafPageFrame({
    super.key,
    required this.metadata,
    required this.page,
    required this.onTap,
    required this.child,
  });

  /// Quran structure, for the labels.
  final QuranMetadata metadata;

  /// Page number, 1–604.
  final int page;

  /// Called when the page is tapped.
  final VoidCallback onTap;

  /// The page body.
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppTokens.readerHeaderExtent,
              bottom: AppTokens.readerFooterExtent,
              start: AppTokens.readerGutter,
              end: AppTokens.readerGutter,
            ),
            child: child,
          ),
        ),
        Positioned.fill(
          child: ReaderPageLabels(metadata: metadata, page: page),
        ),
      ],
    ),
  );
}
