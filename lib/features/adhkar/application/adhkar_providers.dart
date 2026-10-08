import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/application/quran_text_providers.dart';
import '../../quran_text/domain/quran_text.dart';
import '../data/adhkar_progress_repository.dart';
import '../data/adhkar_source.dart';
import '../domain/adhkar_collection.dart';
import '../domain/adhkar_progress.dart';
import '../domain/adhkar_search.dart';
import '../domain/dhikr.dart';

/// Provides the bundled adhkar source. Tests override it.
final adhkarSourceProvider = Provider<AdhkarSource>((ref) => AdhkarSource());

/// Verified adhkar, loaded once and kept for the session.
final adhkarCatalogProvider = FutureProvider<AdhkarCatalog>(
  (ref) => ref.watch(adhkarSourceProvider).load(),
);

/// The current local time. Tests override it.
final adhkarClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// The current time as the adhkar screens see it, re-read every 30 seconds so
/// a prayer window that ends, or a day that turns, shows without a restart.
final adhkarNowProvider = NotifierProvider<AdhkarNow, DateTime>(AdhkarNow.new);

/// Holds [adhkarNowProvider]'s time.
class AdhkarNow extends Notifier<DateTime> {
  @override
  DateTime build() {
    final timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    ref.onDispose(timer.cancel);
    return ref.read(adhkarClockProvider)();
  }

  /// Reads the clock again.
  void refresh() => state = ref.read(adhkarClockProvider)();
}

/// Provides the progress store.
final adhkarProgressRepositoryProvider = Provider<AdhkarProgressRepository>(
  (ref) => LocalAdhkarProgressRepository(SharedPreferencesAsync()),
);

/// What the person has said today.
final adhkarProgressProvider =
    AsyncNotifierProvider<AdhkarProgressNotifier, AdhkarProgress>(
      AdhkarProgressNotifier.new,
    );

/// Owns today's counts. A tap shows at once and is saved in the background; a
/// failed save restores the previous counts. A new local day starts from zero.
class AdhkarProgressNotifier extends AsyncNotifier<AdhkarProgress> {
  AdhkarProgressRepository get _repository =>
      ref.read(adhkarProgressRepositoryProvider);

  DateTime get _now => ref.read(adhkarClockProvider)();

  String get _today => AdhkarProgress.dayOf(_now);

  @override
  Future<AdhkarProgress> build() => _repository.load(_today);

  /// Counts one more repeat of [dhikr]. Returns whether it is now finished.
  Future<bool> increment(AdhkarCollection collection, Dhikr dhikr) async {
    final next = _current.increment(collection, dhikr, now: _now);
    await _apply(next);
    return next.isDone(collection, dhikr);
  }

  /// Takes back one repeat of [dhikr].
  Future<void> decrement(AdhkarCollection collection, Dhikr dhikr) =>
      _apply(_current.decrement(collection, dhikr, now: _now));

  /// Clears today's counts of [collection].
  Future<void> reset(AdhkarCollection collection) =>
      _apply(_current.reset(collection));

  /// Progress for now: counts left from an earlier day or from a prayer
  /// window that has passed are dropped.
  AdhkarProgress get _current {
    final saved = state.value;
    final base = saved != null && saved.day == _today
        ? saved
        : AdhkarProgress(day: _today);
    final catalog = ref.read(adhkarCatalogProvider).value;
    return catalog == null ? base : base.settle(catalog.collections, _now);
  }

  Future<void> _apply(AdhkarProgress next) async {
    final previous = state.value;
    state = AsyncData(next);
    try {
      await _repository.save(next);
    } on Object catch (error) {
      AppLogger.debug('Adhkar progress save failed: ${error.runtimeType}');
      if (previous != null) state = AsyncData(previous);
    }
  }
}

AdhkarProgress? _today(Ref ref) {
  final progress = ref.watch(adhkarProgressProvider).value;
  final now = ref.watch(adhkarNowProvider);
  if (progress == null || progress.day != AdhkarProgress.dayOf(now)) {
    return null;
  }
  final catalog = ref.watch(adhkarCatalogProvider).value;
  return catalog == null ? progress : progress.settle(catalog.collections, now);
}

/// Today's progress of one collection, so a card rebuilds only when its own
/// numbers change.
final collectionProgressProvider =
    Provider.family<
      ({int doneEntries, int totalEntries, double fraction, bool complete}),
      AdhkarCollection
    >((ref, collection) {
      final progress = _today(ref);
      final total = collection.totalRepeats;
      return (
        doneEntries: progress?.doneEntries(collection) ?? 0,
        totalEntries: collection.entries.length,
        fraction: progress == null || total == 0
            ? 0.0
            : progress.doneRepeats(collection) / total,
        complete: progress?.isComplete(collection) ?? false,
      );
    });

/// Times one dhikr was said today, so its card rebuilds only on its own taps.
final dhikrCountProvider = Provider.family<int, (AdhkarCollection, Dhikr)>((
  ref,
  key,
) {
  return _today(ref)?.countOf(key.$1, key.$2) ?? 0;
});

/// The prayer list the person is in the middle of, if any: counted within its
/// window and not finished. The tab leads with it.
final activeSessionProvider = Provider<AdhkarCollection?>((ref) {
  final progress = _today(ref);
  final catalog = ref.watch(adhkarCatalogProvider).value;
  if (progress == null || catalog == null) return null;
  final now = ref.watch(adhkarNowProvider);
  for (final collection in catalog.collections) {
    if (progress.isSessionActive(collection, now) &&
        !progress.isComplete(collection)) {
      return collection;
    }
  }
  return null;
});

/// The next unfinished collection of the same group after [collection], or
/// null when there is none.
final nextCollectionProvider =
    Provider.family<AdhkarCollection?, AdhkarCollection>((ref, collection) {
      final progress = _today(ref);
      final catalog = ref.watch(adhkarCatalogProvider).value;
      if (catalog == null) return null;
      final same = [
        for (final other in catalog.collections)
          if (other.group == collection.group) other,
      ];
      final start = same.indexOf(collection);
      for (var step = 1; step < same.length; step++) {
        final other = same[(start + step) % same.length];
        if (progress == null || !progress.isComplete(other)) return other;
      }
      return null;
    });

/// Search over list names and the words of every dhikr. The words of Quran
/// dhikr join once the Quran text has loaded; until then they are left out.
final adhkarSearchIndexProvider = FutureProvider<AdhkarSearchIndex>((
  ref,
) async {
  final catalog = await ref.watch(adhkarCatalogProvider.future);
  QuranText? quran;
  try {
    quran = await ref.watch(quranTextProvider.future);
  } on Object catch (error) {
    AppLogger.debug('Search without Quran text: ${error.runtimeType}');
  }
  return AdhkarSearchIndex(
    catalog,
    quranWords: (dhikr) {
      final passage = dhikr.quran;
      if (quran == null || passage == null) return null;
      return [
        for (final span in passage.spans)
          for (var ayah = span.from; ayah <= span.to; ayah++)
            quran.clean(AyahRef(span.surah, ayah)),
      ].join(' ');
    },
  );
});
