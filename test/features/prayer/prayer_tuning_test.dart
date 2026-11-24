import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/prayer/domain/hijri_date.dart';
import 'package:mre_quran/features/prayer/domain/prayer_alerts.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/prayer/domain/prayer_tuning.dart';

final _cairo = PrayerPlace(30.0444, 31.2357);
final _day = DateTime(2026, 10, 8);

int _minutes(DateTime later, DateTime earlier) =>
    later.difference(earlier).inMinutes;

void main() {
  group('minutes added to a prayer', () {
    final plain = PrayerDay.compute(_cairo, PrayerMethod.egyptian, _day);

    test('move that prayer only, either way', () {
      final moved = PrayerDay.compute(
        _cairo,
        PrayerMethod.egyptian,
        _day,
        tuning: const PrayerTuning(
          offsets: {DailyPrayer.dhuhr: 5, DailyPrayer.isha: -3},
        ),
      );
      expect(_minutes(moved.dhuhr, plain.dhuhr), 5);
      expect(_minutes(moved.isha, plain.isha), -3);
      expect(moved.fajr, plain.fajr);
      expect(moved.asr, plain.asr);
      expect(moved.maghrib, plain.maghrib);
      expect(moved.sunrise, plain.sunrise);
    });

    test('no tuning is the calculation itself', () {
      final same = PrayerDay.compute(
        _cairo,
        PrayerMethod.egyptian,
        _day,
        tuning: const PrayerTuning(),
      );
      expect(same.fajr, plain.fajr);
      expect(same.isha, plain.isha);
      expect(PrayerTuning.none.isNone, isTrue);
    });
  });

  group('height above sea level', () {
    final plain = PrayerDay.compute(_cairo, PrayerMethod.egyptian, _day);
    PrayerDay at(int metres) => PrayerDay.compute(
      _cairo,
      PrayerMethod.egyptian,
      _day,
      tuning: PrayerTuning(elevation: metres),
    );

    test('brings sunrise forward and Maghrib back, and nothing else', () {
      final high = at(400);
      expect(high.sunrise.isBefore(plain.sunrise), isTrue);
      expect(high.maghrib.isAfter(plain.maghrib), isTrue);
      expect(high.fajr, plain.fajr);
      expect(high.dhuhr, plain.dhuhr);
      expect(high.asr, plain.asr);
      expect(high.isha, plain.isha);
    });

    test('moves them about the same, and more from higher up', () {
      final early = _minutes(plain.sunrise, at(400).sunrise);
      final late = _minutes(at(400).maghrib, plain.maghrib);
      // 400 m: the horizon dips about 0.7 degrees, some three minutes at
      // Cairo's latitude in October.
      expect(early, inInclusiveRange(2, 4));
      expect(late, inInclusiveRange(2, 4));
      expect(_minutes(at(2000).maghrib, plain.maghrib), greaterThan(late));
    });

    test('sea level, and a height below it, change nothing', () {
      expect(at(0).maghrib, plain.maghrib);
      expect(PrayerElevation.shift(_cairo, _day, -50), (sunrise: 0, sunset: 0));
    });

    test('where the sun does not set, nothing is moved', () {
      // Midsummer inside the Arctic Circle.
      final arctic = PrayerPlace(80, 15);
      expect(PrayerElevation.shift(arctic, DateTime(2026, 6, 21), 500), (
        sunrise: 0,
        sunset: 0,
      ));
    });

    test('a tenth of a kilometre is only a minute or two', () {
      final shift = PrayerElevation.shift(_cairo, _day, 100);
      expect(shift.sunset, inInclusiveRange(1, 2));
      expect(shift.sunrise, -shift.sunset);
    });
  });

  group('summer time', () {
    test('automatic leaves the phone\'s clock alone', () {
      expect(DaylightSaving.automatic.shift(deviceOnSummer: true), 0);
      expect(DaylightSaving.automatic.shift(deviceOnSummer: false), 0);
    });

    test('summer adds an hour only where the phone is not on it already', () {
      expect(DaylightSaving.summer.shift(deviceOnSummer: false), 60);
      expect(DaylightSaving.summer.shift(deviceOnSummer: true), 0);
    });

    test('winter takes an hour off only where the phone is on summer time', () {
      expect(DaylightSaving.winter.shift(deviceOnSummer: true), -60);
      expect(DaylightSaving.winter.shift(deviceOnSummer: false), 0);
    });

    test('the times move by that hour, whatever the phone\'s zone', () {
      final plain = PrayerDay.compute(_cairo, PrayerMethod.egyptian, _day);
      final onSummer = DaylightSaving.deviceOnSummerTime(
        DateTime(_day.year, _day.month, _day.day, 12),
      );
      final forced = PrayerDay.compute(
        _cairo,
        PrayerMethod.egyptian,
        _day,
        tuning: PrayerTuning(
          daylight: onSummer ? DaylightSaving.winter : DaylightSaving.summer,
        ),
      );
      expect(_minutes(forced.fajr, plain.fajr), onSummer ? -60 : 60);
      expect(_minutes(forced.isha, plain.isha), onSummer ? -60 : 60);
      expect(_minutes(forced.sunrise, plain.sunrise), onSummer ? -60 : 60);
    });

    test('names that are not known mean automatic', () {
      expect(DaylightSaving.parse('summer'), DaylightSaving.summer);
      expect(DaylightSaving.parse('?'), DaylightSaving.automatic);
      expect(DaylightSaving.parse(null), DaylightSaving.automatic);
    });
  });

  group('the Hijri date', () {
    test('moves by the days the person says', () {
      final plain = HijriDate.of(DateTime(2026, 10, 8));
      final later = HijriDate.of(DateTime(2026, 10, 8), shift: 1);
      final earlier = HijriDate.of(DateTime(2026, 10, 8), shift: -2);
      expect(plain.day, 27);
      expect(later.day, 28);
      expect(earlier.day, 25);
    });

    test('carries over a month end', () {
      // 1 Ramadan 1447 fell on 18 February 2026: a day back is the end of
      // Sha'ban.
      final ramadan = HijriDate.of(DateTime(2026, 2, 18));
      final before = HijriDate.of(DateTime(2026, 2, 18), shift: -1);
      expect((ramadan.month, ramadan.day), (9, 1));
      expect(before.month, 8);
      expect(before.day, greaterThanOrEqualTo(29));
    });
  });

  group('the saved choices', () {
    test('survive being saved and read', () {
      const settings = PrayerSettings(
        offsets: {DailyPrayer.fajr: -2, DailyPrayer.maghrib: 4},
        daylight: DaylightSaving.summer,
        elevation: 120,
        hijriShift: -1,
      );
      final back = PrayerSettings.fromJson(settings.toJson());
      expect(back.offsets, {DailyPrayer.fajr: -2, DailyPrayer.maghrib: 4});
      expect(back.daylight, DaylightSaving.summer);
      expect(back.elevation, 120);
      expect(back.hijriShift, -1);
    });

    test('older settings, and nonsense, mean no change', () {
      final old = PrayerSettings.fromJson({'on': true});
      expect(old.offsets, isEmpty);
      expect(old.daylight, DaylightSaving.automatic);
      expect(old.elevation, isNull);
      expect(old.hijriShift, 0);
      final odd = PrayerSettings.fromJson({
        'offsets': {'fajr': 90, 'isha': 'x', 'asr': 0},
        'elevation': -5,
        'hijriShift': 9,
      });
      expect(odd.offsets, isEmpty);
      expect(odd.elevation, isNull);
      expect(odd.hijriShift, 0);
    });

    test('the height is the person\'s, else the GPS\'s, else sea level', () {
      final gps = PrayerPlace(30.0444, 31.2357, altitude: 23.4);
      expect(const PrayerSettings().elevationAt(_cairo), 0);
      expect(const PrayerSettings().elevationAt(gps), 23);
      expect(const PrayerSettings(elevation: 80).elevationAt(gps), 80);
      expect(
        const PrayerSettings(elevation: 80).copyWith(automaticElevation: true),
        isA<PrayerSettings>().having((s) => s.elevation, 'elevation', isNull),
      );
    });

    test('a place keeps its height through naming, storing and moving', () {
      final place = PrayerPlace(
        30.0444,
        31.2357,
        name: 'Cairo',
        altitude: 23.6,
      );
      expect(place.altitude, 24);
      expect(place.withName('Giza').altitude, 24);
      expect(PrayerPlace.tryFromJson(place.toJson())!.altitude, 24);
      expect(
        PrayerPlace.tryFromJson({'lat': 30.0, 'lng': 31.0})!.altitude,
        isNull,
      );
      // The height is not what makes a place the same one.
      expect(place, PrayerPlace(30.0444, 31.2357));
      expect(place.distanceKm(PrayerPlace(30.0444, 31.2357)), 0);
      expect(place.distanceKm(PrayerPlace(31.2001, 29.9187)), closeTo(179, 3));
    });
  });

  group('the iqama', () {
    final now = DateTime(2026, 10, 8, 3);
    List<PrayerAlert> plan(PrayerSettings settings) => PrayerAlertPlan.compute(
      place: _cairo,
      settings: settings,
      now: now,
      days: 1,
    ).where((alert) => alert.kind == PrayerAlertKind.iqama).toList();

    test('is off until the person turns it on', () {
      expect(plan(const PrayerSettings(alerts: {DailyPrayer.fajr})), isEmpty);
      expect(const PrayerSettings().needsSchedule, isFalse);
      expect(const PrayerSettings(iqamaReminder: true).needsSchedule, isTrue);
    });

    test('comes for the five prayers, the usual gap after each adhan', () {
      final iqamas = plan(const PrayerSettings(iqamaReminder: true));
      final day = PrayerDay.compute(_cairo, PrayerMethod.egyptian, now);
      expect(iqamas.map((alert) => alert.prayer), DailyPrayer.values);
      for (final alert in iqamas) {
        expect(
          _minutes(alert.at, day.of(alert.prayer)),
          PrayerSettings.defaultIqamaMinutes[alert.prayer],
        );
      }
      expect(iqamas.map((alert) => alert.id), [
        for (var i = 0; i < 5; i++) PrayerAlertPlan.firstIqamaId + i,
      ]);
      expect(iqamas.every((alert) => PrayerAlertPlan.owns(alert.id)), isTrue);
    });

    test('follows the gap the person chose, and the minutes they moved '
        'the prayer by', () {
      const settings = PrayerSettings(
        iqamaReminder: true,
        iqamaMinutes: {DailyPrayer.dhuhr: 25},
        offsets: {DailyPrayer.dhuhr: 3},
      );
      final day = PrayerDay.compute(
        _cairo,
        PrayerMethod.egyptian,
        now,
        tuning: settings.tuningAt(_cairo),
      );
      final dhuhr = plan(settings)
          .firstWhere((alert) => alert.prayer == DailyPrayer.dhuhr);
      expect(_minutes(dhuhr.at, day.dhuhr), 25);
      expect(settings.iqamaAfter(DailyPrayer.asr), 15);
    });

    test('a gap already past is not planned', () {
      final late = PrayerAlertPlan.compute(
        place: _cairo,
        settings: const PrayerSettings(iqamaReminder: true),
        now: DateTime(2026, 10, 8, 23, 59),
        days: 1,
      );
      expect(late.where((a) => a.kind == PrayerAlertKind.iqama), isEmpty);
    });

    test('is saved with the sounds, and nonsense means the usual', () {
      const settings = PrayerSettings(
        iqamaReminder: true,
        iqamaSound: false,
        beforeSound: false,
        iqamaMinutes: {DailyPrayer.fajr: 30, DailyPrayer.isha: 15},
      );
      final back = PrayerSettings.fromJson(settings.toJson());
      expect(back.iqamaReminder, isTrue);
      expect(back.iqamaSound, isFalse);
      expect(back.beforeSound, isFalse);
      // Isha's 15 is the usual, so it is not kept.
      expect(back.iqamaMinutes, {DailyPrayer.fajr: 30});
      final odd = PrayerSettings.fromJson({
        'iqamaMinutes': {'fajr': 2, 'dhuhr': 600, 'asr': 'x'},
      });
      expect(odd.iqamaMinutes, isEmpty);
      expect(odd.iqamaReminder, isFalse);
      expect(odd.iqamaSound, isTrue);
      expect(odd.beforeSound, isTrue);
    });
  });

  test('the alerts follow the minutes the person added', () {
    final now = DateTime(2026, 10, 8, 3);
    List<PrayerAlert> plan(PrayerSettings settings) => PrayerAlertPlan.compute(
      place: _cairo,
      settings: settings,
      now: now,
      days: 1,
    ).where((alert) => alert.kind == PrayerAlertKind.atTime).toList();
    const base = PrayerSettings(alerts: {DailyPrayer.dhuhr});
    final plain = plan(base);
    final moved = plan(base.copyWith(offsets: {DailyPrayer.dhuhr: 7}));
    expect(plain, hasLength(1));
    expect(_minutes(moved.single.at, plain.single.at), 7);
  });
}
