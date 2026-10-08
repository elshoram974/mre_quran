import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/prayer/application/prayer_widget_sync.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';

void main() {
  test('widget payload keeps the next prayer and digit preference', () {
    final at = DateTime(2026, 10, 8, 12);
    final data = PrayerWidgetData(
      prayer: DailyPrayer.dhuhr,
      label: 'الصلاة القادمة',
      title: 'الظهر',
      time: '١٢:٠٠',
      at: at,
      useArabicDigits: true,
    );

    expect(data.toMap(), {
      'prayer': 'dhuhr',
      'label': 'الصلاة القادمة',
      'title': 'الظهر',
      'time': '١٢:٠٠',
      'at': at.millisecondsSinceEpoch,
      'useArabicDigits': true,
    });
  });
}
