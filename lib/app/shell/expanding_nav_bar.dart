import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_platform.dart';
import '../../core/theme/app_surface_style.dart';
import '../../core/theme/app_tokens.dart';
import 'shell_destination.dart';

/// The phone's tab bar: a floating pill where the selected destination grows
/// into a rounded chip with its label beside its icon and the others stay
/// icon-only, so the bar reads at a glance and stays light. Liquid glass on
/// iOS, a raised surface elsewhere.
class ExpandingNavBar extends StatelessWidget {
  /// Creates the bar for [destinations] with [index] selected.
  const ExpandingNavBar({
    super.key,
    required this.destinations,
    required this.index,
    required this.onSelected,
  });

  /// Destinations to show, in order.
  final List<ShellDestination> destinations;

  /// Selected destination.
  final int index;

  /// Called when a destination is tapped.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaceStyle.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final duration = still ? Duration.zero : AppTokens.motionMedium;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppTokens.floatingBarGap),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppTokens.gutterCompact,
        ),
        child: _BarSurface(
          surfaces: surfaces,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final total = constraints.maxWidth;
              final count = destinations.length;
              // The selected chip takes a share of the bar; the rest split
              // what is left, and never shrink below a touch target.
              final rest = (total * 0.58 / (count - 1)).clamp(
                AppTokens.minTarget,
                total,
              );
              final selected = total - rest * (count - 1);
              return Row(
                children: [
                  for (var i = 0; i < count; i++)
                    _Item(
                      destination: destinations[i],
                      selected: i == index,
                      width: i == index ? selected : rest,
                      duration: duration,
                      onTap: () {
                        if (i != index) {
                          onSelected(i);
                        }
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.destination,
    required this.selected,
    required this.width,
    required this.duration,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final double width;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      // The node replaces its children's semantics, so it carries the tap
      // itself; otherwise Switch Access and Voice Access find no action.
      onTap: onTap,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        width: width,
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.floatingBarHeight),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? destination.activeIcon : destination.icon,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                  if (selected)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 8),
                        child: Text(
                          destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: scheme.onPrimaryContainer),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bar's floating pill: liquid glass on iOS, a raised surface elsewhere.
class _BarSurface extends StatelessWidget {
  const _BarSurface({required this.surfaces, required this.child});

  final AppSurfaceStyle surfaces;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: const EdgeInsets.all(8), child: child);
    if (context.isCupertino) {
      return SizedBox(
        height: AppTokens.floatingBarHeight,
        child: GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.premium,
          shape: const LiquidRoundedSuperellipse(
            borderRadius: AppTokens.floatingBarHeight / 2,
          ),
          child: Material(type: MaterialType.transparency, child: content),
        ),
      );
    }
    return Container(
      height: AppTokens.floatingBarHeight,
      decoration: BoxDecoration(
        color: surfaces.raised,
        borderRadius: BorderRadius.circular(AppTokens.floatingBarHeight),
        border: Border.all(color: surfaces.hairline),
        boxShadow: surfaces.floatingShadow,
      ),
      child: content,
    );
  }
}
