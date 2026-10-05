import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

/// Provides the device-local settings store.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => LocalSettingsRepository(SharedPreferencesAsync()),
);

/// Loads and updates persisted [AppSettings].
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Application settings state owner.
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  FutureOr<AppSettings> build() => _repository.load();

  Future<void> update(AppSettings next) async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.save(next);
      return next;
    });
    if (state.hasError && previous != null) {
      state = AsyncData(previous);
    }
  }
}
