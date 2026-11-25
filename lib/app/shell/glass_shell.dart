import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../core/widgets/app_page_scaffold.dart';
import 'expanding_nav_rail.dart';
import 'shell_destination.dart';

/// iOS chrome: liquid glass app bar and floating glass tab bar or rail.
/// Everything is glass, the side rail of an iPad included.
class GlassShell extends StatelessWidget {
  /// Creates the glass shell around [child].
  const GlassShell({
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
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: GlassScaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: showAppBar
            ? GlassAppBar(title: Text(destinations[index].label))
            : null,
        bottomBar: bottomBar
            ? _CenteredBar(
                shown: showNavigation,
                child: GlassTabBar.bottom(
                  selectedIndex: index,
                  onTabSelected: onSelected,
                  quality: GlassQuality.premium,
                  selectedIconColor: scheme.primary,
                  selectedLabelColor: scheme.primary,
                  unselectedIconColor: scheme.onSurfaceVariant,
                  unselectedLabelColor: scheme.onSurfaceVariant,
                  tabs: [
                    // Only the chosen tab names itself; the others show
                    // their icon, as on Android.
                    for (final (i, item) in destinations.indexed)
                      GlassTab(
                        icon: Icon(item.icon),
                        activeIcon: Icon(item.activeIcon),
                        label: i == index ? item.label : null,
                        semanticLabel: item.label,
                      ),
                  ],
                ),
              )
            : null,
        body: GlassInsetBody(
          compact: bottomBar && showNavigation,
          hasAppBar: showAppBar,
          child: bottomBar
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
        ),
      ),
    );
  }
}

/// Keeps a floating bar a thumb's reach wide on a tablet instead of stretching
/// it across the whole window. It reports the bar's own height, which the glass
/// scaffold reads to keep the page clear of it.
class _CenteredBar extends StatelessWidget implements PreferredSizeWidget {
  const _CenteredBar({required this.shown, required this.child});

  /// Whether the bar shows; it slides away while the reader hides its bars.
  final bool shown;

  final GlassTabBar child;

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: ShellNavigation.bottomBarMaxWidth,
      ),
      child: NavigationAppear(
        shown: shown,
        from: const Offset(0, 1.3),
        child: child,
      ),
    ),
  );
}
