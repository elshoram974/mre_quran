import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../settings/application/digits_provider.dart';
import '../application/adhkar_providers.dart';
import '../application/favorites_provider.dart';
import '../application/reminders_provider.dart';
import '../domain/adhkar_collection.dart';
import 'collection_card.dart';
import 'group_card.dart';
import 'reminders_sheet.dart';

/// The adhkar tab: search, the list for now, the favourites, the sections, and
/// the reminders.
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
          SkeletonBox(height: 52),
          SizedBox(height: 16),
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
    final starred = [
      for (final id
          in ref.watch(adhkarFavoritesProvider).value ?? const <String>[])
        if (catalog.byId(id) case final collection? when collection != featured)
          collection,
    ];
    return ContentContainer(
      child: ListView(
        padding: pagePadding(context),
        children: [
          const _SearchBar(),
          if (featured != null) ...[
            const SizedBox(height: 20),
            Text(
              active != null ? l10n.adhkarResume : l10n.adhkarSuggested,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            CollectionCard(collection: featured, featured: true),
          ],
          if (starred.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(l10n.adhkarFavorites, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _Grid(
              children: [
                for (final collection in starred)
                  CollectionCard(
                    key: ValueKey(collection.id),
                    collection: collection,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text(l10n.adhkarSections, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _Grid(
            children: [
              for (final group in catalog.groups)
                GroupCard(
                  group: group,
                  count: catalog.collectionsIn(group).length,
                ),
            ],
          ),
          const SizedBox(height: 24),
          const _RemindersTile(),
        ],
      ),
    );
  }
}

/// Lays [children] out in one column on compact widths, two otherwise.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          WindowSize.fromWidth(constraints.maxWidth) == WindowSize.compact
          ? 1
          : 2;
      const gap = 12.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

/// Looks like a search field; a tap opens the search page.
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: context.l10n.adhkarSearchHint,
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radiusField),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoute.adhkarSearch.path),
          child: Container(
            height: AppTokens.minTarget + 4,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.search, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.adhkarSearchHint,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
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
