import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/app/shell/expanding_nav_rail.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mre_quran/app/quran_app.dart';
import 'package:mre_quran/app/shell/expanding_nav_bar.dart';
import 'package:mre_quran/features/mushaf/application/reader_immersive_provider.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_pager.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_times_page.dart';
import 'package:mre_quran/features/settings/presentation/settings_page.dart';
import 'package:mre_quran/features/startup/application/startup_providers.dart';

import 'helpers/fake_quran_metadata_source.dart';
import 'helpers/fake_quran_text_source.dart';
import 'helpers/memory_last_tab_repository.dart';
import 'helpers/memory_bookmarks_repository.dart';
import 'helpers/memory_reading_position_repository.dart';
import 'helpers/memory_settings_repository.dart';

void main() {
  for (final width in [320.0, 600.0, 840.0]) {
    testWidgets('Arabic navigation adapts at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = MemorySettingsRepository();
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          lastTabRepositoryProvider.overrideWithValue(
            MemoryLastTabRepository(),
          ),
          quranMetadataSourceProvider.overrideWithValue(
            FakeQuranMetadataSource(),
          ),
          readingPositionRepositoryProvider.overrideWithValue(
            MemoryReadingPositionRepository(),
          ),
          quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
          bookmarksRepositoryProvider.overrideWithValue(
            MemoryBookmarksRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const QuranApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        Directionality.of(tester.element(find.byType(Scaffold).first)),
        TextDirection.rtl,
      );
      // A bar up to 839 wide (phones and a portrait iPad), a rail from 840.
      expect(
        find.byType(ExpandingNavBar),
        width < 840 ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(ExpandingNavRail),
        width < 840 ? findsNothing : findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.mosque_outlined).first);
      await tester.pumpAndSettle();
      expect(find.byType(PrayerTimesPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reader settings shortcut opens settings', (tester) async {
    final repository = MemorySettingsRepository()
      ..settings = const AppSettings(readerMode: ReaderMode.text);
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repository),
        lastTabRepositoryProvider.overrideWithValue(MemoryLastTabRepository()),
        quranMetadataSourceProvider.overrideWithValue(
          FakeQuranMetadataSource(),
        ),
        readingPositionRepositoryProvider.overrideWithValue(
          MemoryReadingPositionRepository(),
        ),
        quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
        bookmarksRepositoryProvider.overrideWithValue(
          MemoryBookmarksRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const QuranApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined).hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage).hitTestable(), findsOneWidget);
  });

  testWidgets('English locale uses left-to-right direction', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemorySettingsRepository()
      ..settings = const AppSettings(
        localeCode: 'en',
        readerMode: ReaderMode.text,
      );
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repository),
        lastTabRepositoryProvider.overrideWithValue(MemoryLastTabRepository()),
        quranMetadataSourceProvider.overrideWithValue(
          FakeQuranMetadataSource(),
        ),
        readingPositionRepositoryProvider.overrideWithValue(
          MemoryReadingPositionRepository(),
        ),
        quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
        bookmarksRepositoryProvider.overrideWithValue(
          MemoryBookmarksRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const QuranApp()),
    );
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.ltr,
    );
    expect(find.byTooltip('Index'), findsWidgets);
  });

  testWidgets('Large Arabic text has no layout exception', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
        lastTabRepositoryProvider.overrideWithValue(MemoryLastTabRepository()),
        quranMetadataSourceProvider.overrideWithValue(
          FakeQuranMetadataSource(),
        ),
        readingPositionRepositoryProvider.overrideWithValue(
          MemoryReadingPositionRepository(),
        ),
        quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
        bookmarksRepositoryProvider.overrideWithValue(
          MemoryBookmarksRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const QuranApp()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS uses liquid glass chrome, Android uses Material', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
        lastTabRepositoryProvider.overrideWithValue(MemoryLastTabRepository()),
        quranMetadataSourceProvider.overrideWithValue(
          FakeQuranMetadataSource(),
        ),
        readingPositionRepositoryProvider.overrideWithValue(
          MemoryReadingPositionRepository(),
        ),
        quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
        bookmarksRepositoryProvider.overrideWithValue(
          MemoryBookmarksRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    Future<void> pump() async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const QuranApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await pump();
    // The same pill as Android's, its chosen tab named beside its icon, in
    // liquid glass.
    expect(find.byType(ExpandingNavBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ExpandingNavBar),
        matching: find.byType(GlassContainer),
      ),
      findsOneWidget,
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(const SizedBox());
    await pump();
    expect(find.byType(ExpandingNavBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ExpandingNavBar),
        matching: find.byType(GlassContainer),
      ),
      findsNothing,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('on iOS a SnackBar from any tab is shown', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
        lastTabRepositoryProvider.overrideWithValue(MemoryLastTabRepository()),
        quranMetadataSourceProvider.overrideWithValue(
          FakeQuranMetadataSource(),
        ),
        readingPositionRepositoryProvider.overrideWithValue(
          MemoryReadingPositionRepository(),
        ),
        quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
        bookmarksRepositoryProvider.overrideWithValue(
          MemoryBookmarksRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const QuranApp()),
    );
    await tester.pumpAndSettle();

    ScaffoldMessenger.of(tester.element(find.byType(ExpandingNavBar)))
        .showSnackBar(const SnackBar(content: Text('hello')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('hello'), findsOneWidget);
    // It floats above the glass bar, not behind it.
    final surface = find.descendant(
      of: find.byType(SnackBar),
      matching: find.byType(Material),
    );
    expect(
      tester.getRect(surface.first).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(GlassContainer).first).top),
    );
  });

  testWidgets('the Mushaf keeps clear of the Android navigation bar', (
    tester,
  ) async {
    // Edge to edge: a 48 px three-button bar is drawn over the app.
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
        lastTabRepositoryProvider.overrideWithValue(MemoryLastTabRepository()),
        quranMetadataSourceProvider.overrideWithValue(
          FakeQuranMetadataSource(),
        ),
        readingPositionRepositoryProvider.overrideWithValue(
          MemoryReadingPositionRepository()..page = 22,
        ),
        quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
        bookmarksRepositoryProvider.overrideWithValue(
          MemoryBookmarksRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const QuranApp()),
    );
    await tester.pumpAndSettle();
    final withBars = tester.getRect(find.byType(MushafPager));
    container.read(readerImmersiveProvider.notifier).toggle();
    await tester.pumpAndSettle();
    final immersive = tester.getRect(find.byType(MushafPager));
    // The tab bar's Scaffold drops the bottom inset; the page must not.
    expect(withBars.bottom, 780 - 48);
    expect(immersive, withBars, reason: 'hiding the bars never moves the page');
    expect(tester.getRect(find.text('٢٢')).bottom, lessThanOrEqualTo(732));
  });
}
