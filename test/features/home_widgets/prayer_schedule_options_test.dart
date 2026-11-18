import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/home_widgets/domain/prayer_schedule_options.dart';

void main() {
  test('missing options restore the full schedule defaults', () {
    final options = PrayerScheduleOptions.fromMap(null);
    expect(options.upcomingOnly, isFalse);
    expect(options.showSunrise, isTrue);
    expect(options.showDate, isTrue);
    expect(options.showCountdown, isTrue);
    expect(options.largeText, isFalse);
  });

  test('choices survive the platform map round trip', () {
    final options = const PrayerScheduleOptions().copyWith(
      upcomingOnly: true,
      showSunrise: false,
      showDate: false,
      showCountdown: false,
      largeText: true,
    );
    final restored = PrayerScheduleOptions.fromMap(options.toMap());
    expect(restored.toMap(), options.toMap());
  });
}
