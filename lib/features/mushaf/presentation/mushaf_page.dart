import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../quran_index/application/quran_metadata_provider.dart';
import '../../settings/application/digits_provider.dart';
import '../application/reading_position_provider.dart';

/// Mushaf tab. Shows the reading position and opens the index.
///
/// The page renderer arrives once the text, page map, and font are verified.
class MushafPage extends ConsumerWidget {
  const MushafPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ListView(
      padding: pagePadding(context),
      children: [
        const _PositionCard(),
        const SizedBox(height: 12),
        AppCard(
          child: ListTile(
            leading: Icon(
              Icons.format_list_numbered_rtl,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(l10n.quranIndex),
            subtitle: Text('${l10n.indexSurahs} · ${l10n.indexJuz}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final page = await context.push<int>(AppRoute.quranIndex.path);
              if (page != null) {
                await ref.read(readingPositionProvider.notifier).setPage(page);
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(l10n.readerInfo)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PositionCard extends ConsumerWidget {
  const _PositionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final page = ref.watch(readingPositionProvider).value;
    final metadata = ref.watch(quranMetadataProvider).value;
    final digits = ref.watch(digitsFormatterProvider);
    if (page == null || metadata == null) {
      return const AppCard(
        padding: EdgeInsets.all(20),
        child: AppShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 140, height: 18),
              SizedBox(height: 10),
              SkeletonBox(width: 200, height: 14),
            ],
          ),
        ),
      );
    }
    final surah = metadata.surahAtPage(page);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(
            Icons.bookmark_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentPosition,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(l10n.currentPositionBody(digits(page), surah.arabicName)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
