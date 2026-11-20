import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/app/reminder_opener.dart';
import 'package:mre_quran/app/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/notifications/reminder_payload.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';
import 'package:mre_quran/features/adhkar/application/reminders_provider.dart';
import 'package:mre_quran/features/adhkar/application/weekly_reminders_provider.dart';
import 'package:mre_quran/features/adhkar/domain/reminder_setting.dart';
import 'package:mre_quran/features/adhkar/domain/weekly_reminder.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_settings_repository.dart';

const _kahf = WeeklyReminder(
  id: 'friday_kahf',
  weekday: DateTime.friday,
  minutes: 9 * 60,
  titles: {'ar': 'سورة الكهف', 'en': 'Surat Al-Kahf'},
  bodies: {'ar': 'اليوم الجمعة.', 'en': 'It is Friday.'},
  surah: 18,
);

void main() {
  group('the weekly reminders file', () {
    final file = File('assets/reminders/weekly.json');
    final reminders = parseWeeklyReminders(jsonDecode(file.readAsStringSync()));

    test('offers the Friday reminder to read Surat Al-Kahf', () {
      final kahf = reminders.singleWhere((item) => item.id == 'friday_kahf');
      expect(kahf.weekday, DateTime.friday);
      expect(kahf.surah, 18);
      expect(kahf.title('ar'), isNotEmpty);
      expect(kahf.title('en'), isNotEmpty);
      expect(kahf.body('ar'), isNotEmpty);
    });

    test('every reminder has a time, texts in both languages and a day', () {
      for (final reminder in reminders) {
        expect(reminder.minutes, inInclusiveRange(0, 1439));
        expect(reminder.weekday, inInclusiveRange(1, 7));
        expect(reminder.titles.keys, containsAll(['ar', 'en']));
        expect(reminder.bodies.keys, containsAll(['ar', 'en']));
      }
    });
  });

  group('reading the file', () {
    test('a bad entry is skipped, and the others are kept', () {
      final reminders = parseWeeklyReminders(<String, Object?>{
        'schema': 1,
        'reminders': [
          {
            'id': '',
            'weekday': 5,
            'time': '09:00',
            'title': {'ar': 'x'},
            'body': {'ar': 'y'},
          },
          {
            'id': 'a',
            'weekday': 8,
            'time': '09:00',
            'title': {'ar': 'x'},
            'body': {'ar': 'y'},
          },
          {
            'id': 'b',
            'weekday': 5,
            'time': '25:00',
            'title': {'ar': 'x'},
            'body': {'ar': 'y'},
          },
          {
            'id': 'c',
            'weekday': 5,
            'time': '09:00',
            'title': <String, String>{},
            'body': {'ar': 'y'},
          },
          'junk',
          {
            'id': 'good',
            'weekday': 7,
            'time': '08:30',
            'title': {'en': 'T'},
            'body': {'en': 'B'},
            'surah': 999,
          },
          {
            'id': 'good',
            'weekday': 1,
            'time': '08:30',
            'title': {'en': 'T'},
            'body': {'en': 'B'},
          },
        ],
      });
      expect(reminders.map((item) => item.id), ['good']);
      // The first one with an id is kept; a surah that does not exist is not.
      expect(reminders.single.weekday, 7);
      expect(reminders.single.surah, isNull);
      // A language it lacks falls back to what it has.
      expect(reminders.single.title('ar'), 'T');
    });

    test('anything but the expected shape is an empty list', () {
      expect(parseWeeklyReminders(null), isEmpty);
      expect(
        parseWeeklyReminders(<String, Object?>{'reminders': 'x'}),
        isEmpty,
      );
    });
  });

  group('the payload', () {
    test('names a surah, and only a real one', () {
      expect(ReminderPayload.surah(ReminderPayload.forSurah(18)), 18);
      expect(ReminderPayload.surah('surah:0'), isNull);
      expect(ReminderPayload.surah('surah:115'), isNull);
      expect(ReminderPayload.surah('surah:x'), isNull);
      expect(ReminderPayload.surah('adhkar:morning'), isNull);
      expect(
        ReminderPayload.collectionId(ReminderPayload.forSurah(18)),
        isNull,
      );
    });
  });

  group('WeeklyRemindersNotifier', () {
    late FakeReminderScheduler scheduler;
    late MemoryRemindersRepository repository;

    ProviderContainer container({String locale = 'ar'}) {
      scheduler = FakeReminderScheduler();
      repository = MemoryRemindersRepository();
      final c = ProviderContainer(
        overrides: [
          weeklyReminderCatalogProvider.overrideWith((ref) async => [_kahf]),
          weeklyRemindersRepositoryProvider.overrideWithValue(repository),
          reminderSchedulerProvider.overrideWithValue(scheduler),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository()
              ..settings = AppSettings(localeCode: locale),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test(
      'is off until turned on, at its own time, and asks for nothing',
      () async {
        final c = container();
        final settings = await c.read(weeklyRemindersProvider.future);
        expect(
          settings['friday_kahf'],
          const ReminderSetting(enabled: false, minutes: 540),
        );
        expect(scheduler.permissionRequests, 0);
        expect(scheduler.scheduled, isEmpty);
      },
    );

    test(
      'turning it on asks for permission and schedules it for Friday',
      () async {
        final c = container();
        await c.read(weeklyRemindersProvider.future);
        final result = await c
            .read(weeklyRemindersProvider.notifier)
            .setEnabled(_kahf, true);
        expect(result, ReminderToggleResult.enabled);
        expect(scheduler.permissionRequests, 1);
        final id = ReminderPayload.notificationId('weekly:friday_kahf');
        expect(scheduler.weekdays[id], DateTime.friday);
        final scheduled = scheduler.scheduled[id]!;
        expect(scheduled.minutes, 540);
        expect(scheduled.title, 'سورة الكهف');
        expect(scheduled.payload, ReminderPayload.forSurah(18));
        expect(repository.saved['friday_kahf']!.enabled, isTrue);
      },
    );

    test('a refused permission leaves it off', () async {
      final c = container();
      await c.read(weeklyRemindersProvider.future);
      scheduler.allow = false;
      final result = await c
          .read(weeklyRemindersProvider.notifier)
          .setEnabled(_kahf, true);
      expect(result, ReminderToggleResult.permissionDenied);
      expect(scheduler.scheduled, isEmpty);
      expect(
        c.read(weeklyRemindersProvider).value!['friday_kahf']!.enabled,
        isFalse,
      );
    });

    test('a new time reschedules it, and turning it off cancels it', () async {
      final c = container();
      await c.read(weeklyRemindersProvider.future);
      final notifier = c.read(weeklyRemindersProvider.notifier);
      await notifier.setEnabled(_kahf, true);
      await notifier.setTime(_kahf, 8 * 60 + 15);
      final id = ReminderPayload.notificationId('weekly:friday_kahf');
      expect(scheduler.scheduled[id]!.minutes, 495);
      await notifier.setEnabled(_kahf, false);
      expect(scheduler.scheduled.containsKey(id), isFalse);
    });

    test('a reminder left on is scheduled again when the app starts', () async {
      final c = container();
      repository = MemoryRemindersRepository()
        ..saved = {
          'friday_kahf': const ReminderSetting(enabled: true, minutes: 600),
        };
      final again = ProviderContainer(
        overrides: [
          weeklyReminderCatalogProvider.overrideWith((ref) async => [_kahf]),
          weeklyRemindersRepositoryProvider.overrideWithValue(repository),
          reminderSchedulerProvider.overrideWithValue(scheduler),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
      );
      addTearDown(again.dispose);
      await again.read(weeklyRemindersProvider.future);
      await Future<void>.delayed(Duration.zero);
      final id = ReminderPayload.notificationId('weekly:friday_kahf');
      expect(scheduler.scheduled[id]!.minutes, 600);
      expect(scheduler.weekdays[id], DateTime.friday);
      c.dispose();
    });
  });

  group('a tap on the reminder', () {
    testWidgets('puts the Mushaf at the surah and opens it', (tester) async {
      final opened = <int>[];
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(
            path: AppRoute.reader.path,
            builder: (_, _) => const Text('reader'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await openReminder(
        router,
        ReminderPayload.forSurah(18),
        openSurah: (surah) async => opened.add(surah),
      );
      await tester.pumpAndSettle();
      expect(opened, [18]);
      expect(find.text('reader'), findsOneWidget);
    });
  });
}
