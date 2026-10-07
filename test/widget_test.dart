import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mre_quran/app/quran_app.dart';
import 'package:mre_quran/features/mushaf/application/reader_immersive_provider.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_pager.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
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
      expect(
        find.byType(NavigationBar),
        width < 600 ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(NavigationRail),
        width < 600 ? findsNothing : findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.bookmarks_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('لا توجد علامات بعد'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('English locale uses left-to-right direction', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemorySettingsRepository()
      ..settings = const AppSettings(
        localeCode: 'en',
        readerMode: ReaderMode.text,
        editionsIntroSeen: true,
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
    await pump();
    expect(find.byType(GlassTabBar), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(const SizedBox());
    await pump();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(GlassTabBar), findsNothing);
    debugDefaultTargetPlatformOverride = null;
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
