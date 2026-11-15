import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/theme/app_palette.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/theme/quran_colors.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/data/settings_repository.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/features/settings/presentation/theme_pickers.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/memory_settings_repository.dart';

void main() {
  group('LocalSettingsRepository', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('keeps the page theme and the accent', () async {
      final repository = LocalSettingsRepository(SharedPreferencesAsync());
      await repository.save(
        const AppSettings(
          theme: AppThemePreference.black,
          accent: AppAccent.teal,
        ),
      );
      final loaded = await repository.load();
      expect(loaded.theme, AppThemePreference.black);
      expect(loaded.accent, AppAccent.teal);
    });

    test(
      'starts gold, and reads themes saved before accents existed',
      () async {
        final preferences = SharedPreferencesAsync();
        await preferences.setString('settings.theme', 'dark');
        final loaded = await LocalSettingsRepository(preferences).load();
        expect(loaded.theme, AppThemePreference.dark);
        expect(loaded.accent, AppAccent.gold);
      },
    );
  });

  test('every page theme maps to the brightness of its paper', () {
    for (final theme in AppThemePreference.values) {
      final mode = AppSettings(theme: theme).materialThemeMode;
      expect(mode, switch (theme) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.dark || AppThemePreference.black => ThemeMode.dark,
        _ => ThemeMode.light,
      }, reason: theme.name);
    }
  });

  test('the accent colours ayah numbers and the paper colours the page', () {
    final quran = AppTheme.of(
      AppPaper.green,
      AppAccent.crimson,
    ).extension<QuranColors>()!;
    final scheme = AppPalette.scheme(AppPaper.green, AppAccent.crimson);
    expect(quran.ayahNumber, scheme.primary);
    expect(quran.paper, scheme.surface);
    expect(quran.ink, scheme.onSurface);
  });

  testWidgets('the pickers change the page theme and the accent', (
    tester,
  ) async {
    final repository = MemorySettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(
            body: SingleChildScrollView(child: ThemePickers()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('أسود'));
    await tester.pumpAndSettle();
    expect(repository.settings.theme, AppThemePreference.black);

    await tester.tap(find.bySemanticsLabel('فيروزي'));
    await tester.pumpAndSettle();
    expect(repository.settings.accent, AppAccent.teal);
    expect(
      tester.getSemantics(find.bySemanticsLabel('فيروزي')),
      matchesSemantics(
        label: 'فيروزي',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('the pickers wrap without overflow at large text in English', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(child: ThemePickers()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
