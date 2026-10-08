import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../data/adhkar_progress_repository.dart';
import '../data/adhkar_source.dart';
import '../domain/adhkar_collection.dart';
import '../domain/adhkar_progress.dart';
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

  String get _today => AdhkarProgress.dayOf(ref.read(adhkarClockProvider)());

  @override
  Future<AdhkarProgress> build() => _repository.load(_today);

  /// Counts one more repeat of [dhikr]. Returns whether it is now finished.
  Future<bool> increment(AdhkarCollection collection, Dhikr dhikr) async {
    final next = _current.increment(collection, dhikr);
    await _apply(next);
    return next.isDone(collection, dhikr);
  }

  /// Takes back one repeat of [dhikr].
  Future<void> decrement(AdhkarCollection collection, Dhikr dhikr) =>
      _apply(_current.decrement(collection, dhikr));

  /// Clears today's counts of [collection].
  Future<void> reset(AdhkarCollection collection) =>
      _apply(_current.reset(collection));

  /// Progress for today, dropping counts left over from an earlier day.
  AdhkarProgress get _current {
    final saved = state.value;
    return saved != null && saved.day == _today
        ? saved
        : AdhkarProgress(day: _today);
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
  final today = AdhkarProgress.dayOf(ref.read(adhkarClockProvider)());
  return progress != null && progress.day == today ? progress : null;
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
