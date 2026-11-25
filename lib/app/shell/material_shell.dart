import 'package:material_ui/material_ui.dart';

import '../../core/layout/adaptive_layout.dart';
import 'expanding_nav_bar.dart';
import 'expanding_nav_rail.dart';
import 'shell_destination.dart';

/// Android chrome: Material 3 top app bar, and the floating bar or rail.
class MaterialShell extends StatelessWidget {
  /// Creates the Material shell around [child].
  const MaterialShell({
    super.key,
    required this.size,
    required this.destinations,
    required this.index,
    required this.onSelected,
    required this.child,
    this.showAppBar = true,
    this.showNavigation = true,
    this.overContent = false,
  });

  /// Current window size class.
  final WindowSize size;

  /// Destinations to show.
  final List<ShellDestination> destinations;

  /// Selected destination index.
  final int index;

  /// Called when a destination is chosen.
  final ValueChanged<int> onSelected;

  /// Page content.
  final Widget child;

  /// Whether the shell draws its own app bar. The Mushaf tab draws its own.
  final bool showAppBar;

  /// Whether the tab bar or rail is shown. False in immersive reading.
  final bool showNavigation;

  /// Whether the rail lies over the page (the Mushaf) instead of beside it.
  final bool overContent;

  @override
  Widget build(BuildContext context) {
    final bottomBar = size.usesBottomBar;
    final beside = ExpandingNavRail.labelsBesideAt(
      MediaQuery.sizeOf(context).width,
    );
    return Scaffold(
      // The tab bar floats; every page runs under it and keeps clear of it
      // through the bottom padding the Scaffold publishes.
      extendBody: true,
      appBar: showAppBar
          ? AppBar(title: Text(destinations[index].label))
          : null,
      body: bottomBar
          ? ContentContainer(child: child)
          : RailLayout(
              rail: ExpandingNavRail(
                index: index,
                onSelected: onSelected,
                destinations: destinations,
                labelsBeside: beside,
              ),
              railWidth: ExpandingNavRail.widthOf(
                context,
                destinations,
                labelsBeside: beside,
              ),
              shown: showNavigation,
              overContent: overContent,
              child: ContentContainer(child: child),
            ),
      // Kept while the reader hides its bars, and slid away instead, so it
      // comes and goes with them.
      bottomNavigationBar: bottomBar
          ? Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: ShellNavigation.bottomBarMaxWidth,
                ),
                child: NavigationAppear(
                  shown: showNavigation,
                  from: const Offset(0, 1.3),
                  child: ExpandingNavBar(
                    index: index,
                    onSelected: onSelected,
                    destinations: destinations,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
