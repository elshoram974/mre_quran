import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/home_widgets/data/home_widgets_platform.dart';
import 'package:mre_quran/features/home_widgets/domain/prayer_schedule_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('net.mrecode.mre_quran/home_widgets');
  const platform = MethodChannelHomeWidgets();

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test(
    'schedule preferences are read and saved through the native channel',
    () async {
      Map<String, bool> saved = const PrayerScheduleOptions().toMap();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            switch (call.method) {
              case 'prayerScheduleOptions':
                return saved;
              case 'setPrayerScheduleOptions':
                saved = Map<String, bool>.from(call.arguments as Map);
                return true;
            }
            return null;
          });
      final next = (await platform.prayerScheduleOptions()).copyWith(
        upcomingOnly: true,
        showSunrise: false,
        showDate: false,
        largeText: true,
      );
      expect(await platform.setPrayerScheduleOptions(next), isTrue);
      expect((await platform.prayerScheduleOptions()).toMap(), next.toMap());
    },
  );

  test('a missing platform keeps safe defaults', () async {
    final options = await platform.prayerScheduleOptions();
    expect(options.toMap(), const PrayerScheduleOptions().toMap());
    expect(await platform.setPrayerScheduleOptions(options), isFalse);
  });
}
