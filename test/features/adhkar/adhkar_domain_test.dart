import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_collection.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_progress.dart';
import 'package:mre_quran/core/notifications/reminder_payload.dart';
import 'package:mre_quran/features/adhkar/domain/reminder_setting.dart';

import '../../helpers/adhkar_fixtures.dart';

final _t = DateTime(2026, 10, 8, 9);

void main() {
  final catalog = fixtureCatalog();
  final morning = catalog.byId('morning')!;
  final evening = catalog.byId('evening')!;

  group('AdhkarProgress', () {
    test('counts up to the repeat count and no further', () {
      var progress = const AdhkarProgress(day: '2026-10-08');
      final second = morning.entries[1]; // repeat 3
      for (var i = 0; i < 5; i++) {
        progress = progress.increment(morning, second, now: _t);
      }
      expect(progress.countOf(morning, second), 3);
      expect(progress.isDone(morning, second), isTrue);
      expect(progress.isComplete(morning), isFalse);
    });

    test('finishing every entry completes the collection', () {
      var progress = const AdhkarProgress(day: '2026-10-08');
      for (final entry in morning.entries) {
        for (var i = 0; i < entry.repeat; i++) {
          progress = progress.increment(morning, entry, now: _t);
        }
      }
      expect(progress.isComplete(morning), isTrue);
      expect(progress.doneRepeats(morning), morning.totalRepeats);
    });

    test('undo takes one back and never goes below zero', () {
      final entry = morning.entries[1];
      var progress = const AdhkarProgress(day: '2026-10-08')
          .increment(morning, entry, now: _t)
          .increment(morning, entry, now: _t);
      progress = progress.decrement(morning, entry, now: _t);
      expect(progress.countOf(morning, entry), 1);
      progress = progress
          .decrement(morning, entry, now: _t)
          .decrement(morning, entry, now: _t);
      expect(progress.countOf(morning, entry), 0);
      expect(progress.counts, isEmpty);
    });

    test('reset clears one collection and keeps the other', () {
      final progress = const AdhkarProgress(day: '2026-10-08')
          .increment(morning, morning.entries.first, now: _t)
          .increment(evening, evening.entries.first, now: _t);
      final cleared = progress.reset(morning);
      expect(cleared.countOf(morning, morning.entries.first), 0);
      expect(cleared.countOf(evening, evening.entries.first), 1);
    });

    test('the same order in two collections is counted apart', () {
      final progress = const AdhkarProgress(day: '2026-10-08')
          .increment(morning, morning.entries.first, now: _t);
      expect(progress.countOf(evening, evening.entries.first), 0);
    });

    test('saved counts from another day are dropped', () {
      final json = const AdhkarProgress(
        day: '2026-10-07',
        counts: {'morning:1': 1},
      ).toJson();
      expect(AdhkarProgress.fromJson(json, day: '2026-10-08').counts, isEmpty);
      expect(AdhkarProgress.fromJson(json, day: '2026-10-07').counts, {
        'morning:1': 1,
      });
      expect(
        AdhkarProgress.fromJson('junk', day: '2026-10-08').counts,
        isEmpty,
      );
    });

    test('formats the day with zero padding', () {
      expect(AdhkarProgress.dayOf(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('prayer window', () {
    final prayer = fixtureCatalogWithPrayer().byId('after_prayer')!;
    final start = DateTime(2026, 10, 8, 13);

    test('counts survive inside the window and clear after it', () {
      final progress = const AdhkarProgress(day: '2026-10-08')
          .increment(prayer, prayer.entries.first, now: start);
      expect(progress.isSessionActive(prayer, start), isTrue);
      expect(
        progress
            .settle([prayer], start.add(const Duration(minutes: 29)))
            .countOf(prayer, prayer.entries.first),
        1,
      );
      final later = start.add(const Duration(minutes: 31));
      expect(progress.isSessionActive(prayer, later), isFalse);
      expect(
        progress.settle([prayer], later).countOf(prayer, prayer.entries.first),
        0,
      );
    });

    test('each tap extends the window', () {
      var progress = const AdhkarProgress(day: '2026-10-08')
          .increment(prayer, prayer.entries.first, now: start);
      progress = progress.increment(
        prayer,
        prayer.entries.first,
        now: start.add(const Duration(minutes: 25)),
      );
      final later = start.add(const Duration(minutes: 50));
      expect(progress.isSessionActive(prayer, later), isTrue);
      expect(
        progress.settle([prayer], later).countOf(prayer, prayer.entries.first),
        2,
      );
    });

    test('a whole-day list is never cleared by the clock', () {
      final progress = const AdhkarProgress(day: '2026-10-08')
          .increment(morning, morning.entries.first, now: start);
      expect(
        progress
            .settle([morning], start.add(const Duration(hours: 9)))
            .countOf(morning, morning.entries.first),
        1,
      );
    });

    test('the touch times are saved and read back', () {
      final progress = const AdhkarProgress(day: '2026-10-08')
          .increment(prayer, prayer.entries.first, now: start);
      final back = AdhkarProgress.fromJson(
        progress.toJson(),
        day: '2026-10-08',
      );
      expect(back.touched, progress.touched);
      expect(back.isSessionActive(prayer, start), isTrue);
    });
  });

  group('suggestedAt', () {
    test('leads with the collection whose time is nearest', () {
      expect(catalog.suggestedAt(8 * 60)!.id, 'morning');
      expect(catalog.suggestedAt(13 * 60)!.id, 'evening');
      expect(catalog.suggestedAt(22 * 60)!.id, 'evening');
      expect(catalog.suggestedAt(2 * 60)!.id, 'morning');
    });

    test('is the first collection when none has a time, null when empty', () {
      final plain = AdhkarCatalog([
        AdhkarCollection(
          id: 'a',
          titles: const {'ar': 'أ'},
          icon: AdhkarIcon.generic,
          group: kDaily,
          entries: [dhikr(1)],
        ),
      ]);
      expect(plain.suggestedAt(600)!.id, 'a');
      expect(const AdhkarCatalog([]).suggestedAt(600), isNull);
    });
  });

  group('reminders', () {
    test('a setting round-trips and unreadable data is ignored', () {
      const setting = ReminderSetting(enabled: true, minutes: 330);
      expect(ReminderSetting.tryFromJson(setting.toJson()), setting);
      expect(setting.hour, 5);
      expect(setting.minute, 30);
      expect(ReminderSetting.tryFromJson({'on': true, 'm': 1440}), isNull);
      expect(ReminderSetting.tryFromJson({'on': 'yes', 'm': 1}), isNull);
      expect(ReminderSetting.tryFromJson(null), isNull);
    });

    test('reads HH:mm only', () {
      expect(ReminderSetting.parseClock('05:30'), 330);
      expect(ReminderSetting.parseClock('23:59'), 1439);
      expect(ReminderSetting.parseClock('24:00'), isNull);
      expect(ReminderSetting.parseClock('5:30'), isNull);
      expect(ReminderSetting.parseClock(530), isNull);
    });

    test(
      'a tapped reminder opens its list, and foreign payloads open nothing',
      () {
        expect(
          AppRoute.fromReminderPayload('adhkar:evening'),
          '/adhkar/evening',
        );
        expect(AppRoute.fromReminderPayload('download:1'), isNull);
      },
    );

    test('payloads carry the collection id and ids are stable', () {
      final payload = ReminderPayload.forCollection('morning');
      expect(ReminderPayload.collectionId(payload), 'morning');
      expect(ReminderPayload.collectionId('other:1'), isNull);
      expect(ReminderPayload.collectionId('adhkar:'), isNull);
      expect(
        ReminderPayload.notificationId('morning'),
        ReminderPayload.notificationId('morning'),
      );
      expect(
        ReminderPayload.notificationId('morning'),
        isNot(ReminderPayload.notificationId('evening')),
      );
      expect(ReminderPayload.notificationId('morning'), lessThan(1 << 31));
    });
  });
}
