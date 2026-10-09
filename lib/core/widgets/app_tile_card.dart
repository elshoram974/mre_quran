import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_card.dart';
import 'app_directional_icon.dart';

/// A card that is one tappable row: a leading icon, a title, a line under it,
/// and a trailing arrow (or something else).
///
/// Used wherever a row leads somewhere: a group, a screen, a sheet. Without
/// [onTap] it is a plain card with no arrow and no ripple.
class AppTileCard extends StatelessWidget {
  /// Creates a row. Give an [icon] (drawn in a circle when [avatar]) or your
  /// own [leading] widget.
  const AppTileCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.avatar = false,
    this.onTap,
  });

  /// The main line.
  final String title;

  /// The line under [title].
  final String? subtitle;

  /// Icon at the start.
  final IconData? icon;

  /// Replaces [icon] with any widget.
  final Widget? leading;

  /// Replaces the arrow. Ignored without [onTap] unless given.
  final Widget? trailing;

  /// Whether [icon] sits in a tinted circle.
  final bool avatar;

  /// Called on tap; null makes the row inert.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final start =
        leading ??
        (icon == null
            ? null
            : avatar
            ? CircleAvatar(
                radius: 24,
                backgroundColor: scheme.secondaryContainer,
                foregroundColor: scheme.onSecondaryContainer,
                child: Icon(icon),
              )
            : Icon(icon, color: scheme.primary));
    final end = trailing ?? (onTap == null ? null : const AppForwardChevron());
    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppTokens.minTarget),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (start != null) ...[start, const SizedBox(width: 16)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (end != null) ...[const SizedBox(width: 8), end],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
