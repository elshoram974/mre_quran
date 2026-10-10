import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_directional_icon.dart';
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
/// Each dhikr is a page: swipe to the next or the previous, or use the arrows
/// at the two ends. When its count is done the next page comes by itself, and
/// when the last one is done the sheet says so and offers the next list.
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
  PageController? _pages;
  bool _finished = false;
  Timer? _pending;

  @override
  void dispose() {
    _pending?.cancel();
    _pages?.dispose();
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
        if (outcome == CountOutcome.finishedList) {
          setState(() => _finished = true);
        } else {
          _go(collection, _firstOpen(collection, from: index + 1) ?? index);
        }
      },
    );
  }

  /// Turns to page [to]. The page view reports the change back through
  /// [_onPage], so a swipe and an arrow end up in the same place.
  void _go(AdhkarCollection collection, int to) {
    _pending?.cancel();
    final target = to.clamp(0, collection.entries.length - 1);
    final pages = _pages;
    if (pages == null || !pages.hasClients) {
      setState(() => _index = target);
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      pages.jumpToPage(target);
    } else {
      pages.animateToPage(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPage(int page) {
    if (page == _index) return;
    // A swipe during the pause after a finished dhikr wins over the auto-turn.
    _pending?.cancel();
    setState(() => _index = page);
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
    final pages = _pages ??= PageController(initialPage: index);
    // Room for one dhikr: its own page scrolls when a long dua needs more.
    final pageHeight = (MediaQuery.sizeOf(context).height * 0.52).clamp(
      360.0,
      620.0,
    );
    final progress = ref.watch(collectionProgressProvider(collection));
    final digits = ref.watch(digitsFormatterProvider);
    final theme = Theme.of(context);
    final title = collection.title(language);
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
          // A Wrap so the button drops under the title when large text leaves
          // no room beside it.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
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
                  _pages?.dispose();
                  _pages = null;
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
                  icon: const AppBackChevron(),
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
                  icon: const AppForwardChevron(),
                ),
              ],
            ),
            SizedBox(
              height: pageHeight,
              child: PageView.builder(
                controller: pages,
                itemCount: collection.entries.length,
                onPageChanged: _onPage,
                itemBuilder: (context, page) => SingleChildScrollView(
                  child: DhikrCard(
                    key: ValueKey('${collection.id}:$page'),
                    collection: collection,
                    dhikr: collection.entries[page],
                    number: page + 1,
                    onCount: () => _count(collection, page),
                    onUndo: () => ref
                        .read(adhkarProgressProvider.notifier)
                        .decrement(collection, collection.entries[page]),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
