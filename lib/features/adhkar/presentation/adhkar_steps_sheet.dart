import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../settings/application/digits_provider.dart';
import '../application/adhkar_providers.dart';
import '../application/dhikr_counter.dart';
import '../domain/adhkar_collection.dart';
import 'adhkar_complete_card.dart';
import 'adhkar_progress_strip.dart';
import 'dhikr_card.dart';

/// Reads a list one dhikr at a time, in a bottom sheet.
///
/// Each dhikr is a step. When its count is done the next step comes by itself,
/// and when the last one is done the sheet says so and offers the next list.
abstract final class AdhkarSteps {
  /// Opens the list [collectionId] as steps, starting at the dhikr whose order
  /// is [focusOrder] when given, else at the first one not yet finished.
  static Future<void> show(
    BuildContext context, {
    required String collectionId,
    int? focusOrder,
  }) => AppSheet.show<void>(
    context: context,
    expandable: true,
    initialSize: 0.88,
    builder: (_) =>
        _StepsBody(collectionId: collectionId, focusOrder: focusOrder),
  );
}

class _StepsBody extends ConsumerStatefulWidget {
  const _StepsBody({required this.collectionId, this.focusOrder});

  final String collectionId;
  final int? focusOrder;

  @override
  ConsumerState<_StepsBody> createState() => _StepsBodyState();
}

class _StepsBodyState extends ConsumerState<_StepsBody> {
  int? _index;
  bool _finished = false;
  Timer? _pending;

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }

  /// Where to start: the dhikr a search found, else the first one not done.
  int _start(AdhkarCollection collection) {
    final order = widget.focusOrder;
    if (order != null) {
      final found = collection.entries.indexWhere(
        (entry) => entry.order == order,
      );
      if (found >= 0) return found;
    }
    final open = _firstOpen(collection, from: 0);
    return open ?? 0;
  }

  /// The first dhikr from [from] on that is not done, wrapping round; null
  /// when all are done.
  int? _firstOpen(AdhkarCollection collection, {required int from}) {
    final total = collection.entries.length;
    for (var step = 0; step < total; step++) {
      final index = (from + step) % total;
      final entry = collection.entries[index];
      if (ref.read(dhikrCountProvider((collection, entry))) < entry.repeat) {
        return index;
      }
    }
    return null;
  }

  Future<void> _count(AdhkarCollection collection, int index) async {
    final still = MediaQuery.disableAnimationsOf(context);
    final outcome = await countDhikr(
      ref,
      collection,
      collection.entries[index],
    );
    if (outcome != CountOutcome.finishedDhikr &&
        outcome != CountOutcome.finishedList) {
      return;
    }
    // A moment to see it done, then on to the next step.
    _pending?.cancel();
    _pending = Timer(
      still ? Duration.zero : const Duration(milliseconds: 450),
      () {
        if (!mounted) return;
        setState(() {
          if (outcome == CountOutcome.finishedList) {
            _finished = true;
          } else {
            _index = _firstOpen(collection, from: index + 1) ?? index;
          }
        });
      },
    );
  }

  void _go(AdhkarCollection collection, int to) {
    _pending?.cancel();
    setState(() => _index = to.clamp(0, collection.entries.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(adhkarCatalogProvider);
    final collection = catalog.value?.byId(widget.collectionId);
    if (catalog.hasError || (catalog.hasValue && collection == null)) {
      return EmptyState(
        icon: Icons.error_outline,
        title: l10n.adhkarLoadError,
        message: '',
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(adhkarCatalogProvider),
      );
    }
    if (collection == null) {
      return const Padding(
        padding: EdgeInsets.all(AppTokens.gutterCompact),
        child: AppShimmer(
          child: Column(
            children: [
              SkeletonBox(height: 28, width: 160),
              SizedBox(height: 16),
              SkeletonBox(height: 220, radius: AppTokens.radiusCard),
            ],
          ),
        ),
      );
    }
    final index = (_index ??= _start(
      collection,
    )).clamp(0, collection.entries.length - 1);
    final progress = ref.watch(collectionProgressProvider(collection));
    final digits = ref.watch(digitsFormatterProvider);
    final theme = Theme.of(context);
    final title = collection.title(language);
    final still = MediaQuery.disableAnimationsOf(context);
    final complete = _finished || progress.complete && _pending == null;
    final next = complete
        ? ref.watch(nextCollectionProvider(collection))
        : null;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppTokens.gutterCompact,
        0,
        AppTokens.gutterCompact,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
              TextButton(
                onPressed: () {
                  final root = Navigator.of(context, rootNavigator: true);
                  root.pop();
                  GoRouter.of(root.context)
                      .push(AppRoute.adhkarSessionPath(collection.id));
                },
                child: Text(l10n.adhkarShowList),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AdhkarProgressStrip(
            done: progress.doneEntries,
            total: progress.totalEntries,
            fraction: progress.fraction,
          ),
          const SizedBox(height: 12),
          if (complete)
            AdhkarCompleteCard(
              title: title,
              onRestart: () async {
                await ref
                    .read(adhkarProgressProvider.notifier)
                    .reset(collection);
                if (!mounted) return;
                setState(() {
                  _finished = false;
                  _index = 0;
                });
              },
              nextTitle: next?.title(language),
              onNext: next == null
                  ? null
                  : () {
                      final root = Navigator.of(context, rootNavigator: true);
                      root.pop();
                      unawaited(
                        AdhkarSteps.show(root.context, collectionId: next.id),
                      );
                    },
            )
          else ...[
            Row(
              children: [
                IconButton(
                  tooltip: l10n.adhkarStepPrevious,
                  onPressed: index == 0
                      ? null
                      : () => _go(collection, index - 1),
                  // These two flip with the text direction.
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    l10n.adhkarStep(
                      digits(index + 1),
                      digits(collection.entries.length),
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: l10n.adhkarStepNext,
                  onPressed: index == collection.entries.length - 1
                      ? null
                      : () => _go(collection, index + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: still
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              child: DhikrCard(
                key: ValueKey('${collection.id}:$index'),
                collection: collection,
                dhikr: collection.entries[index],
                number: index + 1,
                onCount: () => _count(collection, index),
                onUndo: () => ref
                    .read(adhkarProgressProvider.notifier)
                    .decrement(collection, collection.entries[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
