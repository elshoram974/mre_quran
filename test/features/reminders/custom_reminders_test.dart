import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/notifications/reminder_payload.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';
import 'package:mre_quran/features/adhkar/application/reminders_provider.dart';
import 'package:mre_quran/features/reminders/application/custom_reminders_provider.dart';
import 'package:mre_quran/features/reminders/domain/custom_reminder.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_custom_reminders_repository.dart';
import '../../helpers/memory_settings_repository.dart';

CustomReminder _reminder({
  String id = 'a',
  String title = 'الدواء',
  String note = '',
  List<int> times = const [480],
  ReminderRepeat repeat = ReminderRepeat.daily,
  Set<int> weekdays = const {},
  int dayOfMonth = 1,
  bool enabled = true,
}) => CustomReminder(
  id: id,
  title: title,
  note: note,
  times: times,
  repeat: repeat,
  weekdays: weekdays,
  dayOfMonth: dayOfMonth,
  enabled: enabled,
);

void main() {
  late FakeReminderScheduler scheduler;
  late MemoryCustomRemindersRepository repository;
  late ProviderContainer container;

  ProviderContainer make({String locale = 'ar'}) {
    final made = ProviderContainer(
      overrides: [
        reminderSchedulerProvider.overrideWithValue(scheduler),
        customRemindersRepositoryProvider.overrideWithValue(repository),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository()
            ..settings = AppSettings(localeCode: locale),
        ),
      ],
    );
    addTearDown(made.dispose);
    return made;
  }

  setUp(() {
    scheduler = FakeReminderScheduler();
    repository = MemoryCustomRemindersRepository();
    container = make();
  });

  Future<CustomRemindersNotifier> notifier() async {
    await container.read(customRemindersProvider.future);
    return container.read(customRemindersProvider.notifier);
  }

  Iterable<int> mine() => scheduler.channels.entries
      .where((entry) => entry.value == ReminderChannel.custom)
      .map((entry) => entry.key);

  test('a daily reminder at two times is two daily notifications with the '
      'person\'s words', () async {
    final owner = await notifier();
    expect(
      await owner.save(_reminder(times: const [480, 1260], note: 'بعد الأكل')),
      ReminderSaveResult.saved,
    );
    expect(mine(), hasLength(2));
    final first =
        scheduler.scheduled[CustomRemindersNotifier.notificationId('a', 0)]!;
    expect(
      (first.minutes, first.title, first.body),
      (480, 'الدواء', 'بعد الأكل'),
    );
    expect(first.payload, ReminderPayload.remindersSettings);
    expect(first.settingsLabel, 'الإعدادات');
    expect(scheduler.weekdays, isEmpty);
    expect(scheduler.monthDays, isEmpty);
    expect(repository.reminders.single.title, 'الدواء');
  });

  test('without a note, the app words the line', () async {
    await (await notifier()).save(_reminder());
    final sent = scheduler.scheduled.values.single;
    expect(sent.body, 'تذكير أضفته بنفسك.');
  });

  test('a weekly one is a notification for each day and time', () async {
    await (await notifier()).save(
      _reminder(
        repeat: ReminderRepeat.weekly,
        weekdays: const {1, 4},
        times: const [480, 1200],
      ),
    );
    expect(mine(), hasLength(4));
    expect(scheduler.weekdays.values.toSet(), {1, 4});
  });

  test('a monthly one comes on its day of the month', () async {
    await (await notifier()).save(
      _reminder(repeat: ReminderRepeat.monthly, dayOfMonth: 15),
    );
    expect(scheduler.monthDays.values.single, 15);
    expect(scheduler.weekdays, isEmpty);
  });

  test('editing it takes away the moments it no longer has', () async {
    final owner = await notifier();
    await owner.save(_reminder(times: const [480, 600, 720]));
    expect(mine(), hasLength(3));
    await owner.save(_reminder(times: const [480]));
    expect(mine(), hasLength(1));
    expect(repository.reminders.single.times, [480]);
    // Daily becomes weekly: the daily ones are gone, not left behind.
    await owner.save(
      _reminder(repeat: ReminderRepeat.weekly, weekdays: const {2}),
    );
    expect(mine(), hasLength(1));
    expect(scheduler.weekdays.values.single, 2);
  });

  test('switched off it comes no more; on again it does', () async {
    final owner = await notifier();
    await owner.save(_reminder());
    expect(await owner.setEnabled('a', false), ReminderToggleResult.disabled);
    expect(mine(), isEmpty);
    expect(repository.reminders.single.enabled, isFalse);
    expect(await owner.setEnabled('a', true), ReminderToggleResult.enabled);
    expect(mine(), hasLength(1));
  });

  test('deleting it removes it from the list and the schedule', () async {
    final owner = await notifier();
    await owner.save(_reminder(times: const [480, 600]));
    await owner.save(_reminder(id: 'b', title: 'ورد'));
    await owner.remove('a');
    expect(repository.reminders.map((r) => r.id), ['b']);
    expect(mine(), hasLength(1));
  });

  test('without the notification permission it is kept, but off', () async {
    scheduler.allow = false;
    final owner = await notifier();
    expect(await owner.save(_reminder()), ReminderSaveResult.permissionDenied);
    expect(repository.reminders.single.enabled, isFalse);
    expect(mine(), isEmpty);
    expect(
      await owner.setEnabled('a', true),
      ReminderToggleResult.permissionDenied,
    );
  });

  test('one that cannot be saved is refused and changes nothing', () async {
    final owner = await notifier();
    expect(
      await owner.save(_reminder(title: '   ')),
      ReminderSaveResult.refused,
    );
    expect(
      await owner.save(_reminder(times: const [])),
      ReminderSaveResult.refused,
    );
    expect(repository.reminders, isEmpty);
    expect(mine(), isEmpty);
  });

  test('no more reminders than are allowed', () async {
    final owner = await notifier();
    for (var i = 0; i < CustomReminder.maxReminders; i++) {
      await owner.save(_reminder(id: 'r$i', title: 't$i'));
    }
    expect(owner.canAdd, isFalse);
    expect(
      await owner.save(_reminder(id: 'extra', title: 'x')),
      ReminderSaveResult.refused,
    );
    // An existing one can still be edited.
    expect(
      await owner.save(_reminder(id: 'r0', title: 'edited')),
      ReminderSaveResult.saved,
    );
  });

  test('at start-up the saved ones that are on are scheduled again, in the '
      'app\'s language', () async {
    repository.reminders = [
      _reminder(id: 'on', title: 'مذاكرة'),
      _reminder(id: 'off', title: 'مهمل', enabled: false),
    ];
    final english = make(locale: 'en');
    // The language is known before the reminders are read, as in the app.
    await english.read(settingsProvider.future);
    await english.read(customRemindersProvider.future);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(mine(), hasLength(1));
    final sent = scheduler.scheduled.values.single;
    expect(sent.title, 'مذاكرة');
    expect(sent.body, 'A reminder you made.');
    expect(sent.settingsLabel, 'Settings');
  });
}
