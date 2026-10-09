import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/prayer/application/prayer_widget_sync.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';

void main() {
  final at = DateTime(2026, 10, 8, 12);

  test('widget payload keeps the next prayer and digit preference', () {
    final data = PrayerWidgetData(
      prayer: DailyPrayer.dhuhr,
      label: 'الصلاة القادمة',
      title: 'الظهر',
      time: '١٢:٠٠',
      at: at,
      useArabicDigits: true,
      times: const [PrayerWidgetTime(name: 'الظهر', time: '١٢:٠٠')],
    );

    expect(data.toMap(), {
      'prayer': 'dhuhr',
      'label': 'الصلاة القادمة',
      'title': 'الظهر',
      'time': '١٢:٠٠',
      'at': at.millisecondsSinceEpoch,
      'useArabicDigits': true,
      'times': [
        {'name': 'الظهر', 'time': '١٢:٠٠'},
      ],
      'rtl': true,
    });
  });

  test('the days and labels reach the widget as plain maps', () {
    final midnight = DateTime(2026, 10, 8);
    final data = PrayerWidgetData(
      prayer: DailyPrayer.dhuhr,
      label: 'Next prayer',
      title: 'Dhuhr',
      time: '12:00 PM',
      at: at,
      useArabicDigits: false,
      rtl: false,
      times: const [],
      labels: const PrayerWidgetLabels(
        next: 'Next prayer',
        remaining: r'in %1$s',
        hours: r'%1$s h %2$s min',
        minutes: r'%1$s min',
        empty: 'Open the app',
      ),
      days: [
        PrayerWidgetDay(
          start: midnight,
          end: DateTime(2026, 10, 9),
          dateLabel: 'Thu, Oct 8',
          hijriLabel: "27 Rabi' al-Thani 1448 AH",
          rows: [
            PrayerWidgetRow(
              id: 'dhuhr',
              name: 'Dhuhr',
              time: '12:00 PM',
              at: at,
            ),
          ],
        ),
      ],
    );

    final map = data.toMap();
    expect(map['rtl'], false);
    expect(map['labels'], {
      'next': 'Next prayer',
      'remaining': r'in %1$s',
      'hours': r'%1$s h %2$s min',
      'minutes': r'%1$s min',
      'empty': 'Open the app',
    });
    expect(map['days'], [
      {
        'start': midnight.millisecondsSinceEpoch,
        'end': DateTime(2026, 10, 9).millisecondsSinceEpoch,
        'dateLabel': 'Thu, Oct 8',
        'hijriLabel': "27 Rabi' al-Thani 1448 AH",
        'rows': [
          {
            'id': 'dhuhr',
            'name': 'Dhuhr',
            'time': '12:00 PM',
            'at': at.millisecondsSinceEpoch,
          },
        ],
      },
    ]);
  });
}
