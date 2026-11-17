import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';
import 'package:mre_quran/core/time/ticking_clock.dart';
import 'package:mre_quran/features/adhan/application/adhan_providers.dart';
import 'package:mre_quran/features/adhan/domain/adhan_settings.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/domain/prayer_alerts.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';

import '../../helpers/adhan_fixtures.dart';
import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_settings_repository.dart';

final _cairo = PrayerPlace(30.0444, 31.2357);
final _now = DateTime(2026, 10, 8, 3);

class _Harness {
  _Harness({
    required this.container,
    required this.scheduler,
    required this.platform,
    required this.adhan,
    required this.store,
  });

  final ProviderContainer container;
  final FakeReminderScheduler scheduler;
  final FakeAdhanPlatform platform;
  final MemoryAdhanRepository adhan;
  final FakeVoiceStore store;

  Future<void> turnAllOn() async {
    await container.read(prayerProvider.future);
    await container.read(prayerProvider.notifier).setAllAlerts(true);
  }
}

_Harness _harness({
  bool supported = true,
  bool exact = true,
  AdhanSettings settings = const AdhanSettings(),
  Set<String> saved = const {},
}) {
  final scheduler = FakeReminderScheduler()..exactAllowed = exact;
  final platform = FakeAdhanPlatform(supported: supported);
  final adhan = MemoryAdhanRepository()..settings = settings;
  final store = FakeVoiceStore(saved: saved);
  final container = ProviderContainer(
    overrides: [
      reminderSchedulerProvider.overrideWithValue(scheduler),
      locationSourceProvider.overrideWithValue(
        FakeLocationSource(requestResult: _cairo),
      ),
      prayerRepositoryProvider.overrideWithValue(MemoryPrayerRepository()),
      clockProvider.overrideWithValue(() => _now),
      settingsRepositoryProvider.overrideWithValue(MemorySettingsRepository()),
      adhanPlatformProvider.overrideWithValue(platform),
      adhanRepositoryProvider.overrideWithValue(adhan),
      adhanCatalogSourceProvider.overrideWithValue(FakeAdhanCatalog()),
      voiceStoreProvider.overrideWithValue(store),
    ],
  );
  addTearDown(container.dispose);
  return _Harness(
    container: container,
    scheduler: scheduler,
    platform: platform,
    adhan: adhan,
    store: store,
  );
}

Iterable<int> _atTimeNotifications(_Harness h) => [
  for (final MapEntry(:key, :value) in h.scheduler.once.entries)
    if (value.channel == ReminderChannel.prayer) key,
];

Iterable<int> _beforeNotifications(_Harness h) => [
  for (final MapEntry(:key, :value) in h.scheduler.once.entries)
    if (value.channel == ReminderChannel.prayerSoon) key,
];

/// Every prayer of every planned day.
int get _allAlarms => PrayerNotifier.planDays * DailyPrayer.values.length;

/// With the reminder before each prayer, notifications come in pairs, and
/// only the earliest the system is given are kept.
int get _atTimeWithin => PrayerNotifier.notificationLimit ~/ 2;

