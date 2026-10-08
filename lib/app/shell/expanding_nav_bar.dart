import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_tokens.dart';
import 'shell_destination.dart';

/// The Android tab bar: a floating pill where the selected destination grows
/// into a rounded chip with its label and the others stay icon-only, so the
/// bar reads at a glance and stays light.
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
    final scheme = Theme.of(context).colorScheme;
    final still = MediaQuery.disableAnimationsOf(context);
    final duration = still ? Duration.zero : const Duration(milliseconds: 280);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppTokens.floatingBarGap),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppTokens.gutterCompact,
        ),
        child: Container(
          height: AppTokens.floatingBarHeight,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppTokens.floatingBarHeight),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
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
                          HapticFeedback.selectionClick();
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
