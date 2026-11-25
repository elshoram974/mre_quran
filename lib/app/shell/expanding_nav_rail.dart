import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_platform.dart';
import '../../core/theme/app_surface_style.dart';
import '../../core/theme/app_tokens.dart';
import 'shell_destination.dart';

/// The side rail of a wide window: the phone's floating bar stood on end. The
/// selected destination is a rounded chip with its label beside its icon; the
/// others show only their icon. Liquid glass on iOS, a raised surface
/// elsewhere. It floats, so it can lie over the Mushaf without moving it.
class ExpandingNavRail extends StatelessWidget {
  /// Creates the rail for [destinations] with [index] selected.
  const ExpandingNavRail({
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

  /// The rail's inner padding.
  static const double _padding = 8;

  /// Room on each side of an item's content.
  static const double _itemPadding = 14;

  /// Room between an icon and its label.
  static const double _gap = 8;

  /// The rail keeps one width whichever destination is chosen: room for the
  /// widest label beside its icon, at the text size the bar allows.
  static double widthOf(
    BuildContext context,
    List<ShellDestination> destinations,
  ) {
    final style = Theme.of(context).textTheme.labelLarge;
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    var widest = 0.0;
    for (final destination in destinations) {
      final painter = TextPainter(
        text: TextSpan(text: destination.label, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    return 2 * _padding + 2 * _itemPadding + 24 + _gap + widest.ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppTokens.motionMedium;
    final items = Padding(
      padding: const EdgeInsets.all(_padding),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < destinations.length; i++) ...[
              if (i > 0) const SizedBox(height: AppTokens.spaceTiny),
              _RailItem(
                destination: destinations[i],
                selected: i == index,
                duration: duration,
                onTap: () {
                  if (i != index) onSelected(i);
                },
              ),
            ],
          ],
        ),
      ),
    );
    final width = widthOf(context, destinations);
    if (context.isCupertino) {
      return SizedBox(
        width: width,
        child: GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.premium,
          shape: const LiquidRoundedSuperellipse(
            borderRadius: AppTokens.floatingBarHeight / 2,
          ),
          child: Material(type: MaterialType.transparency, child: items),
        ),
      );
    }
    final surfaces = AppSurfaceStyle.of(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: surfaces.raised,
        borderRadius: BorderRadius.circular(AppTokens.floatingBarHeight / 2),
        border: Border.all(color: surfaces.hairline),
        boxShadow: surfaces.floatingShadow,
      ),
      child: items,
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      // The node replaces its children's semantics, so it carries the tap.
      onTap: onTap,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 52),
        decoration: ShapeDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.primaryContainer.withValues(alpha: 0),
          shape: const StadiumBorder(),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: ExpandingNavRail._itemPadding,
                vertical: 14,
              ),
              child: Row(
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
                        padding: const EdgeInsetsDirectional.only(
                          start: ExpandingNavRail._gap,
                        ),
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

/// Slides the shell's bar or rail in from its edge and out again, so it comes
/// and goes with the reader's own bars instead of popping.
class NavigationAppear extends StatelessWidget {
  /// Shows [child] when [shown], slid away by [from] (a fraction of its size)
  /// otherwise.
  const NavigationAppear({
    super.key,
    required this.shown,
    required this.from,
    required this.child,
  });

  /// Whether the bar is showing.
  final bool shown;

  /// Where it goes when hidden.
  final Offset from;

  /// The bar.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return IgnorePointer(
      ignoring: !shown,
      child: ExcludeSemantics(
        excluding: !shown,
        child: AnimatedSlide(
          offset: shown ? Offset.zero : from,
          duration: duration,
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: shown ? 1 : 0,
            duration: duration,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A wide window's layout: the content, and the rail floating at its start
/// edge. On most pages the content keeps clear of the rail; over the Mushaf
/// ([overContent]) the rail lies on the page and the page keeps its size, so
/// the rail coming and going never moves the text.
class RailLayout extends StatelessWidget {
  /// Lays out [child] with [rail] at the start edge.
  const RailLayout({
    super.key,
    required this.rail,
    required this.railWidth,
    required this.shown,
    required this.overContent,
    required this.child,
  });

  /// The rail.
  final Widget rail;

  /// Its width, from [ExpandingNavRail.widthOf].
  final double railWidth;

  /// Whether the rail is showing (not in immersive reading).
  final bool shown;

  /// Whether the rail lies over the content instead of beside it.
  final bool overContent;

  /// The page.
  final Widget child;

  /// Room between the rail and the window's edges.
  static const double margin = 12;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: overContent ? 0 : railWidth + 2 * margin,
            ),
            child: child,
          ),
        ),
        PositionedDirectional(
          start: margin,
          top: padding.top + margin,
          bottom: padding.bottom + margin,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: NavigationAppear(
              shown: shown,
              // Out past the start edge: the left in English, the right in
              // Arabic.
              from: Offset(rtl ? 1.3 : -1.3, 0),
              child: rail,
            ),
          ),
        ),
      ],
    );
  }
}
