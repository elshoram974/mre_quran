import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../settings/application/digits_provider.dart';
import '../application/adhkar_providers.dart';
import '../domain/adhkar_collection.dart';
import '../domain/dhikr.dart';

/// The tap-to-count control of one dhikr: a big button showing how many
/// times it has been said, a way to take one back, and a "done" badge once
/// the count is reached.
class DhikrCounter extends ConsumerWidget {
  /// Creates the counter of [dhikr] in [collection].
  const DhikrCounter({
    super.key,
    required this.collection,
    required this.dhikr,
    required this.onCount,
    required this.onUndo,
    this.inline = false,
  });

  /// The collection the dhikr belongs to.
  final AdhkarCollection collection;

  /// The dhikr counted.
  final Dhikr dhikr;

  /// Called when the person taps the counter.
  final VoidCallback onCount;

  /// Called when the person takes back one repeat.
  final VoidCallback onUndo;

  /// Whether undo sits beside the button, as an icon, instead of under it.
  /// A bar pinned under scrolling words uses this, so its height never
  /// changes.
  final bool inline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final digits = ref.watch(digitsFormatterProvider);
    final count = ref.watch(dhikrCountProvider((collection, dhikr)));
    final done = count >= dhikr.repeat;
    final canUndo = count > 0 && !done;

    final button = Semantics(
      button: !done,
      label: l10n.adhkarCounterLabel(digits(count), digits(dhikr.repeat)),
      excludeSemantics: true,
      child: done
          ? _DoneBadge(label: l10n.done)
          : FilledButton(
              onPressed: onCount,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(
                  AppTokens.counterButtonHeight,
                ),
              ),
              child: Text(
                l10n.adhkarProgress(digits(count), digits(dhikr.repeat)),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: scheme.onPrimary,
                ),
              ),
            ),
    );
    if (inline) {
      return Row(
        children: [
          Expanded(child: button),
          if (canUndo) ...[
            const SizedBox(width: AppTokens.spaceSmall),
            IconButton.filledTonal(
              onPressed: onUndo,
              tooltip: l10n.adhkarUndo,
              icon: const Icon(Icons.undo_rounded),
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        if (canUndo)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onUndo,
              icon: const Icon(Icons.undo_rounded),
              label: Text(l10n.adhkarUndo),
            ),
          ),
      ],
    );
  }
}

class _DoneBadge extends StatelessWidget {
  const _DoneBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: AppTokens.counterButtonHeight,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusField),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, color: scheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: scheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}
