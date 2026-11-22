import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/fasting/domain/sunnah_fasts.dart';
import 'package:mre_quran/features/prayer/domain/hijri_date.dart';

/// A calendar of 30-day Hijri months where [start] is the 1st of [month].
HijriDate Function(DateTime) calendar(DateTime start, {required int month}) =>
    (day) {
      final days = DateTime.utc(
        day.year,
        day.month,
        day.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
      final index = (month - 1) * 30 + days;
      return HijriDate(
        year: 1448,
        month: index ~/ 30 % 12 + 1,
        day: index % 30 + 1,
      );
    };

void main() {
  // Sunday 3 January 2027, 10 in the morning.
  final now = DateTime(2027, 1, 3, 10);
  const all = FastingSettings();

  List<FastReminder> plan(
    HijriDate Function(DateTime) hijriOf, {
    FastingSettings settings = all,
    DateTime? at,
    int days = 40,
  }) => FastingPlan.compute(
    now: at ?? now,
    settings: settings,
    days: days,
    hijriOf: hijriOf,
  );

  FastReminder on(List<FastReminder> reminders, DateTime day) =>
      reminders.firstWhere((reminder) => reminder.day == day);

  group('Mondays and Thursdays', () {
    // A month with none of the yearly fasts, its white days far off.
    final rajab = calendar(DateTime(2027, 1, 1), month: 7);

    test('are reminded of the evening before, at the chosen time', () {
      final reminders = plan(
        rajab,
        settings: const FastingSettings(fasts: {SunnahFast.mondayThursday}),
        days: 7,
      );
      expect(
        [for (final r in reminders) r.day],
        [DateTime(2027, 1, 4), DateTime(2027, 1, 7)],
      );
      expect(reminders.first.at, DateTime(2027, 1, 3, 21));
      expect(reminders.first.reasons, [FastReason.monday]);
      expect(reminders.last.reasons, [FastReason.thursday]);
      expect(reminders.first.id, FastingPlan.firstId + 1);
      expect(reminders.last.id, FastingPlan.firstId + 4);
      expect(reminders.every((r) => FastingPlan.owns(r.id)), isTrue);
    });

    test('an evening already gone is passed over', () {
      final late = plan(
        rajab,
        settings: const FastingSettings(fasts: {SunnahFast.mondayThursday}),
        at: DateTime(2027, 1, 3, 22),
        days: 7,
      );
      expect(late.first.day, DateTime(2027, 1, 7));
    });

    test('turned off, they are not reminded of', () {
      final reminders = plan(
        rajab,
        settings: const FastingSettings(fasts: {SunnahFast.whiteDays}),
        days: 7,
      );
      expect(reminders, isEmpty);
    });
  });

  test('the white days are the 13th, 14th and 15th', () {
    final reminders = plan(
      calendar(DateTime(2027, 1, 1), month: 7),
      settings: const FastingSettings(fasts: {SunnahFast.whiteDays}),
      days: 20,
    );
    expect([for (final r in reminders) r.hijri.day], [13, 14, 15]);
    expect(
      reminders.every((r) => r.reasons.single == FastReason.whiteDay),
      isTrue,
    );
  });

  test('a day with two reasons gives one reminder with both, the yearly '
      'first', () {
    // The 9th of Dhu al-Hijjah falls on Monday 11 January.
    final reminders = plan(calendar(DateTime(2027, 1, 3), month: 12));
    final arafah = on(reminders, DateTime(2027, 1, 11));
    expect(arafah.hijri.month, 12);
    expect(arafah.hijri.day, 9);
    expect(arafah.reasons, [FastReason.arafah, FastReason.monday]);
  });

  test('no reminder on the Eid of Al-Adha or the days of Tashreeq, nor the '
      'day after them, and no white days in Dhu al-Hijjah', () {
    final reminders = plan(calendar(DateTime(2027, 1, 3), month: 12));
    for (final reminder in reminders) {
      if (reminder.hijri.month != 12) continue;
      expect(reminder.hijri.day, isNot(inInclusiveRange(10, 14)));
      expect(reminder.reasons, isNot(contains(FastReason.whiteDay)));
    }
    // Monday 18 January is the 16th: open again.
    expect(on(reminders, DateTime(2027, 1, 18)).reasons, [FastReason.monday]);
  });

  test('Tasu\'a and Ashura are the 9th and 10th of Muharram', () {
    final reminders = plan(
      calendar(DateTime(2027, 1, 1), month: 1),
      settings: const FastingSettings(fasts: {SunnahFast.ashura}),
    );
    expect(
      [for (final r in reminders) r.reasons.single],
      [FastReason.tasua, FastReason.ashura],
    );
    expect([for (final r in reminders) r.hijri.day], [9, 10]);
  });

  test('nothing in Ramadan, nor on the Eid or the day after; the six of '
      'Shawwal from the 3rd', () {
    // Ramadan's 20th is 3 January; Shawwal begins on 13 January.
    final reminders = plan(
      calendar(DateTime(2026, 12, 15), month: 9),
      days: 20,
    );
    for (final reminder in reminders) {
      expect(reminder.hijri.month, isNot(9));
      if (reminder.hijri.month == 10) {
        expect(reminder.hijri.day, greaterThanOrEqualTo(3));
      }
    }
    final shawwal = reminders.firstWhere(
      (r) => r.reasons.contains(FastReason.shawwal),
    );
    expect(shawwal.hijri.day, 3);
    // Thursday 14 January is the 2nd of Shawwal: no Thursday reminder.
    expect(reminders.where((r) => r.day == DateTime(2027, 1, 14)), isEmpty);
  });

  test('finds when each fast comes next', () {
    final hijri = calendar(DateTime(2027, 1, 1), month: 11);
    expect(
      FastingPlan.next(SunnahFast.arafah, now: now, hijriOf: hijri),
      DateTime(2027, 2, 8),
    );
    expect(
      FastingPlan.next(SunnahFast.mondayThursday, now: now, hijriOf: hijri),
      DateTime(2027, 1, 4),
    );
  });

  test('on the real calendar, the next Arafah is the 9th of Dhu al-Hijjah', () {
    final day = FastingPlan.next(SunnahFast.arafah, now: now)!;
    final hijri = HijriDate.of(day);
    expect((hijri.month, hijri.day), (12, 9));
    expect(day.isAfter(now), isTrue);
  });

  group('the choices', () {
    test('every fast is on at nine in the evening until changed', () {
      expect(all.fasts, SunnahFast.values.toSet());
      expect(all.minutes, 21 * 60);
    });

    test('survive storage; anything unreadable gives the defaults', () {
      const chosen = FastingSettings(
        fasts: {SunnahFast.arafah, SunnahFast.ashura},
        minutes: 20 * 60 + 30,
      );
      expect(FastingSettings.fromJson(chosen.toJson()), chosen);
      expect(
        FastingSettings.fromJson(const {'fasts': <Object?>[]}).fasts,
        isEmpty,
      );
      expect(FastingSettings.fromJson('nonsense'), all);
      expect(
        FastingSettings.fromJson(const {'minutes': 9999}).minutes,
        21 * 60,
      );
    });
  });
}
