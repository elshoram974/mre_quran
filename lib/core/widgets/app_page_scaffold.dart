import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../l10n/l10n.dart';
import '../theme/app_platform.dart';
import '../theme/app_tokens.dart';

/// Scaffold for screens pushed on top of the tab shell.
///
/// iOS gets a glass app bar with a glass back button. Android gets a Material
/// 3 top app bar. Content is padded below the bar on iOS, so scroll views
/// should pad with `pagePadding(context)`.
class AppPageScaffold extends StatelessWidget {
  /// Creates a scaffold titled [title].
  const AppPageScaffold({super.key, required this.title, required this.body});

  /// Bar title.
  final String title;

  /// Page content.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    if (!context.isCupertino) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: body,
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: GlassScaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: GlassAppBar(
          title: Text(title),
          leading: GlassButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            label: context.l10n.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: GlassInsetBody(compact: false, child: body),
      ),
    );
  }
}

/// Publishes the floating glass bar heights through [MediaQuery.padding] so
/// pages can pad their content with `pagePadding`.
class GlassInsetBody extends StatelessWidget {
  /// Creates the wrapper. [compact] also reserves room for the tab bar.
  const GlassInsetBody({super.key, required this.compact, required this.child});

  /// Whether a floating bottom tab bar is shown.
  final bool compact;

  /// Page content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(
          top: media.padding.top + AppTokens.appBarHeight,
          bottom: media.padding.bottom + (compact ? AppTokens.barClearance : 0),
        ),
      ),
      child: child,
    );
  }
}
