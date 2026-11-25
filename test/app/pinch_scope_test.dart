import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/app/quran_app.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';
import 'package:mre_quran/core/widgets/pinch_zoom.dart';
import 'package:mre_quran/features/adhan/application/adhan_providers.dart';
import 'package:mre_quran/features/adhkar/application/adhkar_providers.dart';
import 'package:mre_quran/features/adhkar/application/favorites_provider.dart';
import 'package:mre_quran/features/adhkar/application/reminders_provider.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/startup/application/startup_providers.dart';

import '../helpers/adhan_fixtures.dart';
import '../helpers/adhkar_fixtures.dart';
import '../helpers/fake_quran_metadata_source.dart';
import '../helpers/fake_quran_text_source.dart';
import '../helpers/memory_bookmarks_repository.dart';
import '../helpers/memory_last_tab_repository.dart';
import '../helpers/memory_reading_position_repository.dart';
import '../helpers/memory_settings_repository.dart';

Future<ProviderContainer> _pump(WidgetTester tester, String start) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(MemorySettingsRepository()),
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
      adhkarSourceProvider.overrideWithValue(FakeAdhkarSource(null)),
      adhkarProgressRepositoryProvider.overrideWithValue(
        MemoryAdhkarProgressRepository(),
      ),
      remindersRepositoryProvider.overrideWithValue(
        MemoryRemindersRepository(),
      ),
      adhkarFavoritesRepositoryProvider.overrideWithValue(
        MemoryFavoritesRepository(),
      ),
      prayerRepositoryProvider.overrideWithValue(MemoryPrayerRepository()),
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
  testWidgets('the text of the Mushaf can be pinched', (tester) async {
    await _pump(tester, AppRoute.reader.path);
    expect(find.byType(PinchZoom), findsWidgets);
  });

  for (final tab in [AppRoute.duas, AppRoute.prayerTimes, AppRoute.settings]) {
    testWidgets('the ${tab.name} tab has nothing to pinch, and two fingers '
        'change no text on it', (tester) async {
      final container = await _pump(tester, tab.path);
      expect(find.byType(PinchZoom), findsNothing);
      final before = container.read(settingsProvider).value!;
      final centre = tester.getCenter(find.byType(Scaffold).first);
      final a = await tester.startGesture(centre - const Offset(50, 0));
      final b = await tester.startGesture(centre + const Offset(50, 0));
      await a.moveTo(centre - const Offset(120, 0));
      await b.moveTo(centre + const Offset(120, 0));
      await tester.pump();
      // The app's own text is not scaled by a pinch, wherever it is.
      expect(
        MediaQuery.textScalerOf(tester.element(find.byType(Scaffold).first))
            .scale(10),
        10,
      );
      await a.up();
      await b.up();
      await tester.pumpAndSettle();
      final after = container.read(settingsProvider).value!;
      expect(after.readerFontScale, before.readerFontScale);
      expect(after.adhkarFontScale, before.adhkarFontScale);
    });
  }
}
