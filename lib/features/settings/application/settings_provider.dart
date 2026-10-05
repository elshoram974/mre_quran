import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/crash/crash_reporter.dart';
import '../../../core/diagnostics/app_logger.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

/// Provides the device-local settings store.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => LocalSettingsRepository(SharedPreferencesAsync()),
);

/// Reports failures only when the reader has explicitly opted in.
final crashReporterProvider = Provider<CrashReporter>(
  (ref) => const NoopCrashReporter(),
);

/// Loads and updates persisted [AppSettings].
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Application settings state owner.
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);
  CrashReporter get _crashReporter => ref.read(crashReporterProvider);

  @override
  FutureOr<AppSettings> build() => _repository.load();

  /// Applies [next] immediately and persists it in the background.
  ///
  /// The new value is visible at once so theme and locale changes never wait
  /// on storage. If saving fails the previous value is restored.
  Future<void> save(AppSettings next) async {
    final previous = state.value;
    state = AsyncData(next);
    try {
      await _repository.save(next);
      await _crashReporter.setCollectionEnabled(next.crashReportsEnabled);
    } on Object catch (error) {
      AppLogger.debug('Settings save failed: ${error.runtimeType}');
      if (previous != null) state = AsyncData(previous);
    }
  }
}
