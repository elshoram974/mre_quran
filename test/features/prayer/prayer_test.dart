import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/adhkar/application/prayer_reminders_provider.dart';
import 'package:mre_quran/features/adhkar/application/reminders_provider.dart';
import 'package:mre_quran/features/adhkar/domain/prayer_reminders.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_settings_repository.dart';

final _cairo = PrayerPlace(30.0444, 31.2357);

void main() {
  group('PrayerReminderPlan', () {
    final now = DateTime(2026, 10, 8, 3);

    test(
      'plans five prayers a day for a week, in order, all in the future',
      () {
        final plan = PrayerReminderPlan.compute(
          place: _cairo,
          settings: const PrayerReminderSettings(enabled: true),
          now: now,
        );
        expect(plan, hasLength(35));
        expect(plan.every((reminder) => reminder.at.isAfter(now)), isTrue);
        final first = plan.take(5).map((reminder) => reminder.prayer).toList();
        expect(first, DailyPrayer.values);
        for (var i = 1; i < plan.length; i++) {
          expect(plan[i].at.isAfter(plan[i - 1].at), isTrue, reason: '$i');
        }
        expect(plan.map((reminder) => reminder.id).toSet(), hasLength(35));
        expect(
          plan.every((r) => PrayerReminderPlan.allIds.contains(r.id)),
          isTrue,
        );
      },
    );

    test('drops the prayers already past today', () {
      final late = DateTime(2026, 10, 8, 23, 59);
      final plan = PrayerReminderPlan.compute(
        place: _cairo,
        settings: const PrayerReminderSettings(enabled: true),
        now: late,
      );
      expect(plan.first.at.isAfter(late), isTrue);
      expect(plan.length, lessThanOrEqualTo(35));
    });

    test('the delay moves every reminder by the same amount', () {
      List<PrayerReminder> plan(int after) => PrayerReminderPlan.compute(
        place: _cairo,
        settings: PrayerReminderSettings(enabled: true, afterMinutes: after),
        now: now,
      );
      final short = plan(10);
      final long = plan(30);
      for (var i = 0; i < short.length; i++) {
        expect(long[i].at.difference(short[i].at), const Duration(minutes: 20));
      }
    });

    test('the method changes the times', () {
      DateTime fajr(PrayerMethod method) => PrayerReminderPlan.compute(
        place: _cairo,
        settings: PrayerReminderSettings(enabled: true, method: method),
        now: now,
      ).first.at;
      expect(fajr(PrayerMethod.egyptian), isNot(fajr(PrayerMethod.karachi)));
    });

    test('a place is rounded to about a kilometre', () {
      final place = PrayerPlace(30.04449, 31.23571);
      expect(place.latitude, 30.04);
      expect(place.longitude, 31.24);
      expect(PrayerPlace.tryFromJson({'lat': 120, 'lng': 0}), isNull);
      expect(PrayerPlace.tryFromJson('x'), isNull);
    });

    test('settings survive storage and bad data gives the defaults', () {
      const settings = PrayerReminderSettings(
        enabled: true,
        method: PrayerMethod.ummAlQura,
        afterMinutes: 30,
      );
      final back = PrayerReminderSettings.fromJson(settings.toJson());
      expect(back.enabled, isTrue);
      expect(back.method, PrayerMethod.ummAlQura);
      expect(back.afterMinutes, 30);
      final bad = PrayerReminderSettings.fromJson({'after': 7, 'method': 'x'});
      expect(bad.afterMinutes, 15);
      expect(bad.method, PrayerMethod.egyptian);
      expect(PrayerReminderSettings.fromJson(null).enabled, isFalse);
    });
  });

  group('PrayerRemindersNotifier', () {
    ProviderContainer container({
      required FakeReminderScheduler scheduler,
      required FakeLocationSource location,
      MemoryPrayerRemindersRepository? repository,
      MemorySettingsRepository? settings,
    }) {
      final c = ProviderContainer(
        overrides: [
          reminderSchedulerProvider.overrideWithValue(scheduler),
          locationSourceProvider.overrideWithValue(location),
          prayerRemindersRepositoryProvider.overrideWithValue(
            repository ?? MemoryPrayerRemindersRepository(),
          ),
          settingsRepositoryProvider.overrideWithValue(
            settings ?? MemorySettingsRepository(),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test(
      'turning on asks for notifications, then location, then schedules',
      () async {
        final scheduler = FakeReminderScheduler();
        final location = FakeLocationSource(requestResult: _cairo);
        final repo = MemoryPrayerRemindersRepository();
        final c = container(
          scheduler: scheduler,
          location: location,
          repository: repo,
        );
        await c.read(prayerRemindersProvider.future);
        expect(location.requests, 0, reason: 'starting never asks');

        final result = await c
            .read(prayerRemindersProvider.notifier)
            .setEnabled(true);

        expect(result, PrayerToggleResult.enabled);
        expect(scheduler.permissionRequests, 1);
        expect(location.requests, 1);
        expect(scheduler.once, isNotEmpty);
        expect(
          scheduler.once.keys.every(PrayerReminderPlan.allIds.contains),
          isTrue,
        );
        final sample = scheduler.once.values.first;
        expect(sample.payload, 'adhkar:after_prayer');
        expect(sample.title, 'حان وقت أذكار بعد الصلاة');
        expect(sample.body, startsWith('بعد صلاة'));
        expect(repo.settings.enabled, isTrue);
        expect(repo.place, isNotNull);
      },
    );

    test(
      'stays off, with a reason, when notifications or location are refused',
      () async {
        final noNotifications = FakeReminderScheduler(allow: false);
        final c1 = container(
          scheduler: noNotifications,
          location: FakeLocationSource(requestResult: _cairo),
        );
        await c1.read(prayerRemindersProvider.future);
        expect(
          await c1.read(prayerRemindersProvider.notifier).setEnabled(true),
          PrayerToggleResult.notificationsDenied,
        );
        expect(
          c1.read(prayerRemindersProvider).value!.settings.enabled,
          isFalse,
        );

        final location = FakeLocationSource();
        final scheduler = FakeReminderScheduler();
        final c2 = container(scheduler: scheduler, location: location);
        await c2.read(prayerRemindersProvider.future);
        expect(
          await c2.read(prayerRemindersProvider.notifier).setEnabled(true),
          PrayerToggleResult.locationDenied,
        );
        expect(
          c2.read(prayerRemindersProvider).value!.settings.enabled,
          isFalse,
        );
        expect(scheduler.once, isEmpty);
      },
    );

    test('turning off cancels every prayer reminder', () async {
      final scheduler = FakeReminderScheduler();
      final c = container(
        scheduler: scheduler,
        location: FakeLocationSource(requestResult: _cairo),
      );
      await c.read(prayerRemindersProvider.future);
      final notifier = c.read(prayerRemindersProvider.notifier);
      await notifier.setEnabled(true);
      expect(scheduler.once, isNotEmpty);
      await notifier.setEnabled(false);
      expect(scheduler.once, isEmpty);
    });

    test('a new method or delay schedules them again', () async {
      final scheduler = FakeReminderScheduler();
      final c = container(
        scheduler: scheduler,
        location: FakeLocationSource(requestResult: _cairo),
      );
      await c.read(prayerRemindersProvider.future);
      final notifier = c.read(prayerRemindersProvider.notifier);
      await notifier.setEnabled(true);
      final before = {
        for (final e in scheduler.once.entries) e.key: e.value.at,
      };
      await notifier.setAfterMinutes(30);
      final after = {for (final e in scheduler.once.entries) e.key: e.value.at};
      expect(after.keys.toSet(), before.keys.toSet());
      for (final id in after.keys) {
        expect(after[id]!.isAfter(before[id]!), isTrue);
      }
      await notifier.setMethod(PrayerMethod.karachi);
      expect(
        c.read(prayerRemindersProvider).value!.settings.method,
        PrayerMethod.karachi,
      );
    });

    test(
      'at start-up saved reminders are scheduled again without asking',
      () async {
        final scheduler = FakeReminderScheduler();
        final location = FakeLocationSource(quietResult: _cairo);
        final repo = MemoryPrayerRemindersRepository()
          ..settings = const PrayerReminderSettings(enabled: true);
        final c = container(
          scheduler: scheduler,
          location: location,
          repository: repo,
        );
        await c.read(prayerRemindersProvider.future);
        await Future<void>.delayed(Duration.zero);
        expect(location.requests, 0);
        expect(location.quietReads, 1);
        expect(scheduler.permissionRequests, 0);
        expect(scheduler.once, isNotEmpty);
      },
    );

    test('the texts follow the app language', () async {
      final scheduler = FakeReminderScheduler();
      final repo = MemoryPrayerRemindersRepository()
        ..settings = const PrayerReminderSettings(enabled: true)
        ..place = _cairo;
      final c = container(
        scheduler: scheduler,
        location: FakeLocationSource(),
        repository: repo,
        settings: MemorySettingsRepository()
          ..settings = const AppSettings(localeCode: 'en'),
      );
      await c.read(settingsProvider.future);
      await c.read(prayerRemindersProvider.future);
      await Future<void>.delayed(Duration.zero);
      final sample = scheduler.once.values.first;
      expect(sample.title, 'Time for adhkar after prayer');
      expect(sample.body, startsWith('After the '));
    });
  });
}
