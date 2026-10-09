import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/prayer/domain/hijri_date.dart';

void main() {
  test('follows the Umm al-Qura calendar', () {
    final today = HijriDate.of(DateTime(2026, 10, 8));
    expect((today.year, today.month, today.day), (1448, 4, 27));
  });

  test('Ramadan and Shawwal begin where the calendar says', () {
    final ramadan = HijriDate.of(DateTime(2026, 2, 18));
    expect((ramadan.year, ramadan.month, ramadan.day), (1447, 9, 1));
    final shawwal = HijriDate.of(DateTime(2025, 3, 30));
    expect((shawwal.year, shawwal.month, shawwal.day), (1446, 10, 1));
  });
}
