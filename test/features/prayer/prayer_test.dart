import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';
import 'package:mre_quran/core/time/ticking_clock.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/domain/prayer_alerts.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_settings_repository.dart';

final _cairo = PrayerPlace(30.0444, 31.2357);
final _now = DateTime(2026, 10, 8, 3);

void main() {
  group('method for a place', () {
    final cases = <String, (double, double, PrayerMethod)>{
      'Cairo': (30.04, 31.24, PrayerMethod.egyptian),
      'Amman': (31.95, 35.93, PrayerMethod.egyptian),
      'Khartoum': (15.5, 32.56, PrayerMethod.egyptian),
      'Riyadh': (24.71, 46.68, PrayerMethod.ummAlQura),
      'Makkah': (21.42, 39.83, PrayerMethod.ummAlQura),
      'Dubai': (25.2, 55.27, PrayerMethod.dubai),
      'Kuwait City': (29.37, 47.98, PrayerMethod.kuwait),
      'Doha': (25.29, 51.53, PrayerMethod.qatar),
      'Istanbul': (41.01, 28.98, PrayerMethod.turkey),
      'Karachi': (24.86, 67.0, PrayerMethod.karachi),
      'Jakarta': (-6.2, 106.82, PrayerMethod.singapore),
      'New York': (40.71, -74.0, PrayerMethod.northAmerica),
      'London': (51.51, -0.13, PrayerMethod.muslimWorldLeague),
      'Casablanca': (33.57, -7.59, PrayerMethod.muslimWorldLeague),
    };
    for (final entry in cases.entries) {
      test('${entry.key} follows its region', () {
        final (lat, lng, method) = entry.value;
        expect(PrayerMethod.forPlace(PrayerPlace(lat, lng)), method);
      });
    }
  });

  group('PrayerDay and the next prayer', () {
    test('the five times and sunrise come in order', () {
      final day = PrayerDay.compute(_cairo, PrayerMethod.egyptian, _now);
      final order = [
        day.fajr,
        day.sunrise,
        day.dhuhr,
        day.asr,
        day.maghrib,
        day.isha,
      ];
      for (var i = 1; i < order.length; i++) {
        expect(order[i].isAfter(order[i - 1]), isTrue, reason: '$i');
      }
    });

    test('the next prayer is today\'s, or tomorrow\'s Fajr after Isha', () {
      final day = PrayerDay.compute(_cairo, PrayerMethod.egyptian, _now);
      final before = day.dhuhr.subtract(const Duration(minutes: 5));
      final next = nextPrayer(_cairo, PrayerMethod.egyptian, before);
      expect(next.prayer, DailyPrayer.dhuhr);
      expect(next.at, day.dhuhr);

      final late = day.isha.add(const Duration(minutes: 5));
      final tomorrow = nextPrayer(_cairo, PrayerMethod.egyptian, late);
      expect(tomorrow.prayer, DailyPrayer.fajr);
      expect(tomorrow.at.isAfter(late), isTrue);
      expect(tomorrow.at.day, isNot(day.fajr.day));
    });

    test('a place is rounded to about a kilometre', () {
      final place = PrayerPlace(30.04449, 31.23571);
      expect(place.latitude, 30.04);
      expect(place.longitude, 31.24);
      expect(PrayerPlace.tryFromJson({'lat': 120, 'lng': 0}), isNull);
      expect(PrayerPlace.tryFromJson('x'), isNull);
    });
  });

  group('PrayerAlertPlan', () {
    List<PrayerAlert> plan(PrayerSettings settings, {DateTime? now}) =>
        PrayerAlertPlan.compute(
          place: _cairo,
          settings: settings,
          now: now ?? _now,
        );

    test('nothing is planned when nothing is on', () {
      expect(plan(const PrayerSettings()), isEmpty);
    });

    test('an alert for each chosen prayer, at its time, for a week', () {
      final alerts = plan(
        const PrayerSettings(alerts: {DailyPrayer.fajr, DailyPrayer.maghrib}),
      );
      expect(alerts, hasLength(14));
      expect(alerts.every((a) => a.kind == PrayerAlertKind.atTime), isTrue);
      final first = PrayerDay.compute(_cairo, PrayerMethod.egyptian, _now);
      expect(alerts.first.prayer, DailyPrayer.fajr);
      expect(alerts.first.at, first.fajr);
      for (var i = 1; i < alerts.length; i++) {
        expect(alerts[i].at.isAfter(alerts[i - 1].at), isTrue);
      }
    });

    test('the adhkar reminder follows each prayer by the chosen delay', () {
      final alerts = plan(
        const PrayerSettings(adhkarReminder: true, afterMinutes: 20),
      );
      expect(alerts, hasLength(35));
      expect(
        alerts.every((a) => a.kind == PrayerAlertKind.afterPrayer),
        isTrue,
      );
      final day = PrayerDay.compute(_cairo, PrayerMethod.egyptian, _now);
      expect(alerts.first.at, day.fajr.add(const Duration(minutes: 20)));
    });

    test('both kinds together use different ids, all inside the range', () {
      final alerts = plan(
        PrayerSettings(
          adhkarReminder: true,
          alerts: DailyPrayer.values.toSet(),
        ),
      );
      expect(alerts, hasLength(70));
      expect(alerts.map((a) => a.id).toSet(), hasLength(70));
      expect(
        alerts.every((a) => PrayerAlertPlan.allIds.contains(a.id)),
        isTrue,
      );
    });

    test('past prayers are dropped', () {
      final late = DateTime(2026, 10, 8, 23, 59);
      final alerts = plan(
        PrayerSettings(alerts: DailyPrayer.values.toSet()),
        now: late,
      );
      expect(alerts.every((a) => a.at.isAfter(late)), isTrue);
    });

    test('with no method chosen the place decides; a chosen method wins', () {
      final riyadh = PrayerPlace(24.71, 46.68);
      DateTime fajr(PrayerSettings settings) => PrayerAlertPlan.compute(
        place: riyadh,
        settings: settings,
        now: _now,
      ).first.at;
      const alerts = {DailyPrayer.fajr};
      final automatic = fajr(const PrayerSettings(alerts: alerts));
      final umm = fajr(
        const PrayerSettings(alerts: alerts, method: PrayerMethod.ummAlQura),
      );
      final egyptian = fajr(
        const PrayerSettings(alerts: alerts, method: PrayerMethod.egyptian),
      );
      expect(automatic, umm);
      expect(umm, isNot(egyptian));
    });

    test('settings survive storage; bad data gives the defaults', () {
      const settings = PrayerSettings(
        adhkarReminder: true,
        method: PrayerMethod.karachi,
        afterMinutes: 30,
        alerts: {DailyPrayer.asr, DailyPrayer.isha},
      );
      final back = PrayerSettings.fromJson(settings.toJson());
      expect(back.adhkarReminder, isTrue);
      expect(back.method, PrayerMethod.karachi);
      expect(back.afterMinutes, 30);
      expect(back.alerts, {DailyPrayer.asr, DailyPrayer.isha});
      final automatic = PrayerSettings.fromJson(
        const PrayerSettings().toJson(),
      );
      expect(automatic.method, isNull);
      final bad = PrayerSettings.fromJson({
        'after': 7,
        'method': 'x',
        'alerts': ['zz'],
      });
      expect(bad.afterMinutes, 15);
      expect(bad.method, isNull);
      expect(bad.alerts, isEmpty);
      expect(PrayerSettings.fromJson(null).needsSchedule, isFalse);
    });

    test('copyWith can go back to the automatic method', () {
      const chosen = PrayerSettings(method: PrayerMethod.dubai);
      expect(chosen.copyWith(automaticMethod: true).method, isNull);
      expect(chosen.copyWith(afterMinutes: 10).method, PrayerMethod.dubai);
    });
  });

  group('PrayerNotifier', () {
    ProviderContainer container({
      required FakeReminderScheduler scheduler,
      required FakeLocationSource location,
      MemoryPrayerRepository? repository,
      MemorySettingsRepository? settings,
    }) {
      final c = ProviderContainer(
        overrides: [
          reminderSchedulerProvider.overrideWithValue(scheduler),
          locationSourceProvider.overrideWithValue(location),
          prayerRepositoryProvider.overrideWithValue(
            repository ?? MemoryPrayerRepository(),
          ),
          clockProvider.overrideWithValue(() => _now),
          settingsRepositoryProvider.overrideWithValue(
            settings ?? MemorySettingsRepository(),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('starts with no place, no alerts, and asks for nothing', () async {
      final location = FakeLocationSource(requestResult: _cairo);
      final scheduler = FakeReminderScheduler();
      final c = container(scheduler: scheduler, location: location);
      final state = await c.read(prayerProvider.future);
      expect(state.place, isNull);
      expect(state.method, isNull);
      expect(location.requests, 0);
      expect(scheduler.permissionRequests, 0);
    });

    test(
      'locating saves the place and shows the method that fits it',
      () async {
        final repo = MemoryPrayerRepository();
        final c = container(
          scheduler: FakeReminderScheduler(),
          location: FakeLocationSource(
            requestResult: PrayerPlace(24.71, 46.68),
          ),
          repository: repo,
        );
        await c.read(prayerProvider.future);
        expect(await c.read(prayerProvider.notifier).locate(), PrayerResult.ok);
        final state = c.read(prayerProvider).value!;
        expect(state.settings.method, isNull);
        expect(state.method, PrayerMethod.ummAlQura);
        expect(repo.place, state.place);
      },
    );

    test('a refused location leaves everything as it was', () async {
      final c = container(
        scheduler: FakeReminderScheduler(),
        location: FakeLocationSource(),
      );
      await c.read(prayerProvider.future);
      expect(
        await c.read(prayerProvider.notifier).locate(),
        PrayerResult.locationDenied,
      );
      expect(c.read(prayerProvider).value!.place, isNull);
    });

    test(
      'an alert asks for notifications and location, then schedules it',
      () async {
        final scheduler = FakeReminderScheduler();
        final location = FakeLocationSource(requestResult: _cairo);
        final c = container(scheduler: scheduler, location: location);
        await c.read(prayerProvider.future);

        final result = await c
            .read(prayerProvider.notifier)
            .setAlert(DailyPrayer.fajr, true);

        expect(result, PrayerResult.ok);
        expect(scheduler.permissionRequests, 1);
        expect(location.requests, 1);
        expect(scheduler.once, hasLength(7));
        final sample = scheduler.once.values.first;
        expect(sample.channel, ReminderChannel.prayer);
        expect(sample.exact, isTrue);
        expect(sample.payload, 'prayer:times');
        expect(sample.title, 'حان وقت صلاة الفجر');
        expect(c.read(prayerProvider).value!.settings.alerts, {
          DailyPrayer.fajr,
        });
      },
    );

    test('a second alert does not ask for the location again', () async {
      final location = FakeLocationSource(requestResult: _cairo);
      final c = container(
        scheduler: FakeReminderScheduler(),
        location: location,
      );
      await c.read(prayerProvider.future);
      final notifier = c.read(prayerProvider.notifier);
      await notifier.setAlert(DailyPrayer.fajr, true);
      await notifier.setAlert(DailyPrayer.isha, true);
      expect(location.requests, 1);
      expect(c.read(prayerProvider).value!.settings.alerts, hasLength(2));
      await notifier.setAlert(DailyPrayer.fajr, false);
      expect(c.read(prayerProvider).value!.settings.alerts, {DailyPrayer.isha});
    });

    test('all five on, then all off cancels everything', () async {
      final scheduler = FakeReminderScheduler();
      final c = container(
        scheduler: scheduler,
        location: FakeLocationSource(requestResult: _cairo),
      );
      await c.read(prayerProvider.future);
      final notifier = c.read(prayerProvider.notifier);
      await notifier.setAllAlerts(true);
      expect(scheduler.once, hasLength(35));
      await notifier.setAllAlerts(false);
      expect(scheduler.once, isEmpty);
    });

    test(
      'stays off, with a reason, when notifications or location are refused',
      () async {
        final c1 = container(
          scheduler: FakeReminderScheduler(allow: false),
          location: FakeLocationSource(requestResult: _cairo),
        );
        await c1.read(prayerProvider.future);
        expect(
          await c1
              .read(prayerProvider.notifier)
              .setAlert(DailyPrayer.asr, true),
          PrayerResult.notificationsDenied,
        );
        expect(c1.read(prayerProvider).value!.settings.alerts, isEmpty);

        final scheduler = FakeReminderScheduler();
        final c2 = container(
          scheduler: scheduler,
          location: FakeLocationSource(),
        );
        await c2.read(prayerProvider.future);
        expect(
          await c2.read(prayerProvider.notifier).setAdhkarReminder(true),
          PrayerResult.locationDenied,
        );
        expect(c2.read(prayerProvider).value!.settings.adhkarReminder, isFalse);
        expect(scheduler.once, isEmpty);
      },
    );

    test('the adhkar reminder opens the after-prayer list', () async {
      final scheduler = FakeReminderScheduler();
      final c = container(
        scheduler: scheduler,
        location: FakeLocationSource(requestResult: _cairo),
      );
      await c.read(prayerProvider.future);
      await c.read(prayerProvider.notifier).setAdhkarReminder(true);
      final sample = scheduler.once.values.first;
      expect(sample.channel, ReminderChannel.adhkar);
      expect(sample.exact, isFalse);
      expect(sample.payload, 'adhkar:after_prayer');
      expect(sample.title, 'حان وقت أذكار بعد الصلاة');
    });

    test(
      'a new method or delay schedules again; null goes back to automatic',
      () async {
        final scheduler = FakeReminderScheduler();
        final c = container(
          scheduler: scheduler,
          location: FakeLocationSource(requestResult: _cairo),
        );
        await c.read(prayerProvider.future);
        final notifier = c.read(prayerProvider.notifier);
        await notifier.setAlert(DailyPrayer.fajr, true);
        final before = scheduler.once.values.first.at;
        await notifier.setMethod(PrayerMethod.karachi);
        expect(c.read(prayerProvider).value!.method, PrayerMethod.karachi);
        expect(scheduler.once.values.first.at, isNot(before));
        await notifier.setMethod(null);
        expect(c.read(prayerProvider).value!.settings.method, isNull);
        expect(c.read(prayerProvider).value!.method, PrayerMethod.egyptian);
        expect(scheduler.once.values.first.at, before);
      },
    );

    test('exact alarms are requested through the scheduler', () async {
      final scheduler = FakeReminderScheduler();
      final c = container(scheduler: scheduler, location: FakeLocationSource());
      await c.read(prayerProvider.future);
      await c.read(prayerProvider.notifier).allowExactAlarms();
      expect(scheduler.exactRequests, 1);
    });

    test(
      'at start-up saved alerts are scheduled again without asking',
      () async {
        final scheduler = FakeReminderScheduler();
        final location = FakeLocationSource(quietResult: _cairo);
        final repo = MemoryPrayerRepository()
          ..settings = const PrayerSettings(alerts: {DailyPrayer.dhuhr});
        final c = container(
          scheduler: scheduler,
          location: location,
          repository: repo,
        );
        await c.read(prayerProvider.future);
        await Future<void>.delayed(Duration.zero);
        expect(location.requests, 0);
        expect(location.quietReads, 1);
        expect(scheduler.permissionRequests, 0);
        expect(scheduler.once, hasLength(7));
      },
    );

    test('the texts follow the app language', () async {
      final scheduler = FakeReminderScheduler();
      final repo = MemoryPrayerRepository()
        ..settings = const PrayerSettings(alerts: {DailyPrayer.fajr})
        ..place = _cairo;
      final c = container(
        scheduler: scheduler,
        location: FakeLocationSource(),
        repository: repo,
        settings: MemorySettingsRepository()
          ..settings = const AppSettings(localeCode: 'en'),
      );
      await c.read(settingsProvider.future);
      await c.read(prayerProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(scheduler.once.values.first.title, 'Time for the Fajr prayer');
    });
  });
}
