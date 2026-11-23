import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/notifications/reminder_payload.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';
import 'package:mre_quran/core/time/ticking_clock.dart';
import 'package:mre_quran/features/adhkar/application/reminders_provider.dart';
import 'package:mre_quran/features/fasting/application/fasting_reminders_provider.dart';
import 'package:mre_quran/features/fasting/domain/sunnah_fasts.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_fasting_repository.dart';
import '../../helpers/memory_settings_repository.dart';

void main() {
  // Sunday 3 January 2027, ten in the morning.
  final now = DateTime(2027, 1, 3, 10);

  late FakeReminderScheduler scheduler;
  late MemoryFastingRepository repository;
  late ProviderContainer container;

  setUp(() {
    scheduler = FakeReminderScheduler();
    repository = MemoryFastingRepository();
    container = ProviderContainer(
      overrides: [
        reminderSchedulerProvider.overrideWithValue(scheduler),
        fastingRepositoryProvider.overrideWithValue(repository),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
        clockProvider.overrideWithValue(() => now),
      ],
    );
  });
  tearDown(() => container.dispose());

  /// Lets the schedule the provider started finish.
  Future<void> settled() async {
    await container.read(fastingRemindersProvider.future);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  Iterable<int> planned() => scheduler.once.keys.where(FastingPlan.owns);

  test('from the start, every sunnah fast of the coming two months is '
      'reminded of, the evening before', () async {
    await settled();
    final expected = FastingPlan.compute(
      now: now,
      settings: const FastingSettings(),
      days: FastingRemindersNotifier.androidDays,
    );
    expect(planned().toSet(), {for (final r in expected) r.id});
    final first = scheduler.once[expected.first.id]!;
    expect(first.at, DateTime(2027, 1, 3, 21));
    expect(first.title, 'صيام سنة غدًا');
    expect(first.settingsLabel, 'الإعدادات');
    expect(first.body, contains('غدًا الاثنين'));
    expect(first.channel, ReminderChannel.fasting);
    expect(first.payload, ReminderPayload.prayerTimes);
  });

  test('a fast turned off is no longer reminded of, and stays off', () async {
    await settled();
    final notifier = container.read(fastingRemindersProvider.notifier);
    expect(
      await notifier.setFast(SunnahFast.mondayThursday, false),
      ReminderToggleResult.disabled,
    );
    for (final id in planned()) {
      expect(scheduler.once[id]!.body, isNot(contains('الاثنين،')));
      expect(scheduler.once[id]!.body, isNot(contains('الخميس،')));
    }
    expect(
      repository.settings.fasts,
      isNot(contains(SunnahFast.mondayThursday)),
    );
  });

  test('all off, nothing is planned', () async {
    await settled();
    final notifier = container.read(fastingRemindersProvider.notifier);
    for (final fast in SunnahFast.values) {
      await notifier.setFast(fast, false);
    }
    expect(planned(), isEmpty);
  });

  test('a new time moves every reminder', () async {
    await settled();
    await container.read(fastingRemindersProvider.notifier).setTime(20 * 60);
    for (final id in planned()) {
      final at = scheduler.once[id]!.at;
      expect((at.hour, at.minute), (20, 0));
    }
    expect(repository.settings.minutes, 20 * 60);
  });

  test('turning one on without notifications allowed leaves it off', () async {
    repository.settings = const FastingSettings(fasts: {});
    await settled();
    scheduler.allow = false;
    final result = await container
        .read(fastingRemindersProvider.notifier)
        .setFast(SunnahFast.arafah, true);
    expect(result, ReminderToggleResult.permissionDenied);
    expect(repository.settings.fasts, isEmpty);
    expect(planned(), isEmpty);
  });

  test('other reminders are left alone', () async {
    scheduler.once[42] = (
      at: now,
      title: 'other',
      body: '',
      payload: '',
      channel: ReminderChannel.adhkar,
      exact: false,
      countdownTo: null,
      dismissLabel: null,
      settingsLabel: null,
    );
    await settled();
    await container
        .read(fastingRemindersProvider.notifier)
        .setFast(SunnahFast.mondayThursday, false);
    expect(scheduler.once.keys, contains(42));
  });

  test('on iOS, a few weeks and a few reminders, within its 64', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await settled();
    expect(
      planned().length,
      lessThanOrEqualTo(FastingRemindersNotifier.iosLimit),
    );
    for (final id in planned()) {
      expect(
        scheduler.once[id]!.at.difference(now).inDays,
        lessThan(FastingRemindersNotifier.iosDays),
      );
    }
  });

  test('the next day of each fast is known for the switches', () {
    final next = container.read(fastingNextDaysProvider);
    expect(next[SunnahFast.mondayThursday], DateTime(2027, 1, 4));
    for (final day in next.values) {
      expect(day, isNotNull);
      expect(day!.isAfter(now), isTrue);
    }
  });
}
