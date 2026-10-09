import 'package:flutter/services.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../domain/prayer_times.dart';

/// One prayer row in the daily home-screen widget.
class PrayerWidgetTime {
  const PrayerWidgetTime({required this.name, required this.time});

  final String name;
  final String time;

  Map<String, String> toMap() => {'name': name, 'time': time};
}

/// One day of times for the widgets, so they can move on to the next prayer
/// by themselves while the app is closed.
class PrayerWidgetDay {
  /// Creates a day from [start] (inclusive) to [end] (exclusive).
  const PrayerWidgetDay({
    required this.start,
    required this.end,
    required this.dateLabel,
    required this.hijriLabel,
    required this.rows,
  });

  /// Midnight that begins the day.
  final DateTime start;

  /// Midnight that ends it.
  final DateTime end;

  /// The date as shown in the widget.
  final String dateLabel;

  /// The Hijri date as shown in the widget.
  final String hijriLabel;

  /// Fajr, sunrise, Dhuhr, Asr, Maghrib and Isha, in that order.
  final List<PrayerWidgetRow> rows;

  Map<String, Object> toMap() => {
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
    'dateLabel': dateLabel,
    'hijriLabel': hijriLabel,
    'rows': [for (final row in rows) row.toMap()],
  };
}

/// A time in a [PrayerWidgetDay].
class PrayerWidgetRow {
  /// Creates a row. [id] is the prayer's name, or `sunrise`.
  const PrayerWidgetRow({
    required this.id,
    required this.name,
    required this.time,
    required this.at,
  });

  /// `fajr`, `sunrise`, `dhuhr`, `asr`, `maghrib` or `isha`.
  final String id;

  /// The localized name.
  final String name;

  /// The time as shown.
  final String time;

  /// The moment it begins.
  final DateTime at;

  Map<String, Object> toMap() => {
    'id': id,
    'name': name,
    'time': time,
    'at': at.millisecondsSinceEpoch,
  };
}

/// The widget's own texts in the app's language. Where a number goes there is
/// a `%1$s` (and `%2$s`) for the platform to fill, because the countdown is
/// worked out by the widget.
class PrayerWidgetLabels {
  /// Creates the labels.
  const PrayerWidgetLabels({
    required this.next,
    required this.remaining,
    required this.hours,
    required this.minutes,
    required this.empty,
  });

  /// "Next prayer".
  final String next;

  /// "%1$s left", around the duration.
  final String remaining;

  /// "%1$s h %2$s min".
  final String hours;

  /// "%1$s min".
  final String minutes;

  /// What to say before there is a place.
  final String empty;

  Map<String, String> toMap() => {
    'next': next,
    'remaining': remaining,
    'hours': hours,
    'minutes': minutes,
    'empty': empty,
  };
}

/// Data rendered by the platform's next-prayer home-screen widget.
class PrayerWidgetData {
  /// Creates widget data from the already calculated next prayer.
  const PrayerWidgetData({
    required this.prayer,
    required this.label,
    required this.title,
    required this.time,
    required this.at,
    required this.useArabicDigits,
    required this.times,
    this.days = const [],
    this.labels,
    this.rtl = true,
  });

  final DailyPrayer prayer;
  final String label;
  final String title;
  final String time;
  final DateTime at;
  final bool useArabicDigits;
  final List<PrayerWidgetTime> times;

  /// The next few days, for widgets that keep time on their own.
  final List<PrayerWidgetDay> days;

  /// The widget's texts in the app's language.
  final PrayerWidgetLabels? labels;

  /// Whether the app's language reads right to left.
  final bool rtl;

  Map<String, Object> toMap() => {
    'prayer': prayer.name,
    'label': label,
    'title': title,
    'time': time,
    'at': at.millisecondsSinceEpoch,
    'useArabicDigits': useArabicDigits,
    'times': [for (final item in times) item.toMap()],
    'rtl': rtl,
    if (labels != null) 'labels': labels!.toMap(),
    if (days.isNotEmpty) 'days': [for (final day in days) day.toMap()],
  };
}

/// Shares prayer data with native Android and iOS widgets.
///
/// The widgets render independently of Flutter. This bridge only writes fresh
/// data after the app calculates a new next prayer.
final class PrayerWidgetSync {
  PrayerWidgetSync._();

  static const _channel = MethodChannel('net.mrecode.mre_quran/prayer_widget');

  /// Replaces the widget's data, or clears it when no prayer place exists.
  static Future<void> update(PrayerWidgetData? data) async {
    try {
      await _channel.invokeMethod<void>('update', data?.toMap());
    } on MissingPluginException {
      // Widgets exist only on Android and iOS.
    } on PlatformException catch (error) {
      AppLogger.debug('Prayer widget update failed: ${error.code}');
    }
  }
}
