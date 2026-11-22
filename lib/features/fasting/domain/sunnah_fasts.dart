import 'package:meta/meta.dart';

import '../../prayer/domain/hijri_date.dart';

/// The sunnah fasts the app can remind of, each turned on or off on its own.
enum SunnahFast {
  /// Every Monday and Thursday.
  mondayThursday,

  /// The white days: the 13th, 14th and 15th of each Hijri month.
  whiteDays,

  /// The Day of Arafah, the 9th of Dhu al-Hijjah.
  arafah,

  /// Tasu'a and Ashura, the 9th and 10th of Muharram.
  ashura,

  /// Six days of Shawwal, after the Eid.
  shawwal,
}

/// Why a day is a sunnah fast.
enum FastReason {
  /// It is a Monday.
  monday,

  /// It is a Thursday.
  thursday,

  /// It is one of the white days.
  whiteDay,

  /// It is the Day of Arafah.
  arafah,

  /// It is Tasu'a.
  tasua,

  /// It is Ashura.
  ashura,

  /// The six days of Shawwal may begin on it.
  shawwal;

  /// The fast whose switch covers this reason.
  SunnahFast get fast => switch (this) {
    monday || thursday => SunnahFast.mondayThursday,
    whiteDay => SunnahFast.whiteDays,
    arafah => SunnahFast.arafah,
    tasua || ashura => SunnahFast.ashura,
    shawwal => SunnahFast.shawwal,
  };
}

/// The choices for the fasting reminders.
@immutable
class FastingSettings {
  /// Creates the choices. Every fast is reminded of until the person turns it
  /// off, the evening before at [minutes] after midnight.
  const FastingSettings({
    this.fasts = const {...SunnahFast.values},
    this.minutes = defaultMinutes,
  });

  /// Reads choices saved by [toJson]; anything unreadable gives the defaults.
  factory FastingSettings.fromJson(Object? json) {
    if (json is! Map<String, Object?>) return const FastingSettings();
    final fasts = json['fasts'];
    final minutes = json['minutes'];
    return FastingSettings(
      fasts: fasts is List<Object?>
          ? {
              for (final name in fasts)
                for (final fast in SunnahFast.values)
                  if (fast.name == name) fast,
            }
          : const {...SunnahFast.values},
      minutes: minutes is int && minutes >= 0 && minutes < 24 * 60
          ? minutes
          : defaultMinutes,
    );
  }

  /// Nine in the evening.
  static const int defaultMinutes = 21 * 60;

  /// The fasts reminded of.
  final Set<SunnahFast> fasts;

  /// When the reminder comes, the evening before: minutes after midnight.
  final int minutes;

  /// A copy with the given changes.
  FastingSettings copyWith({Set<SunnahFast>? fasts, int? minutes}) =>
      FastingSettings(
        fasts: fasts ?? this.fasts,
        minutes: minutes ?? this.minutes,
      );

  /// Compact form for storage.
  Map<String, Object?> toJson() => {
    'fasts': [for (final fast in fasts) fast.name],
    'minutes': minutes,
  };

  @override
  bool operator ==(Object other) =>
      other is FastingSettings &&
      other.minutes == minutes &&
      other.fasts.length == fasts.length &&
      other.fasts.containsAll(fasts);

  @override
  int get hashCode => Object.hash(minutes, Object.hashAllUnordered(fasts));
}

/// One reminder: the evening [at] before [day], a day to fast for [reasons].
@immutable
class FastReminder {
  /// Creates a reminder.
  const FastReminder({
    required this.id,
    required this.day,
    required this.at,
    required this.hijri,
    required this.reasons,
  });

  /// Stable notification id, from the day.
  final int id;

  /// The day to fast, at midnight.
  final DateTime day;

  /// When the reminder comes.
  final DateTime at;

  /// The Hijri date of [day].
  final HijriDate hijri;

  /// Why [day] is a fast, the yearly ones first.
  final List<FastReason> reasons;
}

/// Works out which days are sunnah fasts, and the reminders before them.
///
/// The Hijri dates are Umm al-Qura's (see [HijriDate]), which can be a day
/// off the moon sighting where the person is. So no reminder ever falls on a
/// day that could be a day when fasting is not allowed there: nothing in
/// Ramadan (its fast is due, not sunnah), on the 1st or 2nd of Shawwal (the
/// Eid), or from the 10th to the 14th of Dhu al-Hijjah (the Eid and the days
/// of Tashreeq). The six of Shawwal are reminded of for the 3rd, and the
/// white days are not in Dhu al-Hijjah, whose Arafah stands for them.
abstract final class FastingPlan {
  /// The id of the reminder for tomorrow; a day further on adds one.
  static const int firstId = 7003000;

  /// The most days a plan reaches ahead.
  static const int maxDays = 120;

  /// Whether [id] belongs to a fasting plan.
  static bool owns(int id) => id > firstId && id <= firstId + maxDays;

  /// Whether no voluntary fast is reminded of on [hijri], here or a day off.
  static bool closed(HijriDate hijri) =>
      hijri.month == 9 ||
      (hijri.month == 10 && hijri.day <= 2) ||
      (hijri.month == 12 && hijri.day >= 10 && hijri.day <= 14);

  /// Why [day] (whose Hijri date is [hijri]) is a fast among [fasts]; empty
  /// when it is none.
  static List<FastReason> reasonsOn(
    DateTime day,
    HijriDate hijri,
    Set<SunnahFast> fasts,
  ) {
    if (closed(hijri)) return const [];
    final month = hijri.month;
    final date = hijri.day;
    return [
      if (month == 12 && date == 9) FastReason.arafah,
      if (month == 1 && date == 9) FastReason.tasua,
      if (month == 1 && date == 10) FastReason.ashura,
      if (month == 10 && date == 3) FastReason.shawwal,
      if (month != 12 && date >= 13 && date <= 15) FastReason.whiteDay,
      if (day.weekday == DateTime.monday) FastReason.monday,
      if (day.weekday == DateTime.thursday) FastReason.thursday,
    ].where((reason) => fasts.contains(reason.fast)).toList();
  }

  /// The reminders after [now] for the fasts of [settings], over the next
  /// [days] days, by time. [hijriOf] gives a day's Hijri date.
  static List<FastReminder> compute({
    required DateTime now,
    required FastingSettings settings,
    int days = 60,
    HijriDate Function(DateTime) hijriOf = HijriDate.of,
  }) {
    assert(days >= 1 && days <= maxDays);
    final reminders = <FastReminder>[];
    if (settings.fasts.isEmpty) return reminders;
    for (var offset = 1; offset <= days; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset);
      final hijri = hijriOf(day);
      final reasons = reasonsOn(day, hijri, settings.fasts);
      if (reasons.isEmpty) continue;
      final at = DateTime(
        day.year,
        day.month,
        day.day - 1,
        settings.minutes ~/ 60,
        settings.minutes % 60,
      );
      if (!at.isAfter(now)) continue;
      reminders.add(
        FastReminder(
          id: firstId + offset,
          day: day,
          at: at,
          hijri: hijri,
          reasons: reasons,
        ),
      );
    }
    return reminders;
  }

  /// The next day after [now] that is a fast of [fast], looking up to a
  /// Hijri year and a little more ahead; null if none is found.
  static DateTime? next(
    SunnahFast fast, {
    required DateTime now,
    HijriDate Function(DateTime) hijriOf = HijriDate.of,
  }) {
    for (var offset = 1; offset <= 400; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset);
      if (reasonsOn(day, hijriOf(day), {fast}).isNotEmpty) return day;
    }
    return null;
  }
}
