import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Sizes of [AppIconBadge].
enum AppIconBadgeSize {
  /// For list rows and switches.
  small(AppTokens.badgeSmall, 20, AppTokens.radiusBadge),

  /// For tile and group cards.
  medium(AppTokens.badgeMedium, 24, AppTokens.radiusBadge),

  /// For empty and error states.
  large(AppTokens.badgeLarge, 36, AppTokens.radiusCard);

  const AppIconBadgeSize(this.side, this.iconSize, this.radius);

  /// Width and height of the badge.
  final double side;

  /// Size of the glyph inside.
  final double iconSize;

  /// Corner radius.
  final double radius;
}

/// A glyph on a softly tinted rounded square: the leading mark of rows, tiles,
/// and empty states, so every list in the app starts the same way.
///
/// The badge is decoration; the row it leads carries the meaning, so it is
/// hidden from screen readers.
class AppIconBadge extends StatelessWidget {
  /// Creates a badge showing [icon].
  const AppIconBadge(
    IconData this.icon, {
    super.key,
    this.size = AppIconBadgeSize.medium,
    this.emphasized = false,
  }) : text = null;

  /// Creates a badge showing a short [text], such as a position number.
  const AppIconBadge.text(
    String this.text, {
    super.key,
    this.size = AppIconBadgeSize.small,
    this.emphasized = false,
  }) : icon = null;

  /// The glyph, when built with the default constructor.
  final IconData? icon;

  /// The label, when built with [AppIconBadge.text].
  final String? text;

  /// How big the badge is.
  final AppIconBadgeSize size;

  /// Whether to use the solid accent, for the current or selected item.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = emphasized ? scheme.primary : scheme.primaryContainer;
    final foreground = emphasized
        ? scheme.onPrimary
        : scheme.onPrimaryContainer;
    return ExcludeSemantics(
      child: Container(
        width: size.side,
        height: size.side,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size.radius),
        ),
        child: icon != null
            ? Icon(icon, size: size.iconSize, color: foreground)
            : Text(
                text!,
                maxLines: 1,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
      ),
    );
  }
}
