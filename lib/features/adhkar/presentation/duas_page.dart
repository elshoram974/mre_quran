import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../settings/application/digits_provider.dart';
import '../application/adhkar_providers.dart';
import '../application/reminders_provider.dart';
import '../domain/adhkar_collection.dart';
import 'collection_card.dart';
import 'reminders_sheet.dart';

/// The adhkar tab: today's suggested list first, then the others, then the
/// reminders.
class DuasPage extends ConsumerWidget {
  const DuasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final catalog = ref.watch(adhkarCatalogProvider);
    return catalog.when(
      loading: () => const _Skeleton(),
      error: (_, _) => EmptyState(
        icon: Icons.error_outline,
        title: l10n.adhkarLoadError,
        message: '',
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(adhkarCatalogProvider),
      ),
      data: (data) => _Content(catalog: data),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: pagePadding(context),
    child: const AppShimmer(
      child: Column(
        children: [
          SkeletonBox(height: 168, radius: AppTokens.radiusCard),
          SizedBox(height: 12),
          SkeletonBox(height: 84, radius: AppTokens.radiusCard),
        ],
      ),
    ),
  );
}

class _Content extends ConsumerWidget {
  const _Content({required this.catalog});

  final AdhkarCatalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final active = ref.watch(activeSessionProvider);
    final now = ref.watch(adhkarNowProvider);
    final featured = active ?? catalog.suggestedAt(now.hour * 60 + now.minute);
    return ContentContainer(
      child: ListView(
        padding: pagePadding(context),
        children: [
          if (featured != null) ...[
            Text(
              active != null ? l10n.adhkarResume : l10n.adhkarSuggested,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            CollectionCard(collection: featured, featured: true),
          ],
          for (final group in AdhkarGroup.values)
            _GroupSection(
              group: group,
              collections: [
                for (final collection in catalog.collections)
                  if (collection.group == group && collection != featured)
                    collection,
              ],
            ),
          const SizedBox(height: 24),
          const _RemindersTile(),
        ],
      ),
    );
  }
}

/// One titled group of collections, laid out in one or two columns.
class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group, required this.collections});

  final AdhkarGroup group;
  final List<AdhkarCollection> collections;

  @override
  Widget build(BuildContext context) {
    if (collections.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final title = switch (group) {
      AdhkarGroup.daily => l10n.adhkarGroupDaily,
      AdhkarGroup.prayer => l10n.adhkarGroupPrayer,
      AdhkarGroup.duas => l10n.adhkarGroupDuas,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  WindowSize.fromWidth(constraints.maxWidth) ==
                      WindowSize.compact
                  ? 1
                  : 2;
              const gap = 12.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final collection in collections)
                    SizedBox(
                      width: width,
                      child: CollectionCard(collection: collection),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RemindersTile extends ConsumerWidget {
  const _RemindersTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final digits = ref.watch(digitsFormatterProvider);
    final enabled = ref.watch(
      remindersProvider.select(
        (value) =>
            value.value?.values.where((setting) => setting.enabled).length ?? 0,
      ),
    );
    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Icon(
            enabled > 0
                ? Icons.notifications_active_outlined
                : Icons.notifications_none_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(l10n.adhkarReminders),
          subtitle: Text(
            enabled > 0
                ? l10n.adhkarRemindersSome(digits(enabled))
                : l10n.adhkarRemindersNone,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => RemindersSheet.show(context),
        ),
      ),
    );
  }
}
