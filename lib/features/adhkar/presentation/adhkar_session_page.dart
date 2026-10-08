import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

import '../../../core/haptics/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../settings/application/digits_provider.dart';
import '../application/adhkar_providers.dart';
import '../domain/adhkar_collection.dart';
import 'dhikr_card.dart';

/// Reads one collection and counts each dhikr as the person says it.
class AdhkarSessionPage extends ConsumerWidget {
  /// Creates the page for the collection with [collectionId].
  const AdhkarSessionPage({
    super.key,
    required this.collectionId,
    this.focusOrder,
  });

  /// Id of the collection to show.
  final String collectionId;

  /// Order of the dhikr to scroll to when the page opens, if any.
  final int? focusOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(adhkarCatalogProvider);
    final collection = catalog.value?.byId(collectionId);
    return AppPageScaffold(
      title: collection?.title(language) ?? l10n.duas,
      body: Builder(
        builder: (context) {
          if (catalog.hasError || (catalog.hasValue && collection == null)) {
            return EmptyState(
              icon: Icons.error_outline,
              title: l10n.adhkarLoadError,
              message: '',
              actionLabel: l10n.retry,
              onAction: () => ref.invalidate(adhkarCatalogProvider),
            );
          }
          if (collection == null) return const _Skeleton();
          return ContentContainer(
            child: _Session(collection: collection, focusOrder: focusOrder),
          );
        },
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: pagePadding(context),
    child: AppShimmer(
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            const SkeletonBox(height: 200, radius: AppTokens.radiusCard),
            const SizedBox(height: 12),
          ],
        ],
      ),
    ),
  );
}

class _Session extends ConsumerStatefulWidget {
  const _Session({required this.collection, this.focusOrder});

  final AdhkarCollection collection;
  final int? focusOrder;

  @override
  ConsumerState<_Session> createState() => _SessionState();
}

class _SessionState extends ConsumerState<_Session> {
  late final List<GlobalKey> _keys = [
    for (final _ in widget.collection.entries) GlobalKey(),
  ];
  final GlobalKey _completeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final order = widget.focusOrder;
    if (order == null) return;
    final index = widget.collection.entries.indexWhere(
      (entry) => entry.order == order,
    );
    if (index < 0) return;
    // Bring the dhikr a search found into view once the list is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _keys[index].currentContext;
      if (target != null) Scrollable.ensureVisible(target, alignment: 0.05);
    });
  }

  Future<void> _count(int index) async {
    final collection = widget.collection;
    final entry = collection.entries[index];
    final count = ref.read(dhikrCountProvider((collection, entry)));
    if (count >= entry.repeat) return;
    final finishes = count + 1 >= entry.repeat;
    // Feel it the moment the finger lands, before anything is saved: a light
    // tick for a repeat, a firmer pulse when the dhikr is done and the next
    // comes into view, a double pulse when the whole list is done.
    final lastOne =
        finishes &&
        collection.entries.every(
          (other) =>
              other == entry ||
              ref.read(dhikrCountProvider((collection, other))) >= other.repeat,
        );
    unawaited(
      lastOne
          ? Haptics.celebrate()
          : finishes
          ? Haptics.step()
          : Haptics.tick(),
    );
    await ref
        .read(adhkarProgressProvider.notifier)
        .increment(collection, entry);
    if (finishes) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _advance(index));
    }
  }

  /// Brings the next unfinished dhikr into view, or the closing message when
  /// everything is done.
  void _advance(int from) {
    if (!mounted) return;
    final collection = widget.collection;
    final progress = ref.read(collectionProgressProvider(collection));
    GlobalKey? target;
    if (progress.complete) {
      target = _completeKey;
    } else {
      final counts = [
        for (final entry in collection.entries)
          ref.read(dhikrCountProvider((collection, entry))) >= entry.repeat,
      ];
      for (var i = from + 1; i < counts.length; i++) {
        if (!counts[i]) {
          target = _keys[i];
          break;
        }
      }
    }
    final context = target?.currentContext;
    if (context == null) return;
    final still = MediaQuery.disableAnimationsOf(this.context);
    Scrollable.ensureVisible(
      context,
      alignment: 0.05,
      duration: still ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final collection = widget.collection;
    final padding = pagePadding(context);
    final progress = ref.watch(collectionProgressProvider(collection));
    final next = progress.complete
        ? ref.watch(nextCollectionProvider(collection))
        : null;
    return Column(
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            padding.start,
            padding.top,
            padding.end,
            8,
          ),
          child: _ProgressStrip(
            done: progress.doneEntries,
            total: progress.totalEntries,
            fraction: progress.fraction,
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsetsDirectional.fromSTEB(
              padding.start,
              4,
              padding.end,
              padding.bottom,
            ),
            children: [
              for (var i = 0; i < collection.entries.length; i++)
                Padding(
                  key: _keys[i],
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DhikrCard(
                    collection: collection,
                    dhikr: collection.entries[i],
                    number: i + 1,
                    onCount: () => _count(i),
                    onUndo: () => ref
                        .read(adhkarProgressProvider.notifier)
                        .decrement(collection, collection.entries[i]),
                  ),
                ),
              if (progress.complete)
                _CompleteCard(
                  key: _completeKey,
                  title: collection.title(
                    Localizations.localeOf(context).languageCode,
                  ),
                  onRestart: () => ref
                      .read(adhkarProgressProvider.notifier)
                      .reset(collection),
                  nextTitle: next?.title(
                    Localizations.localeOf(context).languageCode,
                  ),
                  onNext: next == null
                      ? null
                      : () => context.pushReplacement(
                          AppRoute.adhkarSessionPath(next.id),
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressStrip extends ConsumerWidget {
  const _ProgressStrip({
    required this.done,
    required this.total,
    required this.fraction,
  });

  final int done;
  final int total;
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

class _CompleteCard extends StatelessWidget {
  const _CompleteCard({
    super.key,
    required this.title,
    required this.onRestart,
    this.nextTitle,
    this.onNext,
  });

  final String title;
  final VoidCallback onRestart;

  /// Title of the list to go on to, when there is one.
  final String? nextTitle;
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
