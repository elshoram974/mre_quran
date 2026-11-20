import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
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

final class _DelayedPreferences extends InMemorySharedPreferencesAsync {
  _DelayedPreferences() : super.empty();

  final started = <String>{};
  final gate = Completer<void>();

  Future<void> _wait(String key) {
    started.add(key);
    return gate.future;
  }

  @override
  Future<String?> getString(
    String key,
    SharedPreferencesOptions options,
  ) async {
    await _wait(key);
    return super.getString(key, options);
  }

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) async {
    await _wait(key);
    return super.getBool(key, options);
  }

  @override
  Future<double?> getDouble(
    String key,
    SharedPreferencesOptions options,
  ) async {
    await _wait(key);
    return super.getDouble(key, options);
  }
}

void main() {
  group('LocalSettingsRepository', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test(
      'starts all independent settings reads before waiting for storage',
      () async {
        final platform = _DelayedPreferences();
        SharedPreferencesAsyncPlatform.instance = platform;
        final loading = LocalSettingsRepository(SharedPreferencesAsync())
            .load();
        try {
          await Future<void>.delayed(Duration.zero);
          expect(platform.started, hasLength(16));
          expect(
            platform.started,
            containsAll([
              'settings.haptics',
              'settings.surah_frame',
              'settings.widget_seconds',
              'settings.widget_locale',
            ]),
          );
        } finally {
          platform.gate.complete();
        }
        expect((await loading).hapticsEnabled, isTrue);
      },
    );

    test(
      'keeps the widgets\' language, and follows the app by default',
      () async {
        final repository = LocalSettingsRepository(SharedPreferencesAsync());
        var loaded = await repository.load();
        expect(loaded.widgetLocaleCode, 'app');
        expect(loaded.widgetLanguage, loaded.localeCode);
        await repository.save(
          const AppSettings(localeCode: 'ar', widgetLocaleCode: 'en'),
        );
        loaded = await repository.load();
        expect(loaded.widgetLocaleCode, 'en');
        expect(loaded.widgetLanguage, 'en');
        await repository.save(const AppSettings(localeCode: 'en'));
        expect((await repository.load()).widgetLanguage, 'en');
        // Anything else is the app's own.
        await repository.save(const AppSettings(widgetLocaleCode: 'fr'));
        expect((await repository.load()).widgetLocaleCode, 'app');
      },
    );

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
      'keeps the reading of the printed Mushaf, and starts on Hafs',
      () async {
        final repository = LocalSettingsRepository(SharedPreferencesAsync());
        expect((await repository.load()).mushafEdition, MushafEditions.hafs);
        for (final edition in MushafEditions.all) {
          await repository.save(AppSettings(mushafEdition: edition));
          expect((await repository.load()).mushafEdition, edition);
        }
      },
    );

    test('keeps the surah name frame, and starts on the pointed one', () async {
      final preferences = SharedPreferencesAsync();
      final repository = LocalSettingsRepository(preferences);
      expect((await repository.load()).surahFrame, SurahFrameStyle.cartouche);
      for (final style in SurahFrameStyle.values) {
        await repository.save(AppSettings(surahFrame: style));
        expect((await repository.load()).surahFrame, style);
      }
      await preferences.setString('settings.surah_frame', 'gone');
      expect((await repository.load()).surahFrame, SurahFrameStyle.cartouche);
    });

    test('a reading it does not know falls back to Hafs', () async {
      final preferences = SharedPreferencesAsync();
      await preferences.setString('settings.mushaf_edition', 'unknown-kfqc');
      final loaded = await LocalSettingsRepository(preferences).load();
      expect(loaded.mushafEdition, MushafEditions.hafs);
    });

    test('only Hafs is the app\'s own text; Hafs and Warsh draw their '
        'lines in order', () {
      for (final edition in MushafEditions.all) {
        final hafs = edition == MushafEditions.hafs;
        expect(edition.matchesAppText, hafs, reason: edition.id);
        // Only these draw their script line by line on most pages
        // (tool/check_svg_lines.dart: 591 and 469 of 604).
        expect(
          edition.linesInDrawingOrder,
          hafs || edition == MushafEditions.warsh,
          reason: edition.id,
        );
      }
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
          localizationsDelegates: appLocalizationsDelegates,
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
          localizationsDelegates: appLocalizationsDelegates,
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
