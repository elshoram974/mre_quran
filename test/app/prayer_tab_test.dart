import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/app/quran_app.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';
import 'package:mre_quran/features/adhan/application/adhan_providers.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/startup/application/startup_providers.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';

import '../helpers/adhan_fixtures.dart';
import '../helpers/adhkar_fixtures.dart';
import '../helpers/fake_quran_metadata_source.dart';
import '../helpers/fake_quran_text_source.dart';
import '../helpers/memory_bookmarks_repository.dart';
import '../helpers/memory_last_tab_repository.dart';
import '../helpers/memory_reading_position_repository.dart';
import '../helpers/memory_settings_repository.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  String locale = 'ar',
  String start = '/reader',
  PrayerPlace? place,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final settings = MemorySettingsRepository();
  settings.settings = settings.settings.copyWith(localeCode: locale);
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(settings),
      lastTabRepositoryProvider.overrideWithValue(MemoryLastTabRepository()),
      initialLocationProvider.overrideWithValue(start),
      quranMetadataSourceProvider.overrideWithValue(FakeQuranMetadataSource()),
      readingPositionRepositoryProvider.overrideWithValue(
        MemoryReadingPositionRepository(),
      ),
      quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
      bookmarksRepositoryProvider.overrideWithValue(
        MemoryBookmarksRepository(),
      ),
      prayerRepositoryProvider.overrideWithValue(
        MemoryPrayerRepository()..place = place,
      ),
      locationSourceProvider.overrideWithValue(FakeLocationSource()),
      reminderSchedulerProvider.overrideWithValue(FakeReminderScheduler()),
      adhanPlatformProvider.overrideWithValue(FakeAdhanPlatform()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const QuranApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('the Adhan tab sits between the Adhkar and the settings', () {
    expect(AppRoute.tabs, [
      AppRoute.reader,
      AppRoute.duas,
      AppRoute.prayerTimes,
      AppRoute.settings,
    ]);
  });

  for (final (locale, label) in [('ar', 'الأذان'), ('en', 'Adhan')]) {
    testWidgets('the bar has an Adhan tab that opens the prayer times in '
        '$locale', (tester) async {
      await _pump(tester, locale: locale);
      await tester.tap(find.byIcon(Icons.mosque_outlined).first);
      await tester.pumpAndSettle();
      // The shell's bar names the tab, and the page is the prayer times.
      expect(find.text(label), findsWidgets);
      expect(
        find.text(locale == 'ar' ? 'اعرف مواقيت الصلاة' : 'Find prayer times'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('back from the Adhan tab returns to the Mushaf', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester, start: AppRoute.prayerTimes.path);
    expect(find.text('اعرف مواقيت الصلاة'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('اعرف مواقيت الصلاة'), findsNothing);
    expect(find.text('إغلاق التطبيق؟'), findsNothing);
  });

  for (final (name, size) in [
    ('compact', const Size(320, 640)),
    ('medium', const Size(700, 900)),
    ('expanded', const Size(1194, 834)),
  ]) {
    testWidgets('five tabs fit the $name window', (tester) async {
      await _pump(tester, size: size);
      await tester.tap(find.byIcon(Icons.mosque_outlined).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
