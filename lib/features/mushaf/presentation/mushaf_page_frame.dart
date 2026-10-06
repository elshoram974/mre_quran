import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// The room around a Mushaf page, shared by the typeset and the printed
/// reader: a narrow side margin, and fixed room above and below where the
/// reader's header chips and page-number chip sit, so they never cover the
/// text and the page never moves when they change.
class MushafPageFrame extends StatelessWidget {
  /// Creates the frame around [child].
  const MushafPageFrame({super.key, required this.onTap, required this.child});

  /// Called when the page is tapped.
  final VoidCallback onTap;

  /// The page body.
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppTokens.readerHeaderExtent,
        bottom: AppTokens.readerFooterExtent,
        start: AppTokens.readerGutter,
        end: AppTokens.readerGutter,
      ),
      child: child,
    ),
  );
}
