import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/adhkar/application/adhkar_providers.dart';
import 'package:mre_quran/features/adhkar/application/reminders_provider.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_collection.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_progress.dart';
import 'package:mre_quran/core/notifications/reminder_payload.dart';
import 'package:mre_quran/features/adhkar/domain/reminder_setting.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_settings_repository.dart';

import 'package:mre_quran/core/time/ticking_clock.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';

ProviderContainer _container({
  MemoryAdhkarProgressRepository? progress,
  MemoryRemindersRepository? reminders,
  FakeReminderScheduler? scheduler,
  MemorySettingsRepository? settings,
  DateTime Function()? clock,
  AdhkarCatalog? catalog,
}) {
  final container = ProviderContainer(
    overrides: [
      adhkarSourceProvider.overrideWithValue(FakeAdhkarSource(catalog)),
      adhkarProgressRepositoryProvider.overrideWithValue(
        progress ?? MemoryAdhkarProgressRepository(),
      ),
      remindersRepositoryProvider.overrideWithValue(
        reminders ?? MemoryRemindersRepository(),
      ),
      reminderSchedulerProvider.overrideWithValue(
        scheduler ?? FakeReminderScheduler(),
      ),
      settingsRepositoryProvider.overrideWithValue(
        settings ?? MemorySettingsRepository(),
      ),
      clockProvider.overrideWithValue(clock ?? () => DateTime(2026, 10, 8, 9)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('AdhkarProgressNotifier', () {
    test(
      'a tap shows at once, saves, and reports when the dhikr is done',
      () async {
        final repo = MemoryAdhkarProgressRepository();
        final container = _container(progress: repo);
        final catalog = await container.read(adhkarCatalogProvider.future);
        final morning = catalog.byId('morning')!;
        await container.read(adhkarProgressProvider.future);
        final notifier = container.read(adhkarProgressProvider.notifier);

        expect(
          await notifier.increment(morning, morning.entries.first),
          isTrue,
        );
        expect(
          container.read(dhikrCountProvider((morning, morning.entries.first))),
          1,
        );
        expect(repo.saved?.counts, {'morning:1': 1});
        expect(await notifier.increment(morning, morning.entries[1]), isFalse);
        expect(
          container.read(collectionProgressProvider(morning)).doneEntries,
          1,
        );
      },
    );

    test('rolls back when saving fails', () async {
      final repo = MemoryAdhkarProgressRepository()..fail = true;
      final container = _container(progress: repo);
      final morning = (await container.read(adhkarCatalogProvider.future))
          .byId('morning')!;
      await container.read(adhkarProgressProvider.future);
      await container
          .read(adhkarProgressProvider.notifier)
          .increment(morning, morning.entries.first);
      expect(
        container.read(dhikrCountProvider((morning, morning.entries.first))),
        0,
      );
    });

    test('counts start again on a new day', () async {
      final repo = MemoryAdhkarProgressRepository()
        ..saved = const AdhkarProgress(
          day: '2026-10-07',
          counts: {'morning:1': 1},
        );
      final container = _container(progress: repo);
      final morning = (await container.read(adhkarCatalogProvider.future))
          .byId('morning')!;
      await container.read(adhkarProgressProvider.future);
      expect(
        container.read(dhikrCountProvider((morning, morning.entries.first))),
        0,
      );
    });

    test(
      'a count left open past midnight does not carry into the next day',
      () async {
        var now = DateTime(2026, 10, 8, 23, 59);
        final container = _container(clock: () => now);
        final morning = (await container.read(adhkarCatalogProvider.future))
            .byId('morning')!;
        await container.read(adhkarProgressProvider.future);
        final notifier = container.read(adhkarProgressProvider.notifier);
        await notifier.increment(morning, morning.entries[1]);
        now = DateTime(2026, 10, 9, 0, 1);
        await notifier.increment(morning, morning.entries[1]);
        expect(container.read(adhkarProgressProvider).value!.day, '2026-10-09');
        expect(
          container.read(dhikrCountProvider((morning, morning.entries[1]))),
          1,
        );
      },
    );

    test('undo and restart change only what they should', () async {
      final container = _container();
      final catalog = await container.read(adhkarCatalogProvider.future);
      final morning = catalog.byId('morning')!;
      final evening = catalog.byId('evening')!;
      await container.read(adhkarProgressProvider.future);
      final notifier = container.read(adhkarProgressProvider.notifier);
      await notifier.increment(morning, morning.entries[1]);
      await notifier.increment(morning, morning.entries[1]);
      await notifier.increment(evening, evening.entries.first);
      await notifier.decrement(morning, morning.entries[1]);
      expect(
        container.read(dhikrCountProvider((morning, morning.entries[1]))),
        1,
      );
      await notifier.reset(morning);
      expect(
        container.read(dhikrCountProvider((morning, morning.entries[1]))),
        0,
      );
      expect(
        container.read(dhikrCountProvider((evening, evening.entries.first))),
        1,
      );
    });
  });

  group('prayer lists', () {
    test('the open list leads while its window lasts, then lets go', () async {
      var now = DateTime(2026, 10, 8, 13);
      final container = _container(
        clock: () => now,
        catalog: fixtureCatalogWithPrayer(),
      );
      final catalog = await container.read(adhkarCatalogProvider.future);
      final prayer = catalog.byId('after_prayer')!;
      await container.read(adhkarProgressProvider.future);
      expect(container.read(activeSessionProvider), isNull);

      await container
          .read(adhkarProgressProvider.notifier)
          .increment(prayer, prayer.entries.first);
      expect(container.read(activeSessionProvider), prayer);

      now = now.add(const Duration(minutes: 31));
      container.read(tickingNowProvider.notifier).refresh();
      expect(container.read(activeSessionProvider), isNull);
      expect(
        container.read(dhikrCountProvider((prayer, prayer.entries.first))),
        0,
      );
    });

    test('a finished list is not offered again as the open one', () async {
      final container = _container(catalog: fixtureCatalogWithPrayer());
      final prayer = (await container.read(adhkarCatalogProvider.future))
          .byId('after_prayer')!;
      await container.read(adhkarProgressProvider.future);
      final notifier = container.read(adhkarProgressProvider.notifier);
      for (final entry in prayer.entries) {
        for (var i = 0; i < entry.repeat; i++) {
          await notifier.increment(prayer, entry);
        }
      }
      expect(
        container.read(collectionProgressProvider(prayer)).complete,
        isTrue,
      );
      expect(container.read(activeSessionProvider), isNull);
    });

    test(
      'next goes to the following unfinished list of the same group',
      () async {
        final container = _container(catalog: fixtureCatalogWithPrayer());
        final catalog = await container.read(adhkarCatalogProvider.future);
        final morning = catalog.byId('morning')!;
        final evening = catalog.byId('evening')!;
        await container.read(adhkarProgressProvider.future);
        expect(container.read(nextCollectionProvider(morning)), isNot(morning));
        expect(container.read(nextCollectionProvider(morning))!.group, kDaily);
        expect(container.read(nextCollectionProvider(evening))!.id, 'sleep');
        // A group of one has nothing to go on to.
        final prayer = catalog.byId('after_prayer')!;
        expect(container.read(nextCollectionProvider(prayer)), isNull);
      },
    );
  });

  group('RemindersNotifier', () {
    test('starts off, at each collection\'s default time', () async {
      final container = _container();
      final settings = await container.read(remindersProvider.future);
      expect(
        settings['morning'],
        const ReminderSetting(enabled: false, minutes: 330),
      );
      expect(
        settings['evening'],
        const ReminderSetting(enabled: false, minutes: 1050),
      );
    });

    test('turning one on asks permission, saves, and schedules it', () async {
      final scheduler = FakeReminderScheduler();
      final repo = MemoryRemindersRepository();
      final container = _container(scheduler: scheduler, reminders: repo);
      final catalog = await container.read(adhkarCatalogProvider.future);
      await container.read(remindersProvider.future);
      final morning = catalog.byId('morning')!;

      final result = await container
          .read(remindersProvider.notifier)
          .setEnabled(morning, true);

      expect(result, ReminderToggleResult.enabled);
      expect(scheduler.permissionRequests, 1);
      final id = ReminderPayload.notificationId('morning');
      expect(scheduler.scheduled[id]!.minutes, 330);
      expect(scheduler.scheduled[id]!.title, 'أذكار الصباح');
      expect(scheduler.scheduled[id]!.body, 'حان وقت أذكارك. اضغط للقراءة.');
      expect(scheduler.scheduled[id]!.payload, 'adhkar:morning');
      expect(repo.saved['morning']!.enabled, isTrue);
    });

    test('stays off when notifications are not allowed', () async {
      final scheduler = FakeReminderScheduler(allow: false);
      final container = _container(scheduler: scheduler);
      final morning = (await container.read(adhkarCatalogProvider.future))
          .byId('morning')!;
      await container.read(remindersProvider.future);

      final result = await container
          .read(remindersProvider.notifier)
          .setEnabled(morning, true);

      expect(result, ReminderToggleResult.permissionDenied);
      expect(scheduler.scheduled, isEmpty);
      expect(
        container.read(remindersProvider).value!['morning']!.enabled,
        isFalse,
      );
    });

    test('a new time reschedules; turning off cancels', () async {
      final scheduler = FakeReminderScheduler();
      final container = _container(scheduler: scheduler);
      final morning = (await container.read(adhkarCatalogProvider.future))
          .byId('morning')!;
      await container.read(remindersProvider.future);
      final notifier = container.read(remindersProvider.notifier);
      final id = ReminderPayload.notificationId('morning');

      await notifier.setEnabled(morning, true);
      await notifier.setTime(morning, 6 * 60);
      expect(scheduler.scheduled[id]!.minutes, 360);

      expect(
        await notifier.setEnabled(morning, false),
        ReminderToggleResult.disabled,
      );
      expect(scheduler.scheduled, isEmpty);
    });

    test('saved reminders are scheduled again at start-up', () async {
      final scheduler = FakeReminderScheduler();
      final repo = MemoryRemindersRepository()
        ..saved = {
          'evening': const ReminderSetting(enabled: true, minutes: 1080),
        };
      final container = _container(scheduler: scheduler, reminders: repo);
      await container.read(remindersProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(
        scheduler.scheduled[ReminderPayload.notificationId('evening')]!.minutes,
        1080,
      );
    });

    test('the texts follow the app language', () async {
      final scheduler = FakeReminderScheduler();
      final repo = MemoryRemindersRepository()
        ..saved = {
          'morning': const ReminderSetting(enabled: true, minutes: 330),
        };
      final container = _container(
        scheduler: scheduler,
        reminders: repo,
        settings: MemorySettingsRepository()
          ..settings = const AppSettings(localeCode: 'en'),
      );
      await container.read(settingsProvider.future);
      await container.read(remindersProvider.future);
      await Future<void>.delayed(Duration.zero);
      final scheduled =
          scheduler.scheduled[ReminderPayload.notificationId('morning')]!;
      expect(scheduled.title, 'Morning adhkar');
      expect(scheduled.body, 'Time for your adhkar. Tap to read.');
    });

    test('a failed save leaves the reminder as it was', () async {
      final repo = MemoryRemindersRepository()..fail = true;
      final scheduler = FakeReminderScheduler();
      final container = _container(scheduler: scheduler, reminders: repo);
      final morning = (await container.read(adhkarCatalogProvider.future))
          .byId('morning')!;
      await container.read(remindersProvider.future);
      await container
          .read(remindersProvider.notifier)
          .setEnabled(morning, true);
      expect(
        container.read(remindersProvider).value!['morning']!.enabled,
        isFalse,
      );
      expect(scheduler.scheduled, isEmpty);
    });
  });
}
