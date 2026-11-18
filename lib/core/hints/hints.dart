import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The hints the app offers once it is the right moment, each in a sheet.
enum AppHint {
  /// Before the first permission request: what is asked for, and why.
  permissions,

  /// Once prayer alerts are on: hear the adhan now, before the first prayer.
  tryAdhan,

  /// An invitation to configure prayer alerts and the adhan.
  configureAdhan,

  /// Explain why prayer alerts need exact alarms when first enabled.
  exactPrayerTiming,

  /// After the adhan was tried: put the prayer times on the home screen.
  tryWidgets,

  /// When a page of the printed Mushaf is not on the device yet: the Mushaf
  /// needs the internet, except for the pages already opened.
  offlineMushaf,
}

/// Remembers the hints the person asked never to see again.
abstract interface class HintsRepository {
  /// The hints turned off for good.
  Future<Set<AppHint>> dismissed();

  /// Turns [hint] off for good.
  Future<void> dismiss(AppHint hint);
}

/// [HintsRepository] in the app's preferences.
class LocalHintsRepository implements HintsRepository {
  /// Creates the repository over [preferences].
  LocalHintsRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const String _key = 'hints.dismissed';

  @override
  Future<Set<AppHint>> dismissed() async {
    final names = await _preferences.getStringList(_key) ?? const [];
    return {
      for (final hint in AppHint.values)
        if (names.contains(hint.name)) hint,
    };
  }

  @override
  Future<void> dismiss(AppHint hint) async {
    final names = {...?await _preferences.getStringList(_key), hint.name};
    await _preferences.setStringList(_key, names.toList());
  }
}

/// Provides the store. Tests override it.
final hintsRepositoryProvider = Provider<HintsRepository>(
  (ref) => LocalHintsRepository(SharedPreferencesAsync()),
);

/// Which hints may still be shown.
@immutable
class HintsState {
  /// Creates the state.
  const HintsState({required this.dismissed, required this.shown});

  /// Turned off for good.
  final Set<AppHint> dismissed;

  /// Already shown since the app started: a hint comes at most once a run.
  final Set<AppHint> shown;

  /// Whether [hint] may be shown now.
  bool allows(AppHint hint) =>
      !dismissed.contains(hint) && !shown.contains(hint);
}

/// The hints that may still be shown, and the person's answers.
final hintsProvider = AsyncNotifierProvider<HintsNotifier, HintsState>(
  HintsNotifier.new,
);

/// Owns [hintsProvider].
class HintsNotifier extends AsyncNotifier<HintsState> {
  @override
  Future<HintsState> build() async {
    Set<AppHint> dismissed;
    try {
      dismissed = await ref.read(hintsRepositoryProvider).dismissed();
    } on Object {
      // Unreadable: every hint may come, once a run as always.
      dismissed = const {};
    }
    return HintsState(dismissed: dismissed, shown: const {});
  }

  /// Takes [hint] for showing now: true when it may be shown, and from then
  /// on it is not shown again this run.
  Future<bool> take(AppHint hint) async {
    final current = await future;
    if (!current.allows(hint)) return false;
    state = AsyncData(
      HintsState(dismissed: current.dismissed, shown: {...current.shown, hint}),
    );
    return true;
  }

  /// Turns [hint] off for good.
  Future<void> dismiss(AppHint hint) async {
    final current = await future;
    state = AsyncData(
      HintsState(dismissed: {...current.dismissed, hint}, shown: current.shown),
    );
    await ref.read(hintsRepositoryProvider).dismiss(hint);
  }
}