void main() {
  test(
    'the at-time alerts go to the adhan player, not to notifications',
    () async {
      final h = _harness();
      await h.turnAllOn();

      expect(h.platform.alarms, hasLength(_allAlarms));
      expect(h.platform.alarms.first.title, 'حان وقت صلاة الفجر');
      expect(h.platform.config!.stopLabel, 'إيقاف الأذان');
      expect(h.platform.config!.stopWhenFlipped, isTrue);
      expect(h.platform.config!.voicePath, isNull, reason: 'bundled voice');
      expect(h.platform.config!.payload, 'prayer:times');
      expect(_atTimeNotifications(h), isEmpty);
    },
  );

  test('the chosen downloaded voice is the one handed over', () async {
    final h = _harness(
      settings: const AdhanSettings(voiceId: 'madinah'),
      saved: {'madinah'},
    );
    await h.turnAllOn();
    expect(h.platform.config!.voicePath, endsWith('madinah.audio'));
  });

  test('a voice that has gone falls back to the bundled one', () async {
    final h = _harness(settings: const AdhanSettings(voiceId: 'madinah'));
    await h.turnAllOn();
    expect(h.platform.config!.voicePath, isNull);
    expect(h.platform.alarms, hasLength(_allAlarms));
  });

  test('without exact alarms the alerts stay normal notifications', () async {
    final h = _harness(exact: false);
    await h.turnAllOn();
    expect(h.platform.alarms, isEmpty);
    expect(_atTimeNotifications(h), hasLength(_atTimeWithin));
  });

  test(
    'a phone that cannot play by itself keeps normal notifications',
    () async {
      final h = _harness(supported: false);
      await h.turnAllOn();
      expect(h.platform.alarms, isEmpty);
      expect(_atTimeNotifications(h), hasLength(_atTimeWithin));
    },
  );

  test(
    'with the style off the alerts are notifications and the player is cleared',
    () async {
      final h = _harness(settings: const AdhanSettings(playAdhan: false));
      await h.turnAllOn();
      expect(h.platform.alarms, isEmpty);
      expect(h.platform.cancels, greaterThan(0));
      expect(_atTimeNotifications(h), hasLength(_atTimeWithin));
    },
  );

  test('turning all alerts off clears the adhan alarms', () async {
    final h = _harness();
    await h.turnAllOn();
    await h.container.read(prayerProvider.notifier).setAllAlerts(false);
    expect(h.platform.alarms, isEmpty);
    expect(h.scheduler.once, isEmpty);
  });

  test('changing the voice or the style schedules again', () async {
    final h = _harness(saved: {'madinah'});
    await h.turnAllOn();
    expect(h.platform.config!.voicePath, isNull);

    await h.container
        .read(adhanSettingsProvider.notifier)
        .change((value) => value.copyWith(voiceId: 'madinah'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(h.platform.config!.voicePath, endsWith('madinah.audio'));

    await h.container
        .read(adhanSettingsProvider.notifier)
        .change((value) => value.copyWith(playAdhan: false));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(h.platform.alarms, isEmpty);
    expect(_atTimeNotifications(h), hasLength(_atTimeWithin));
  });

  test('the after-prayer adhkar reminders stay notifications', () async {
    final h = _harness();
    await h.turnAllOn();
    await h.container.read(prayerProvider.notifier).setAdhkarReminder(true);
    final after = h.scheduler.once.entries.where(
      (entry) => entry.value.channel == ReminderChannel.adhkar,
    );
    expect(after, isNotEmpty);
    expect(
      after.length + _beforeNotifications(h).length,
      PrayerNotifier.notificationLimit,
    );
  });

  test('a reminder comes before each prayer, and can move or stop', () async {
    final h = _harness();
    await h.turnAllOn();
    final first = h.scheduler.once[PrayerAlertPlan.firstBeforeId]!;
    final fajr = h.platform.alarms.first;
    expect(first.title, 'اقتربت صلاة الفجر');
    expect(first.body, 'باقي ١٥ دقيقة على الأذان');
    expect(fajr.at.difference(first.at), const Duration(minutes: 15));
    expect(first.exact, isTrue);

    final notifier = h.container.read(prayerProvider.notifier);
    await notifier.setBeforeMinutes(5);
    final moved = h.scheduler.once[PrayerAlertPlan.firstBeforeId]!;
    expect(fajr.at.difference(moved.at), const Duration(minutes: 5));
    expect(moved.body, 'باقي ٥ دقائق على الأذان');

    await notifier.setBeforeReminder(false);
    expect(_beforeNotifications(h), isEmpty);
    // The adhan itself is untouched.
    expect(h.platform.alarms, hasLength(_allAlarms));
  });

  test('Fajr plays the Fajr adhan; every adhan is announced, Friday\'s '
      'Dhuhr as the Friday prayer', () async {
    final h = _harness();
    await h.turnAllOn();
    final alarms = h.platform.alarms;
    expect(
      alarms.where((alarm) => alarm.fajr),
      hasLength(PrayerNotifier.planDays),
    );
    expect(alarms.first.fajr, isTrue);
    expect(alarms.first.announce, 'fajr');
    final friday = alarms.firstWhere(
      (alarm) =>
          alarm.at.weekday == DateTime.friday && alarm.announce == 'jumuah',
    );
    expect(friday.title, 'حان وقت صلاة الجمعة');
    expect(
      alarms.where(
        (alarm) =>
            alarm.at.weekday != DateTime.friday && alarm.announce == 'jumuah',
      ),
      isEmpty,
    );
  });

  test(
    'the announcement, the dua and the Fajr voice reach the player',
    () async {
      final h = _harness(
        settings: const AdhanSettings(
          fajrVoiceId: 'fajr_voice',
          announce: false,
        ),
        saved: {'fajr_voice'},
      );
      await h.turnAllOn();
      final config = h.platform.config!;
      expect(config.announce, isFalse);
      expect(config.duaAfter, isTrue);
      expect(config.fajrVoicePath, endsWith('fajr_voice.audio'));
      expect(config.voicePath, isNull, reason: 'bundled voice');
    },
  );

  test('scheduling again leaves other reminders alone', () async {
    final h = _harness();
    await h.scheduler.scheduleOnce(
      id: 42,
      at: _now.add(const Duration(days: 1)),
      title: 'other',
      body: '',
      channel: ReminderChannel.adhkar,
      channelName: '',
      payload: '',
    );
    await h.turnAllOn();
    await h.container.read(prayerProvider.notifier).setAllAlerts(false);
    expect(h.scheduler.once.keys, [42]);
  });
}
