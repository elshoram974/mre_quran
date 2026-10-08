import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../settings/application/digits_provider.dart';

/// A bar with "3 of 26" beside it.
class AdhkarProgressStrip extends ConsumerWidget {
  /// Creates the strip.
  const AdhkarProgressStrip({
    super.key,
    required this.done,
    required this.total,
    required this.fraction,
  });

  /// Entries finished.
  final int done;

  /// Entries in the list.
  final int total;

  /// Share of all repeats said, 0 to 1.
  final double fraction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(digitsFormatterProvider);
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusField),
            child: LinearProgressIndicator(value: fraction, minHeight: 8),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          context.l10n.adhkarProgress(digits(done), digits(total)),
          style: theme.textTheme.labelLarge,
        ),
      ],
    );
  }
}
