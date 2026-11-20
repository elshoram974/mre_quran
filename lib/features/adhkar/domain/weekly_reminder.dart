import 'package:meta/meta.dart';

import 'reminder_setting.dart';

/// A reminder that comes once a week, such as reading Surat Al-Kahf on Friday.
/// They are defined in `assets/reminders/weekly.json`, so one is added there,
/// with no code.
@immutable
class WeeklyReminder {
  /// Creates a reminder.
  const WeeklyReminder({
    required this.id,
    required this.weekday,
    required this.minutes,
    required this.titles,
    required this.bodies,
    required this.surah,
    this.enabledByDefault = false,
  });

  /// Reads one entry of the JSON file. Returns null for anything unreadable,
  /// so one bad entry does not stop the rest.
  static WeeklyReminder? tryFromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    final weekday = json['weekday'];
    final minutes = ReminderSetting.parseClock(json['time']);
    final titles = _texts(json['title']);
    final bodies = _texts(json['body']);
    final surah = json['surah'];
    if (id is! String ||
        id.isEmpty ||
        weekday is! int ||
        weekday < DateTime.monday ||
        weekday > DateTime.sunday ||
        minutes == null ||
        titles == null ||
        bodies == null) {
      return null;
    }
    return WeeklyReminder(
      id: id,
      weekday: weekday,
      minutes: minutes,
      titles: titles,
      bodies: bodies,
      surah: surah is int && surah >= 1 && surah <= 114 ? surah : null,
      enabledByDefault: json['enabled'] == true,
    );
  }

  static Map<String, String>? _texts(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final texts = {
      for (final entry in json.entries)
        if (entry.value case final String text when text.isNotEmpty)
          entry.key: text,
    };
    return texts.isEmpty ? null : texts;
  }

  /// A stable name, such as `friday_kahf`.
  final String id;

  /// The day of the week, 1 Monday to 7 Sunday.
  final int weekday;

  /// The default time, minutes after midnight.
  final int minutes;

  /// The notice's title by language.
  final Map<String, String> titles;

  /// The notice's words by language.
  final Map<String, String> bodies;

  /// The surah a tap opens the Mushaf at, if any.
  final int? surah;

  /// Whether it is on until the person turns it off (`"enabled": true` in the
  /// file); off until they turn it on otherwise.
  final bool enabledByDefault;

  /// The title in [language], else Arabic, else any.
  String title(String language) => _pick(titles, language);

  /// The words in [language], else Arabic, else any.
  String body(String language) => _pick(bodies, language);

  static String _pick(Map<String, String> texts, String language) =>
      texts[language] ?? texts['ar'] ?? texts.values.first;
}

/// Reads the reminders of the JSON file [source], skipping any that cannot be
/// read.
List<WeeklyReminder> parseWeeklyReminders(Object? source) {
  if (source is! Map<String, Object?>) return const [];
  final list = source['reminders'];
  if (list is! List<Object?>) return const [];
  final seen = <String>{};
  return [
    for (final entry in list)
      if (WeeklyReminder.tryFromJson(entry) case final reminder?)
        if (seen.add(reminder.id)) reminder,
  ];
}
