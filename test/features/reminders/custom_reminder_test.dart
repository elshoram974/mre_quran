import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/reminders/domain/custom_reminder.dart';

CustomReminder _reminder({
  String title = 'الدواء',
  List<int> times = const [480],
  ReminderRepeat repeat = ReminderRepeat.daily,
  Set<int> weekdays = const {},
  int dayOfMonth = 1,
}) => CustomReminder(
  id: 'a',
  title: title,
  times: times,
  repeat: repeat,
  weekdays: weekdays,
  dayOfMonth: dayOfMonth,
);

void main() {
  group('what the form lets through is cleaned', () {
    test('texts are trimmed and cut, times sorted and without repeats', () {
      final clean = CustomReminder(
        id: 'a',
        title: '  ${'ا' * 80}  ',
        note: ' ملاحظة ',
        times: const [600, 480, 600, 99999, -5],
        dayOfMonth: 31,
        weekdays: const {0, 3, 9},
        repeat: ReminderRepeat.weekly,
      ).normalized();
      expect(clean.title.length, CustomReminder.maxTitle);
      expect(clean.note, 'ملاحظة');
      expect(clean.times, [480, 600]);
      expect(clean.dayOfMonth, CustomReminder.maxDayOfMonth);
      expect(clean.weekdays, {3});
    });
  });

  group('what stops it being saved', () {
    test('a good one has no problem', () {
      expect(_reminder().problem, isNull);
    });

    test('no title, no time, no day, too many times or moments', () {
      expect(_reminder(title: '  ').problem, ReminderProblem.noTitle);
      expect(_reminder(times: const []).problem, ReminderProblem.noTime);
      expect(
        _reminder(repeat: ReminderRepeat.weekly).problem,
        ReminderProblem.noDay,
      );
      expect(
        _reminder(times: [for (var i = 0; i < 7; i++) i * 60]).problem,
        ReminderProblem.tooManyTimes,
      );
      expect(
        _reminder(
          repeat: ReminderRepeat.weekly,
          weekdays: {1, 2, 3, 4, 5, 6, 7},
          times: const [480, 600, 720],
        ).problem,
        ReminderProblem.tooManyMoments,
      );
    });
  });

  group('the moments it comes at', () {
    test('daily: each time, every day', () {
      final slots = _reminder(times: const [480, 1200]).slots;
      expect([for (final s in slots) s.minutes], [480, 1200]);
      expect(
        slots.every((s) => s.weekday == null && s.dayOfMonth == null),
        isTrue,
      );
    });

    test('weekly: each time on each chosen day, days in order', () {
      final slots = _reminder(
        repeat: ReminderRepeat.weekly,
        weekdays: {5, 1},
        times: const [480, 1200],
      ).slots;
      expect(
        [for (final s in slots) (s.weekday, s.minutes)],
        [(1, 480), (1, 1200), (5, 480), (5, 1200)],
      );
    });

    test('monthly: each time on the one day', () {
      final slots = _reminder(
        repeat: ReminderRepeat.monthly,
        dayOfMonth: 15,
        times: const [480],
      ).slots;
      expect(slots.single.dayOfMonth, 15);
      expect(slots.single.weekday, isNull);
    });
  });

  group('when it first comes', () {
    // Thursday 8 October 2026, ten in the morning.
    final now = DateTime(2026, 10, 8, 10);

    test('daily: today when a time is still ahead, else tomorrow', () {
      expect(
        _reminder(times: const [480, 1200]).nextAfter(now),
        DateTime(2026, 10, 8, 20),
      );
      expect(
        _reminder(times: const [480]).nextAfter(now),
        DateTime(2026, 10, 9, 8),
      );
    });

    test('weekly: the soonest of the chosen days', () {
      final reminder = _reminder(
        repeat: ReminderRepeat.weekly,
        weekdays: {DateTime.monday, DateTime.saturday},
        times: const [480],
      );
      // Saturday 10 October comes before Monday the 12th.
      expect(reminder.nextAfter(now), DateTime(2026, 10, 10, 8));
      // The same weekday as today, its time gone: a week on.
      expect(
        _reminder(
          repeat: ReminderRepeat.weekly,
          weekdays: {DateTime.thursday},
          times: const [480],
        ).nextAfter(now),
        DateTime(2026, 10, 15, 8),
      );
    });

    test('monthly: this month when the day is ahead, else next month', () {
      expect(
        _reminder(
          repeat: ReminderRepeat.monthly,
          dayOfMonth: 15,
        ).nextAfter(now),
        DateTime(2026, 10, 15, 8),
      );
      expect(
        _reminder(repeat: ReminderRepeat.monthly, dayOfMonth: 3).nextAfter(now),
        DateTime(2026, 11, 3, 8),
      );
      expect(
        _reminder(
          repeat: ReminderRepeat.monthly,
          dayOfMonth: 3,
        ).nextAfter(DateTime(2026, 12, 20)),
        DateTime(2027, 1, 3, 8),
      );
    });

    test('with no moment there is none', () {
      expect(_reminder(times: const []).nextAfter(now), isNull);
    });
  });

  group('storage', () {
    test('survives being saved and read', () {
      const reminder = CustomReminder(
        id: 'x',
        title: 'ورد القرآن',
        note: 'صفحة قبل النوم',
        repeat: ReminderRepeat.weekly,
        weekdays: {7, 1},
        times: [1260],
        enabled: false,
      );
      final back = CustomReminder.tryFromJson(reminder.toJson())!;
      expect(back.title, 'ورد القرآن');
      expect(back.note, 'صفحة قبل النوم');
      expect(back.repeat, ReminderRepeat.weekly);
      expect(back.weekdays, {1, 7});
      expect(back.times, [1260]);
      expect(back.enabled, isFalse);
    });

    test('a bad entry is skipped, and the rest are kept', () {
      final good = _reminder().toJson();
      final list = parseCustomReminders([
        good,
        {
          'id': 'b',
          'title': '',
          'times': [1],
          'repeat': 'daily',
        },
        {'id': 'c', 'title': 'x', 'times': <int>[], 'repeat': 'daily'},
        {
          'id': 'd',
          'title': 'x',
          'times': [60],
          'repeat': 'yearly',
        },
        'nonsense',
        good,
      ]);
      expect(list, hasLength(1));
      expect(list.single.id, 'a');
    });

    test('no more than are allowed are read', () {
      final list = parseCustomReminders([
        for (var i = 0; i < 30; i++)
          {
            'id': '$i',
            'title': 't',
            'times': [60],
            'repeat': 'daily',
          },
      ]);
      expect(list, hasLength(CustomReminder.maxReminders));
    });
  });
}
