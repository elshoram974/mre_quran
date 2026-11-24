import 'package:hijri/hijri_calendar.dart';

/// A date in the Hijri calendar (Umm al-Qura), month 1 being Muharram.
///
/// The calendar follows the Umm al-Qura tables, which can differ by a day
/// from local moon sighting.
class HijriDate {
  /// Creates a date.
  const HijriDate({required this.year, required this.month, required this.day});

  /// The Hijri date that falls on [date], moved by [shift] days when the
  /// person found the calendar a day or two off the moon sighting.
  factory HijriDate.of(DateTime date, {int shift = 0}) {
    final converted = HijriCalendar.fromDate(
      DateTime(date.year, date.month, date.day + shift, date.hour),
    );
    return HijriDate(
      year: converted.hYear,
      month: converted.hMonth,
      day: converted.hDay,
    );
  }

  /// The year, such as 1448.
  final int year;

  /// The month, 1 to 12.
  final int month;

  /// The day of the month, 1 to 30.
  final int day;
}
