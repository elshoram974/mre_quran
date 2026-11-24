import 'package:meta/meta.dart';

/// How often a reminder the person made comes.
enum ReminderRepeat {
  /// Every day.
  daily,

  /// On the chosen days of the week.
  weekly,

  /// On one day of every month.
  monthly;

  /// Reads a saved name, or null for anything else.
  static ReminderRepeat? tryParse(Object? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// One moment a reminder comes at: a time of day, on a day of the week for a
/// weekly one, or on a day of the month for a monthly one.
@immutable
class ReminderSlot {
  /// Creates a moment.
  const ReminderSlot({required this.minutes, this.weekday, this.dayOfMonth});

  /// Minutes after midnight.
  final int minutes;

  /// 1 Monday to 7 Sunday, for a weekly reminder.
  final int? weekday;

  /// 1 to 28, for a monthly reminder.
  final int? dayOfMonth;
}

/// A reminder the person made for themselves, with their own words.
///
/// It repeats daily, on chosen days of the week, or on a day of the month,
/// and may come at several times of the day.
@immutable
class CustomReminder {
  /// Creates a reminder. Prefer [normalized] for what the person typed.
  const CustomReminder({
    required this.id,
    required this.title,
    required this.times,
    this.note = '',
    this.repeat = ReminderRepeat.daily,
    this.weekdays = const {},
    this.dayOfMonth = 1,
    this.enabled = true,
  });

  /// Reads a reminder saved by [toJson]. Returns null for anything unreadable
  /// or out of range, so one bad entry does not stop the rest.
  static CustomReminder? tryFromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    final title = json['title'];
    final times = json['times'];
    final repeat = ReminderRepeat.tryParse(json['repeat']);
    if (id is! String ||
        id.isEmpty ||
        title is! String ||
        title.trim().isEmpty ||
        times is! List<Object?> ||
        repeat == null) {
      return null;
    }
    final weekdays = json['weekdays'];
    final reminder = CustomReminder(
      id: id,
      title: title,
      note: json['note'] is String ? json['note']! as String : '',
      repeat: repeat,
      times: [
        for (final time in times)
          if (time is int && time >= 0 && time < 1440) time,
      ],
      weekdays: {
        if (weekdays is List<Object?>)
          for (final day in weekdays)
            if (day is int && day >= DateTime.monday && day <= DateTime.sunday)
              day,
      },
      dayOfMonth: json['day'] is int ? json['day']! as int : 1,
      enabled: json['on'] != false,
    ).normalized();
    return reminder.problem == null ? reminder : null;
  }

  /// The most reminders a person may make: each is kept by the system, which
  /// holds only so many (iOS 64, shared with the prayer alerts).
  static const int maxReminders = 20;

  /// The most times of the day one reminder may have.
  static const int maxTimes = 6;

  /// The most moments one reminder may have: its times, over its days.
  static const int maxSlots = 14;

  /// The longest title.
  static const int maxTitle = 60;

  /// The longest note.
  static const int maxNote = 200;

  /// The last day of the month a monthly reminder may be on: every month has
  /// it.
  static const int maxDayOfMonth = 28;

  /// A name that stays the same for the reminder's life.
  final String id;

  /// What the notification's title says.
  final String title;

  /// What it says under the title; empty for a line the app words itself.
  final String note;

  /// How often it comes.
  final ReminderRepeat repeat;

  /// The days of the week of a weekly reminder, 1 Monday to 7 Sunday.
  final Set<int> weekdays;

  /// The day of the month of a monthly reminder, 1 to [maxDayOfMonth].
  final int dayOfMonth;

  /// Times of the day, minutes after midnight, earliest first.
  final List<int> times;

  /// Whether it comes.
  final bool enabled;

  /// A copy cleaned of what a form lets through: texts trimmed and cut to
  /// their length, times sorted and without repeats, days in range.
  CustomReminder normalized() {
    String clip(String text, int length) {
      final trimmed = text.trim();
      return trimmed.length <= length
          ? trimmed
          : trimmed.substring(0, length).trimRight();
    }

    return CustomReminder(
      id: id,
      title: clip(title, maxTitle),
      note: clip(note, maxNote),
      repeat: repeat,
      weekdays: {
        for (final day in weekdays)
          if (day >= DateTime.monday && day <= DateTime.sunday) day,
      },
      dayOfMonth: dayOfMonth.clamp(1, maxDayOfMonth),
      times: ({...times}.where((time) => time >= 0 && time < 1440).toList()
        ..sort()),
      enabled: enabled,
    );
  }

  /// What stops this being saved, or null when it can be.
  ReminderProblem? get problem {
    if (title.trim().isEmpty) return ReminderProblem.noTitle;
    if (times.isEmpty) return ReminderProblem.noTime;
    if (times.length > maxTimes) return ReminderProblem.tooManyTimes;
    if (repeat == ReminderRepeat.weekly && weekdays.isEmpty) {
      return ReminderProblem.noDay;
    }
    if (slots.length > maxSlots) return ReminderProblem.tooManyMoments;
    return null;
  }

  /// Every moment it comes at, which the system is given one by one.
  List<ReminderSlot> get slots => switch (repeat) {
    ReminderRepeat.daily => [
      for (final time in times) ReminderSlot(minutes: time),
    ],
    ReminderRepeat.weekly => [
      for (final day in (weekdays.toList()..sort()))
        for (final time in times) ReminderSlot(minutes: time, weekday: day),
    ],
    ReminderRepeat.monthly => [
      for (final time in times)
        ReminderSlot(minutes: time, dayOfMonth: dayOfMonth),
    ],
  };

  /// When it first comes after [now], or null when it has no moment yet.
  DateTime? nextAfter(DateTime now) {
    DateTime? first;
    for (final slot in slots) {
      final at = _next(slot, now);
      if (first == null || at.isBefore(first)) first = at;
    }
    return first;
  }

  static DateTime _next(ReminderSlot slot, DateTime now) {
    DateTime on(DateTime day) => DateTime(
      day.year,
      day.month,
      day.day,
      slot.minutes ~/ 60,
      slot.minutes % 60,
    );
    final dayOfMonth = slot.dayOfMonth;
    if (dayOfMonth != null) {
      final thisMonth = on(DateTime(now.year, now.month, dayOfMonth));
      return thisMonth.isAfter(now)
          ? thisMonth
          : on(DateTime(now.year, now.month + 1, dayOfMonth));
    }
    var day = DateTime(now.year, now.month, now.day);
    // At most a week and a day: a daily one comes today or tomorrow, a weekly
    // one on the next day that is its weekday.
    for (var step = 0; step < 8; step++) {
      final at = on(day);
      if (at.isAfter(now) &&
          (slot.weekday == null || at.weekday == slot.weekday)) {
        return at;
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return on(day);
  }

  /// A copy with the given changes.
  CustomReminder copyWith({
    String? title,
    String? note,
    ReminderRepeat? repeat,
    Set<int>? weekdays,
    int? dayOfMonth,
    List<int>? times,
    bool? enabled,
  }) => CustomReminder(
    id: id,
    title: title ?? this.title,
    note: note ?? this.note,
    repeat: repeat ?? this.repeat,
    weekdays: weekdays ?? this.weekdays,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    times: times ?? this.times,
    enabled: enabled ?? this.enabled,
  );

  /// Compact form for storage.
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    if (note.isNotEmpty) 'note': note,
    'repeat': repeat.name,
    if (repeat == ReminderRepeat.weekly) 'weekdays': weekdays.toList()..sort(),
    if (repeat == ReminderRepeat.monthly) 'day': dayOfMonth,
    'times': times,
    'on': enabled,
  };
}

/// Why a reminder cannot be saved yet.
enum ReminderProblem {
  /// It has no title.
  noTitle,

  /// It has no time of day.
  noTime,

  /// It has more times of the day than are allowed.
  tooManyTimes,

  /// A weekly reminder has no day chosen.
  noDay,

  /// Its times over its days come to more moments than are allowed.
  tooManyMoments,
}

/// Reads the saved reminders, skipping any that cannot be read.
List<CustomReminder> parseCustomReminders(Object? json) {
  if (json is! List<Object?>) return const [];
  final seen = <String>{};
  return [
    for (final entry in json)
      if (CustomReminder.tryFromJson(entry) case final reminder?)
        if (seen.add(reminder.id)) reminder,
  ].take(CustomReminder.maxReminders).toList();
}
