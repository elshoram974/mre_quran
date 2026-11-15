import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_icon_badge.dart';

/// The block shown when a screen has nothing to show or could not load: a
/// large icon badge, a title, a message, and an optional action such as retry.
class EmptyState extends StatelessWidget {
  /// Creates an empty or error block.
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Glyph in the badge.
  final IconData icon;

  /// What happened, in a few words.
  final String title;

  /// What the person can do next; may be empty.
  final String message;

  /// Label of the action button; the button shows only with [onAction].
  final String? actionLabel;

  /// Called when the action button is pressed.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(AppTokens.gutterWide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconBadge(icon, size: AppIconBadgeSize.large),
            const SizedBox(height: AppTokens.gutterWide),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTokens.spaceMedium),
            if (message.isNotEmpty)
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTokens.gutterWide),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
