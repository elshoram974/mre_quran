import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores when the adhan suggestion was last shown, on this device only.
abstract interface class AdhanSuggestionStore {
  Future<DateTime?> lastShown();
  Future<void> markShown(DateTime when);
}

class _LocalAdhanSuggestionStore implements AdhanSuggestionStore {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const _key = 'adhan.suggestion.lastShown';

  @override
  Future<DateTime?> lastShown() async {
    final millis = await _preferences.getInt(_key);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<void> markShown(DateTime when) =>
      _preferences.setInt(_key, when.millisecondsSinceEpoch);
}

/// Provides the local suggestion history.
final adhanSuggestionStoreProvider = Provider<AdhanSuggestionStore>(
  (ref) => _LocalAdhanSuggestionStore(),
);

/// Whether a suggestion is useful and its quiet period has elapsed.
bool shouldSuggestAdhan({
  required bool alertsEnabled,
  required bool adhanEnabled,
  required DateTime now,
  required DateTime? lastShown,
}) {
  if (alertsEnabled && adhanEnabled) return false;
  return lastShown == null ||
      now.difference(lastShown) >= const Duration(days: 7);
}
