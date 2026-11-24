import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// A value with a button on each side to take one step down or up: minutes
/// added to a prayer, days moved on a calendar.
///
/// [label] says the current value in words. The buttons are the platform's
/// icon buttons at the shared touch size, and a button at its end is disabled
/// rather than hidden, so the row does not move.
class AppStepper extends StatelessWidget {
  /// Creates a stepper showing [label].
  const AppStepper({
    super.key,
    required this.label,
    required this.decreaseLabel,
    required this.increaseLabel,
    required this.onDecrease,
    required this.onIncrease,
    this.highlighted = false,
  });

  /// The value, in words.
  final String label;

  /// What the left button does, for screen readers and its tooltip.
  final String decreaseLabel;

  /// What the right button does, for screen readers and its tooltip.
  final String increaseLabel;

  /// Called to step down. Null disables the button (the lowest value).
  final VoidCallback? onDecrease;

  /// Called to step up. Null disables the button (the highest value).
  final VoidCallback? onIncrease;

  /// Whether the value differs from the usual one, which colours it.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        _StepButton(
          icon: Icons.remove,
          tooltip: decreaseLabel,
          onPressed: onDecrease,
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: highlighted ? scheme.primary : scheme.onSurface,
              ),
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          tooltip: increaseLabel,
          onPressed: onIncrease,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    constraints: const BoxConstraints(
      minWidth: AppTokens.minTarget,
      minHeight: AppTokens.minTarget,
    ),
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
  );
}
