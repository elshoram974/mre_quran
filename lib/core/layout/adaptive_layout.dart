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

/// How the app shell lets people move between tabs, from the window alone.
///
/// A bottom bar up to 839 wide, which covers phones and a portrait iPad (820):
/// a rail beside the content would eat a tenth of a tall page and push the
/// thumb to the far edge. The rail starts where there is room for it beside two
/// pages, and spells out its labels only on the widest windows.
extension ShellNavigation on WindowSize {
  /// Whether tabs sit in a floating bar at the bottom rather than in a rail.
  bool get usesBottomBar => this != WindowSize.expanded;

  /// Widest a floating bar grows; wider windows centre it instead of stretching.
  static const double bottomBarMaxWidth = 560;

  /// Window width from which the rail shows a label beside each icon.
  static const double extendedRailMinWidth = 1100;
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
