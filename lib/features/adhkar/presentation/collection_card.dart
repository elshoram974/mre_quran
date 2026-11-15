import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_directional_icon.dart';
import '../../../core/widgets/app_hero_card.dart';
import '../../settings/application/digits_provider.dart';
import '../application/adhkar_providers.dart';
import '../domain/adhkar_collection.dart';
import 'adhkar_icons.dart';
import 'adhkar_steps_sheet.dart';
import 'favorite_button.dart';
import 'progress_ring.dart';

/// A tappable card that opens one collection and shows today's progress.
///
/// The [featured] card is large and carries a start button; the others are
/// compact rows.
class CollectionCard extends ConsumerWidget {
  /// Creates a card for [collection].
  const CollectionCard({
    super.key,
    required this.collection,
    this.featured = false,
  });

  /// The collection it opens.
  final AdhkarCollection collection;

  /// Whether to draw the large variant.
  final bool featured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final digits = ref.watch(digitsFormatterProvider);
    final progress = ref.watch(collectionProgressProvider(collection));
    final title = collection.title(
      Localizations.localeOf(context).languageCode,
    );
    final progressText = l10n.adhkarProgress(
      digits(progress.doneEntries),
      digits(progress.totalEntries),
    );
    void open() => AdhkarSteps.show(context, collectionId: collection.id);
    // On the hero panel both lines take its own foreground.
    final scheme = theme.colorScheme;
    final titleColor = featured ? scheme.onPrimaryContainer : scheme.onSurface;
    final lineColor = featured
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    final header = Row(
      children: [
        ProgressRing(
          fraction: progress.fraction,
          icon: progress.complete
              ? Icons.check_rounded
              : adhkarIconData(collection.icon),
          size: featured ? 64 : 48,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    (featured
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.titleMedium)
                        ?.copyWith(color: titleColor),
              ),
              const SizedBox(height: 2),
              Text(
                progressText,
                style: theme.textTheme.bodyMedium?.copyWith(color: lineColor),
              ),
            ],
          ),
        ),
        FavoriteButton(collectionId: collection.id),
        if (!featured) const AppForwardChevron(),
      ],
    );

    if (!featured) {
      return AppCard(
        padding: const EdgeInsetsDirectional.all(AppTokens.cardPadding),
        onTap: open,
        child: header,
      );
    }
    return AppHeroCard(
      watermark: adhkarIconData(collection.icon),
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: AppTokens.cardPadding),
          progress.complete
              ? FilledButton.tonalIcon(
                  onPressed: open,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l10n.adhkarDoneToday),
                )
              : FilledButton(
                  onPressed: open,
                  child: Text(
                    progress.fraction == 0
                        ? l10n.adhkarStart
                        : l10n.adhkarContinue,
                  ),
                ),
        ],
      ),
    );
  }
}
