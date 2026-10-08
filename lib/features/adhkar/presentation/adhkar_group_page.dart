import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../application/adhkar_providers.dart';
import 'collection_card.dart';

/// The lists of one group.
class AdhkarGroupPage extends ConsumerWidget {
  /// Creates the page for the group with [groupId].
  const AdhkarGroupPage({super.key, required this.groupId});

  /// Id of the group to show.
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(adhkarCatalogProvider);
    final group = catalog.value?.groupById(groupId);
    return AppPageScaffold(
      title: group?.title(language) ?? l10n.duas,
      body: Builder(
        builder: (context) {
          if (catalog.hasError || (catalog.hasValue && group == null)) {
            return EmptyState(
              icon: Icons.error_outline,
              title: l10n.adhkarLoadError,
              message: '',
              actionLabel: l10n.retry,
              onAction: () => ref.invalidate(adhkarCatalogProvider),
            );
          }
          if (group == null) {
            return Padding(
              padding: pagePadding(context),
              child: const AppShimmer(
                child: Column(
                  children: [
                    SkeletonBox(height: 84, radius: AppTokens.radiusCard),
                    SizedBox(height: 12),
                    SkeletonBox(height: 84, radius: AppTokens.radiusCard),
                  ],
                ),
              ),
            );
          }
          final collections = catalog.value!.collectionsIn(group);
          return ContentContainer(
            child: ListView.separated(
              padding: pagePadding(context),
              itemCount: collections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  CollectionCard(collection: collections[index]),
            ),
          );
        },
      ),
    );
  }
}
