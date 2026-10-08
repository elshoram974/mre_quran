import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../data/favorites_repository.dart';

/// Provides the favourites store.
final adhkarFavoritesRepositoryProvider = Provider<AdhkarFavoritesRepository>(
  (ref) => LocalAdhkarFavoritesRepository(SharedPreferencesAsync()),
);

/// The starred list ids, oldest first.
final adhkarFavoritesProvider =
    AsyncNotifierProvider<AdhkarFavoritesNotifier, List<String>>(
      AdhkarFavoritesNotifier.new,
    );

/// Whether one list is starred, so a star rebuilds only for its own list.
final isAdhkarFavoriteProvider = Provider.family<bool, String>(
  (ref, id) => ref.watch(adhkarFavoritesProvider).value?.contains(id) ?? false,
);

/// Owns the favourites. A change shows at once and is saved in the
/// background; a failed save restores the previous list.
class AdhkarFavoritesNotifier extends AsyncNotifier<List<String>> {
  AdhkarFavoritesRepository get _repository =>
      ref.read(adhkarFavoritesRepositoryProvider);

  @override
  Future<List<String>> build() => _repository.load();

  /// Stars [id], or removes the star if it is there.
  Future<void> toggle(String id) async {
    final current = state.value ?? const <String>[];
    final next = current.contains(id)
        ? [
            for (final item in current)
              if (item != id) item,
          ]
        : [...current, id];
    final previous = state.value;
    state = AsyncData(next);
    try {
      await _repository.save(next);
    } on Object catch (error) {
      AppLogger.debug('Favourites save failed: ${error.runtimeType}');
      if (previous != null) state = AsyncData(previous);
    }
  }
}
