import 'package:mre_quran/core/notifications/reminder_scheduler.dart';
import 'package:mre_quran/features/prayer/data/prayer_soon_platform.dart';

import 'adhkar_fixtures.dart';

/// Records the prayer notices the app hands to the platform.
class FakePrayerSoonPlatform implements PrayerSoonPlatform {
  /// The reminders as last scheduled.
  List<PrayerSoonAlarm> alarms = [];

  /// The config they were scheduled with.
  PrayerSoonConfig? config;

  /// How many times they were all removed.
  int cancels = 0;

  /// Whether the fake platform takes the notices (false: as if it failed).
  bool works = true;

  /// The countdown reminders as last scheduled.
  List<PrayerSoonAlarm> get countdowns =>
      alarms.where((alarm) => alarm.countdown).toList();

  /// The plain notices as last scheduled.
  List<PrayerSoonAlarm> get plain =>
      alarms.where((alarm) => !alarm.countdown).toList();

  @override
  Future<bool> schedule(
    List<PrayerSoonAlarm> alarms,
    PrayerSoonConfig config,
  ) async {
    if (!works) return false;
    this.alarms = alarms;
    this.config = config;
    return true;
  }

  @override
  Future<void> cancelAll() async {
    cancels++;
    alarms = [];
  }
}

/// Every prayer notice without a countdown that was handed over: to the
/// notifications plugin ([scheduler]), and on Android to the app's own
/// scheduler ([soon]), by id, in the plugin's terms.
Map<int, OnceNotice> handedOver(
  FakeReminderScheduler scheduler,
  FakePrayerSoonPlatform soon,
) => {
  ...scheduler.once,
  for (final alarm in soon.plain)
    alarm.id: (
      at: alarm.at,
      title: alarm.title,
      body: alarm.body,
      payload: alarm.payload!,
      channel: ReminderChannel.values.firstWhere(
        (channel) => channel.id == alarm.channel,
      ),
      // Android's own scheduler arms each to the minute, as it arms one at
      // a time and a late one would hold back the rest.
      exact: true,
      silent: alarm.silent!,
      settingsLabel: soon.config?.settingsLabel,
    ),
};
