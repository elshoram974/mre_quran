import 'package:mre_quran/features/prayer/data/prayer_soon_platform.dart';

/// Records the countdown reminders the app hands to the platform.
class FakePrayerSoonPlatform implements PrayerSoonPlatform {
  /// The reminders as last scheduled.
  List<PrayerSoonAlarm> alarms = [];

  /// The config they were scheduled with.
  PrayerSoonConfig? config;

  /// How many times they were all removed.
  int cancels = 0;

  @override
  Future<void> schedule(
    List<PrayerSoonAlarm> alarms,
    PrayerSoonConfig config,
  ) async {
    this.alarms = alarms;
    this.config = config;
  }

  @override
  Future<void> cancelAll() async {
    cancels++;
    alarms = [];
  }
}
