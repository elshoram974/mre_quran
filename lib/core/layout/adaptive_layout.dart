import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum WindowSize {
  compact,
  medium,
  expanded;

  static WindowSize fromWidth(double width) => switch (width) {
    < 600 => compact,
    < 840 => medium,
    _ => expanded,
  };
}

class ContentContainer extends StatelessWidget {
  const ContentContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960),
      child: child,
    ),
  );
}

/// Scroll padding for pages inside the glass shell.
///
/// Adds the width-based gutter and the system and floating-bar insets that the
/// shell publishes through [MediaQuery.paddingOf].
EdgeInsetsDirectional pagePadding(BuildContext context) {
  final media = MediaQuery.of(context);
  final gutter = WindowSize.fromWidth(media.size.width) == WindowSize.compact
      ? AppTokens.gutterCompact
      : AppTokens.gutterWide;
  return EdgeInsetsDirectional.fromSTEB(
    gutter,
    media.padding.top + 16,
    gutter,
    media.padding.bottom + 16,
  );
}
