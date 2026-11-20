import 'package:meta/meta.dart';

/// One time in a widget preview: `fajr`, `sunrise`, `dhuhr`, `asr`,
/// `maghrib` or `isha`, as it is named and timed in the widgets' language.
@immutable
class WidgetPreviewRow {
  /// Creates a row.
  const WidgetPreviewRow({
    required this.id,
    required this.name,
    required this.time,
  });

  /// Which prayer (or `sunrise`).
  final String id;

  /// Its name.
  final String name;

  /// Its time, as the widget writes it.
  final String time;
}

/// Everything a preview of a home-screen widget says, in the language the
/// widgets speak: the words, the dates, the clock and the direction.
@immutable
class WidgetPreviewData {
  /// Creates the data. [rows] are Fajr, sunrise, Dhuhr, Asr, Maghrib and Isha.
  const WidgetPreviewData({
    required this.language,
    required this.rtl,
    required this.rows,
    required this.nextId,
    required this.nextLabel,
    required this.date,
    required this.hijri,
    required this.remaining,
    required this.tasbihName,
    required this.tasbihCount,
    required this.dhikrName,
    required this.dhikrCount,
    required this.dhikrTitle,
  });

  /// `ar` or `en`.
  final String language;

  /// Whether the language reads right to left.
  final bool rtl;

  /// The day's six times.
  final List<WidgetPreviewRow> rows;

  /// The id of the coming prayer.
  final String nextId;

  /// "Next prayer".
  final String nextLabel;

  /// The date.
  final String date;

  /// The Hijri date.
  final String hijri;

  /// "in 1 h 24 min".
  final String remaining;

  /// The tasbih widget's name.
  final String tasbihName;

  /// The tasbih count shown.
  final String tasbihCount;

  /// The dhikr widget's name.
  final String dhikrName;

  /// How far through the dhikr: "3 of 12".
  final String dhikrCount;

  /// The suggested dhikr's name.
  final String dhikrTitle;

  /// The coming prayer's row.
  WidgetPreviewRow get next =>
      rows.firstWhere((row) => row.id == nextId, orElse: () => rows.first);
}
