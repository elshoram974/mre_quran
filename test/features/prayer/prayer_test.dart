import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' show Placemark;
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';
import 'package:mre_quran/core/time/ticking_clock.dart';
import 'package:mre_quran/features/prayer/application/place_search_provider.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/data/location_source.dart';
import 'package:mre_quran/features/prayer/data/place_name_source.dart';
import 'package:mre_quran/features/prayer/domain/prayer_alerts.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_labels.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/prayer_soon_fixtures.dart';
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
    test('coordinates keep signs, precision and direction in mixed text', () {
      expect(
        formatPrayerCoordinate(-30.9994, (value) => value),
        '\u2066-30.9994\u2069',
      );
      expect(
        formatPrayerCoordinate(30.9999, (value) => value),
        '\u206630.9999\u2069',
      );
    });
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

    test('a place is rounded to four decimal degrees', () {
      final place = PrayerPlace(30.04449, 31.23571);
      expect(place.latitude, 30.0445);
      expect(place.longitude, 31.2357);
      expect(PrayerPlace.tryFromJson({'lat': 120, 'lng': 0}), isNull);
      expect(PrayerPlace.tryFromJson({'lat': double.nan, 'lng': 0}), isNull);
      expect(PrayerPlace.tryFromJson('x'), isNull);
    });

    test(
      'legacy settings keep the saved location fixed until chosen again',
      () {
        expect(
          PrayerSettings.fromJson({
            'alerts': ['fajr'],
          }).automaticLocation,
          isFalse,
        );
        expect(PrayerSettings.fromJson(null).automaticLocation, isTrue);
      },
    );
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
        const PrayerSettings(
          alerts: {DailyPrayer.fajr, DailyPrayer.maghrib},
          beforeReminder: false,
        ),
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
      // Before, at, and after each of five prayers, for seven days.
      expect(alerts, hasLength(105));
      expect(alerts.map((a) => a.id).toSet(), hasLength(105));
      expect(alerts.every((a) => PrayerAlertPlan.owns(a.id)), isTrue);
    });

    test('a month of alerts keeps every kind inside its own ids', () {
      final alerts = PrayerAlertPlan.compute(
        place: _cairo,
        settings: PrayerSettings(
          adhkarReminder: true,
          alerts: DailyPrayer.values.toSet(),
        ),
        now: _now,
        days: PrayerAlertPlan.maxDays,
      );
      expect(alerts.map((a) => a.id).toSet(), hasLength(alerts.length));
      for (final kind in PrayerAlertKind.values) {
        final first = switch (kind) {
          PrayerAlertKind.afterPrayer => PrayerAlertPlan.firstAfterId,
          PrayerAlertKind.atTime => PrayerAlertPlan.firstAtTimeId,
          PrayerAlertKind.beforePrayer => PrayerAlertPlan.firstBeforeId,
        };
        expect(
          alerts
              .where((a) => a.kind == kind)
              .every((a) => a.id >= first && a.id < first + 1000),
          isTrue,
          reason: kind.name,
        );
      }
      expect(PrayerAlertPlan.owns(42), isFalse);
    });

    test('the reminder before comes its minutes ahead, only for prayers '
        'that alert, and can be turned off', () {
      final alerts = plan(
        const PrayerSettings(alerts: {DailyPrayer.asr}, beforeMinutes: 20),
      );
      final before = alerts.where(
        (a) => a.kind == PrayerAlertKind.beforePrayer,
      );
      expect(before, hasLength(7));
      expect(before.every((a) => a.prayer == DailyPrayer.asr), isTrue);
      final asr = alerts.firstWhere((a) => a.kind == PrayerAlertKind.atTime);
      expect(asr.at.difference(before.first.at), const Duration(minutes: 20));
      expect(
        plan(
          const PrayerSettings(
            alerts: {DailyPrayer.asr},
            beforeReminder: false,
          ),
        ).where((a) => a.kind == PrayerAlertKind.beforePrayer),
        isEmpty,
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
        beforeReminder: false,
        beforeMinutes: 30,
        beforeCountdown: false,
      );
      final back = PrayerSettings.fromJson(settings.toJson());
      expect(back.beforeReminder, isFalse);
      expect(back.beforeMinutes, 30);
      expect(back.beforeCountdown, isFalse);
      // Saved before the reminder existed: it is on, 15 minutes ahead, and
      // counts down.
      final old = PrayerSettings.fromJson(const <String, Object?>{'on': true});
      expect(old.beforeReminder, isTrue);
      expect(old.beforeMinutes, 15);
      expect(old.beforeCountdown, isTrue);
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

  group('a place and its name', () {
    test('the name is kept in storage, and the same point is one place', () {
      final named = PrayerPlace(30.0444, 31.2357, name: 'Cairo, Egypt');
      expect(PrayerPlace.tryFromJson(named.toJson())?.name, 'Cairo, Egypt');
      expect(named, PrayerPlace(30.0444, 31.2357));
      expect(named.hashCode, PrayerPlace(30.0444, 31.2357).hashCode);
      // A place saved before names existed has none.
      expect(PrayerPlace.tryFromJson({'lat': 30.0, 'lng': 31.0})?.name, isNull);
      expect(
        PrayerPlace.tryFromJson({'lat': 30.0, 'lng': 31.0, 'name': '  '})?.name,
        isNull,
      );
      expect(named.withName(null).name, isNull);
    });

    test('a name is the city and the country, without repeating one', () {
      String? label({
        String? city,
        String? district,
        String? region,
        String? country,
      }) => PlatformPlaceNameSource.labelOf(
        Placemark(
          locality: city,
          subAdministrativeArea: district,
          administrativeArea: region,
          country: country,
        ),
      );
      expect(label(city: 'Cairo', country: 'Egypt'), 'Cairo, Egypt');
      expect(
        label(district: 'Giza', region: 'Cairo', country: 'Egypt'),
        'Giza, Egypt',
      );
      expect(
        label(region: 'Cairo Governorate', country: 'Egypt'),
        'Cairo Governorate, Egypt',
      );
      expect(label(city: 'Singapore', country: 'Singapore'), 'Singapore');
      expect(label(country: 'Egypt'), 'Egypt');
      expect(label(city: '  ', country: ''), isNull);
    });
  });

  group('PrayerNotifier', () {
    // The countdown reminders of the last container made, which the
    // platform keeps rather than the scheduler.
    late FakePrayerSoonPlatform soon;

    ProviderContainer container({
      required FakeReminderScheduler scheduler,
      required FakeLocationSource location,
      MemoryPrayerRepository? repository,
      MemorySettingsRepository? settings,
      FakePlaceNameSource? names,
    }) {
      soon = FakePrayerSoonPlatform();
      final c = ProviderContainer(
        overrides: [
          placeNameSourceProvider.overrideWithValue(
            names ?? FakePlaceNameSource(),
          ),
          reminderSchedulerProvider.overrideWithValue(scheduler),
          prayerSoonPlatformProvider.overrideWithValue(soon),
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

    group('the alerts on the first place', () {
      test('the first place turns the five alerts on and asks for '
          'notifications then, once', () async {
        final scheduler = FakeReminderScheduler();
        final c = container(
          scheduler: scheduler,
          location: FakeLocationSource(requestResult: _cairo),
        );
        await c.read(prayerProvider.future);
        expect(scheduler.permissionRequests, 0);
        await c.read(prayerProvider.notifier).locate();
        final state = c.read(prayerProvider).value!;
        expect(state.settings.alerts, DailyPrayer.values.toSet());
        expect(scheduler.permissionRequests, 1);
        // They are planned for the place that was just given.
        expect(scheduler.once, isNotEmpty);
      });

      test('a place chosen on the map does the same', () async {
        final scheduler = FakeReminderScheduler();
        final c = container(
          scheduler: scheduler,
          location: FakeLocationSource(),
        );
        await c.read(prayerProvider.future);
        await c
            .read(prayerProvider.notifier)
            .setPlace(PrayerPlace(21.42, 39.83));
        expect(
          c.read(prayerProvider).value!.settings.alerts,
          DailyPrayer.values.toSet(),
        );
        expect(scheduler.permissionRequests, 1);
      });

      test('if notifications are refused the place still saves, the alerts '
          'stay off, and nothing asks again', () async {
        final scheduler = FakeReminderScheduler(allow: false);
        final c = container(
          scheduler: scheduler,
          location: FakeLocationSource(),
        );
        await c.read(prayerProvider.future);
        await c.read(prayerProvider.notifier).setPlace(_cairo);
        final state = c.read(prayerProvider).value!;
        expect(state.place, _cairo);
        expect(state.settings.alerts, isEmpty);
        expect(scheduler.permissionRequests, 1);
        await c
            .read(prayerProvider.notifier)
            .setPlace(PrayerPlace(21.42, 39.83));
        expect(scheduler.permissionRequests, 1);
      });

      test('a person who turned them off keeps them off when the place '
          'changes', () async {
        final scheduler = FakeReminderScheduler();
        final c = container(
          scheduler: scheduler,
          location: FakeLocationSource(),
        );
        await c.read(prayerProvider.future);
        final notifier = c.read(prayerProvider.notifier);
        await notifier.setPlace(_cairo);
        await notifier.setAllAlerts(false);
        await notifier.setPlace(PrayerPlace(21.42, 39.83));
        expect(c.read(prayerProvider).value!.settings.alerts, isEmpty);
      });

      test('a place saved before is left alone: no alerts appear', () async {
        final scheduler = FakeReminderScheduler();
        final repo = MemoryPrayerRepository()..place = _cairo;
        final c = container(
          scheduler: scheduler,
          location: FakeLocationSource(),
          repository: repo,
        );
        await c.read(prayerProvider.future);
        await c
            .read(prayerProvider.notifier)
            .setPlace(PrayerPlace(21.42, 39.83));
        expect(c.read(prayerProvider).value!.settings.alerts, isEmpty);
        expect(scheduler.permissionRequests, 0);
      });
    });

    test(
      'a map-selected place saves without requesting device location',
      () async {
        final repo = MemoryPrayerRepository();
        final location = FakeLocationSource();
        final c = container(
          scheduler: FakeReminderScheduler(),
          location: location,
          repository: repo,
        );
        await c.read(prayerProvider.future);

        final selected = PrayerPlace(21.42, 39.83);
        await c.read(prayerProvider.notifier).setPlace(selected);

        expect(location.requests, 0);
        expect(c.read(prayerProvider).value!.place, selected);
        expect(repo.place, selected);
        expect(repo.settings.automaticLocation, isFalse);
        expect(c.read(prayerProvider).value!.method, PrayerMethod.ummAlQura);
      },
    );

    test(
      'a located place is named in the background and keeps its name',
      () async {
        final repo = MemoryPrayerRepository();
        final names = FakePlaceNameSource('Riyadh, Saudi Arabia');
        final c = container(
          scheduler: FakeReminderScheduler(),
          location: FakeLocationSource(
            requestResult: PrayerPlace(24.71, 46.68),
          ),
          repository: repo,
          names: names,
        );
        await c.read(prayerProvider.future);
        await c.read(prayerProvider.notifier).locate();
        // Nothing waited for the name; it arrives behind.
        await Future<void>.delayed(Duration.zero);
        expect(
          c.read(prayerProvider).value!.place?.name,
          'Riyadh, Saudi Arabia',
        );
        expect(repo.place?.name, 'Riyadh, Saudi Arabia');
        expect(c.read(prayerProvider).value!.method, PrayerMethod.ummAlQura);
      },
    );

    test('a map place that is already named is not asked for again', () async {
      final names = FakePlaceNameSource('Somewhere');
      final c = container(
        scheduler: FakeReminderScheduler(),
        location: FakeLocationSource(),
        names: names,
      );
      await c.read(prayerProvider.future);
      await c
          .read(prayerProvider.notifier)
          .setPlace(PrayerPlace(21.42, 39.83, name: 'Makkah, Saudi Arabia'));
      await Future<void>.delayed(Duration.zero);
      expect(names.asked, isEmpty);
      expect(c.read(prayerProvider).value!.place?.name, 'Makkah, Saudi Arabia');
    });

    test('with no name to be found, the place stays as it is', () async {
      final c = container(
        scheduler: FakeReminderScheduler(),
        location: FakeLocationSource(requestResult: _cairo),
        names: FakePlaceNameSource(),
      );
      await c.read(prayerProvider.future);
      await c.read(prayerProvider.notifier).locate();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(prayerProvider).value!.place, _cairo);
      expect(c.read(prayerProvider).value!.place?.name, isNull);
    });

    test('a refused location says why, and a good one clears it', () async {
      final location = FakeLocationSource()
        ..blocking = LocationProblem.serviceOff;
      final c = container(
        scheduler: FakeReminderScheduler(),
        location: location,
      );
      await c.read(prayerProvider.future);
      await c.read(prayerProvider.notifier).locate();
      expect(c.read(locationProblemProvider), LocationProblem.serviceOff);

      location
        ..blocking = LocationProblem.none
        ..requestResult = _cairo;
      await c.read(prayerProvider.notifier).locate();
      expect(c.read(locationProblemProvider), LocationProblem.none);
    });

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
        final atTime = scheduler.once.values.where(
          (value) => value.channel == ReminderChannel.prayer,
        );
        expect(atTime, hasLength(PrayerNotifier.planDays));
        // And as many reminders before it, which the platform keeps.
        expect(scheduler.once, hasLength(PrayerNotifier.planDays));
        expect(soon.alarms, hasLength(PrayerNotifier.planDays));
        final sample = atTime.first;
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
      // As many as the system is given at once; the rest come on a later
      // start.
      expect(
        scheduler.once.length + soon.alarms.length,
        PrayerNotifier.notificationLimit,
      );
      await notifier.setAllAlerts(false);
      expect(scheduler.once, isEmpty);
      expect(soon.alarms, isEmpty);
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
        expect(
          scheduler.once.length + soon.alarms.length,
          2 * PrayerNotifier.planDays,
        );
      },
    );

    test(
      'a manually selected place is not replaced by device location on startup',
      () async {
        final location = FakeLocationSource(
          quietResult: PrayerPlace(24.71, 46.68),
        );
        final repo = MemoryPrayerRepository()
          ..settings = const PrayerSettings(
            alerts: {DailyPrayer.dhuhr},
            automaticLocation: false,
          )
          ..place = _cairo;
        final c = container(
          scheduler: FakeReminderScheduler(),
          location: location,
          repository: repo,
        );
        final state = await c.read(prayerProvider.future);
        expect(state.place, _cairo);
        expect(location.quietReads, 0);
        expect(
          PrayerSettings.fromJson(repo.settings.toJson()).automaticLocation,
          isFalse,
        );
      },
    );

    test('previewing device location does not save it', () async {
      final repo = MemoryPrayerRepository()..place = _cairo;
      final newPlace = PrayerPlace(24.71, 46.68);
      final c = container(
        scheduler: FakeReminderScheduler(),
        location: FakeLocationSource(requestResult: newPlace),
        repository: repo,
      );
      await c.read(prayerProvider.future);
      expect(
        await c.read(prayerProvider.notifier).previewDeviceLocation(),
        newPlace,
      );
      expect(repo.place, _cairo);
      expect(c.read(prayerProvider).value!.place, _cairo);
    });

    test('confirming a device fix allows later automatic refresh', () async {
      final repo = MemoryPrayerRepository();
      final c = container(
        scheduler: FakeReminderScheduler(),
        location: FakeLocationSource(),
        repository: repo,
      );
      await c.read(prayerProvider.future);
      await c
          .read(prayerProvider.notifier)
          .setPlace(_cairo, automaticLocation: true);
      expect(repo.settings.automaticLocation, isTrue);
      expect(repo.place, _cairo);
    });

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
      final titles = scheduler.once.values.map((value) => value.title);
      expect(soon.alarms.first.title, 'Fajr is near');
      expect(titles, contains('Time for the Fajr prayer'));
    });
  });
}
