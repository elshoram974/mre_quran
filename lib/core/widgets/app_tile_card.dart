import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_card.dart';
import 'app_directional_icon.dart';
import 'app_icon_badge.dart';

/// A card that is one tappable row: a leading icon badge, a title, a line under
/// it, and a trailing arrow (or something else).
///
/// Used wherever a row leads somewhere: a group, a screen, a sheet. Without
/// [onTap] it is a plain card with no arrow and no ripple.
class AppTileCard extends StatelessWidget {
  /// Creates a row. Give an [icon] (drawn in an [AppIconBadge]) or your own
  /// [leading] widget.
  const AppTileCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
  });

  /// The main line.
  final String title;

  /// The line under [title].
  final String? subtitle;

  /// Icon at the start, shown in a badge.
  final IconData? icon;

  /// Replaces [icon] with any widget.
  final Widget? leading;

  /// Replaces the arrow. Ignored without [onTap] unless given.
  final Widget? trailing;

  /// Called on tap; null makes the row inert.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final start = leading ?? (icon == null ? null : AppIconBadge(icon!));
    final end = trailing ?? (onTap == null ? null : const AppForwardChevron());
    // With large text every pixel of width saves a line, so the leading mark
    // moves above the title and the text takes the whole row.
    final stacked =
        start != null &&
        MediaQuery.textScalerOf(context).scale(1) >= AppTokens.stackTextScale;
    final text = _TileText(title: title, subtitle: subtitle);
    return AppCard(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppTokens.cardPadding,
        vertical: AppTokens.spaceMedium,
      ),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTokens.minTarget),
        child: Row(
          children: [
            if (start != null && !stacked) ...[
              start,
              const SizedBox(width: AppTokens.spaceMedium),
            ],
            Expanded(
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        start,
                        const SizedBox(height: AppTokens.spaceSmall),
                        text,
                      ],
                    )
                  : text,
            ),
            if (end != null) ...[
              const SizedBox(width: AppTokens.spaceSmall),
              end,
            ],
          ],
        ),
      ),
    );
  }
}

class _TileText extends StatelessWidget {
  const _TileText({required this.title, required this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
