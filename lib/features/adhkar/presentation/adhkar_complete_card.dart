import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';

/// The message at the end of a list, with a way to go on or start over.
class AdhkarCompleteCard extends StatelessWidget {
  /// Creates the card for the list named [title].
  const AdhkarCompleteCard({
    super.key,
    required this.title,
    required this.onRestart,
    this.nextTitle,
    this.onNext,
  });

  /// Name of the list that was finished.
  final String title;

  /// Called to count the list again from the start.
  final VoidCallback onRestart;

  /// Title of the list to go on to, when there is one.
  final String? nextTitle;

  /// Called to go on to the next list, when there is one.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, size: 48, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            l10n.adhkarCompleteTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.adhkarCompleteBody(title),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          if (onNext != null && nextTitle != null) ...[
            FilledButton(
              onPressed: onNext,
              child: Text(l10n.adhkarNext(nextTitle!)),
            ),
            const SizedBox(height: 4),
          ],
          TextButton(onPressed: onRestart, child: Text(l10n.adhkarRestart)),
        ],
      ),
    );
  }
}
