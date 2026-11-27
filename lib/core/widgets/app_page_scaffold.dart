import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../l10n/l10n.dart';
import '../theme/app_platform.dart';
import '../theme/app_tokens.dart';

/// Scaffold for screens pushed on top of the tab shell.
///
/// iOS gets a glass app bar with a glass back button. Android gets a Material
/// 3 top app bar. Content is padded below the bar on iOS, so scroll views
/// should pad with `pagePadding(context)`.
///
/// A page that draws itself before its data has arrived says so in the bar
/// with [loading] (`docs/UI_RULES.md`, section 5).
class AppPageScaffold extends StatelessWidget {
  /// Creates a scaffold titled [title].
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.loading = false,
  });

  /// Bar title.
  final String title;

  /// Page content.
  final Widget body;

  /// Whether the page is still waiting for what it shows. The bar says so in
  /// each platform's own way, a thin line along its bottom edge on Android
  /// and a spinner at its end on iOS, without moving anything, and screen
  /// readers announce it. A wait shorter than [AppTokens.loaderDelay] shows
  /// nothing.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (!context.isCupertino) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          // Stacked behind the toolbar and outside its layout, so the title
          // stays where it is when the line comes and goes.
          flexibleSpace: loading ? const _BarLoading() : null,
        ),
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
            icon: const BackButtonIcon(),
            label: context.l10n.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          // The glass bar centres its title on its whole width, so a spinner
          // in the trailing slot does not move it either.
          actions: loading ? const [_BarLoading()] : null,
        ),
        body: GlassInsetBody(compact: false, hasAppBar: true, child: body),
      ),
    );
  }
}

/// The bar's sign that the page is loading: Material's thin line along the
/// bar's bottom edge, or the glass kit's spinner where iOS puts a bar button.
/// It waits [AppTokens.loaderDelay] before showing, so a quick load shows no
/// loader at all, and it takes the same room shown or not.
class _BarLoading extends StatefulWidget {
  const _BarLoading();

  @override
  State<_BarLoading> createState() => _BarLoadingState();
}

class _BarLoadingState extends State<_BarLoading> {
  late final Timer _delay;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _delay = Timer(AppTokens.loaderDelay, () => setState(() => _shown = true));
  }

  @override
  void dispose() {
    _delay.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.loading;
    if (!context.isCupertino) {
      return Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: _shown
            ? Semantics(
                liveRegion: true,
                child: LinearProgressIndicator(
                  minHeight: AppTokens.barProgressHeight,
                  semanticsLabel: label,
                ),
              )
            : null,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: AppTokens.appBarHeight,
      child: _shown
          ? Center(
              child: Semantics(
                liveRegion: true,
                child: GlassProgressIndicator.circular(
                  color: scheme.primary,
                  backgroundColor: scheme.surfaceContainerHighest,
                  semanticLabel: label,
                ),
              ),
            )
          : null,
    );
  }
}

/// Publishes the floating glass bar heights through [MediaQuery.padding] so
/// pages can pad their content with `pagePadding`.
class GlassInsetBody extends StatelessWidget {
  /// Creates the wrapper. [compact] also reserves room for the tab bar.
  const GlassInsetBody({
    super.key,
    required this.compact,
    required this.hasAppBar,
    required this.child,
  });

  /// Whether a floating bottom tab bar is shown.
  final bool compact;

  /// Whether a floating glass app bar is shown.
  final bool hasAppBar;

  /// Page content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(
          top: media.padding.top + (hasAppBar ? AppTokens.appBarHeight : 0),
          bottom: media.padding.bottom + (compact ? AppTokens.barClearance : 0),
        ),
      ),
      // A glass screen has no Material Scaffold, and a SnackBar has nowhere
      // to appear without one. This transparent one gives it a place. The
      // empty bottom bar is the glass bar's room: a SnackBar floats above it,
      // and the page still runs underneath, as `extendBody` keeps it.
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        extendBody: true,
        bottomNavigationBar: compact
            ? const SizedBox(height: AppTokens.barClearance)
            : null,
        body: child,
      ),
    );
  }
}
