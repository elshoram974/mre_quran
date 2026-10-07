import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mre_quran/core/crash/crash_reporter.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';

import '../../../helpers/memory_settings_repository.dart';

void main() {
  group('SettingsNotifier', () {
    test('loads and persists an updated preference', () async {
      final repository = MemorySettingsRepository();
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          crashReporterProvider.overrideWithValue(FakeCrashReporter()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(settingsProvider.future),
        repository.settings,
      );

      await container
          .read(settingsProvider.notifier)
          .save(
            const AppSettings(
              theme: AppThemePreference.sepia,
              localeCode: 'en',
            ),
          );

      expect(repository.settings.theme, AppThemePreference.sepia);
      expect(repository.settings.localeCode, 'en');
    });

    test('applies at once and rolls back when saving fails', () async {
      final repository = MemorySettingsRepository();
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          crashReporterProvider.overrideWithValue(FakeCrashReporter()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(settingsProvider.future);
      repository.fail = true;

      await container
          .read(settingsProvider.notifier)
          .save(const AppSettings(theme: AppThemePreference.dark));

      expect(container.read(settingsProvider).value, repository.settings);
    });

    test('shows the new value before storage finishes', () async {
      final repository = MemorySettingsRepository();
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          crashReporterProvider.overrideWithValue(FakeCrashReporter()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(settingsProvider.future);

      final pending = container
          .read(settingsProvider.notifier)
          .save(const AppSettings(theme: AppThemePreference.dark));

      expect(
        container.read(settingsProvider).value?.theme,
        AppThemePreference.dark,
      );
      expect(container.read(settingsProvider).isLoading, isFalse);
      await pending;
    });

    test('persists explicit crash-report consent', () async {
      final repository = MemorySettingsRepository();
      final crashReporter = FakeCrashReporter();
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          crashReporterProvider.overrideWithValue(crashReporter),
        ],
      );
      addTearDown(container.dispose);
      await container.read(settingsProvider.future);

      await container
          .read(settingsProvider.notifier)
          .save(const AppSettings(crashReportsEnabled: true));

      expect(repository.settings.crashReportsEnabled, isTrue);
      expect(crashReporter.enabledValues, [true]);
    });
  });
}

class FakeCrashReporter implements CrashReporter {
  final List<bool> enabledValues = [];

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    enabledValues.add(enabled);
  }

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {}

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {}
}
