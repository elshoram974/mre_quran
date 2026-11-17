import 'package:meta/meta.dart';

import 'prayer_times.dart';

/// The prayer choices: the time alerts, the reminder before them, the
/// after-prayer adhkar reminder, and how the times are worked out.
@immutable
class PrayerSettings {
  /// Creates the settings.
  const PrayerSettings({
    this.adhkarReminder = false,
    this.method,
    this.afterMinutes = 15,
    this.alerts = const {},
    this.beforeReminder = true,
    this.beforeMinutes = 15,
  });

  /// Reads settings saved by [toJson]. Anything unreadable gives the defaults.
  factory PrayerSettings.fromJson(Object? json) {
    if (json is! Map<String, Object?>) return const PrayerSettings();
    final after = json['after'];
    final alerts = json['alerts'];
    final before = json['before'];
    return PrayerSettings(
      adhkarReminder: json['on'] == true,
      method: PrayerMethod.tryParse(json['method']),
      afterMinutes: after is int && choices.contains(after) ? after : 15,
      beforeReminder: json['beforeOn'] != false,
      beforeMinutes: before is int && beforeChoices.contains(before)
          ? before
          : 15,
      alerts: {
        if (alerts is List<Object?>)
          for (final name in alerts)
            for (final prayer in DailyPrayer.values)
              if (prayer.name == name) prayer,
      },
    );
  }

  /// Minutes after the prayer time an adhkar reminder may come.
  static const List<int> choices = [10, 15, 20, 30];

  /// Minutes before the prayer time its reminder may come.
  static const List<int> beforeChoices = [5, 10, 15, 20, 30, 45];

  /// Whether the after-prayer adhkar reminder is on.
  final bool adhkarReminder;

  /// The method the person chose, or null to follow the place.
  final PrayerMethod? method;

  /// Minutes after each prayer time for the adhkar reminder.
  final int afterMinutes;

  /// The prayers that alert at their time.
  final Set<DailyPrayer> alerts;

  /// Whether a reminder comes a while before each prayer that alerts:
  /// "اقتربت صلاة الظهر".
  final bool beforeReminder;

  /// Minutes before the prayer time for that reminder.
  final int beforeMinutes;

  /// Whether anything needs the prayer times scheduled.
  bool get needsSchedule => adhkarReminder || alerts.isNotEmpty;

  /// A copy with the given changes. [automaticMethod] clears [method].
  PrayerSettings copyWith({
    bool? adhkarReminder,
    PrayerMethod? method,
    bool automaticMethod = false,
    int? afterMinutes,
    Set<DailyPrayer>? alerts,
    bool? beforeReminder,
    int? beforeMinutes,
  }) => PrayerSettings(
    adhkarReminder: adhkarReminder ?? this.adhkarReminder,
    method: automaticMethod ? null : (method ?? this.method),
    afterMinutes: afterMinutes ?? this.afterMinutes,
    alerts: alerts ?? this.alerts,
    beforeReminder: beforeReminder ?? this.beforeReminder,
    beforeMinutes: beforeMinutes ?? this.beforeMinutes,
  );

  /// Compact form for storage.
  Map<String, Object?> toJson() => {
    'on': adhkarReminder,
    'method': method?.name,
    'after': afterMinutes,
    'alerts': [for (final prayer in alerts) prayer.name],
    'beforeOn': beforeReminder,
    'before': beforeMinutes,
  };
}

/// Why a notification is scheduled.
enum PrayerAlertKind {
  /// At the prayer time.
  atTime,

  /// A while after the prayer, to read the adhkar.
  afterPrayer,

  /// A while before the prayer, so the person can get ready.
  beforePrayer,
}

/// One notification to schedule.
@immutable
class PrayerAlert {
  /// Creates an alert.
  const PrayerAlert({
    required this.id,
    required this.kind,
    required this.prayer,
    required this.at,
  });

  /// Stable notification id.
  final int id;

  /// Why it is scheduled.
  final PrayerAlertKind kind;

  /// The prayer it belongs to.
  final DailyPrayer prayer;

  /// When to show it, in local time.
  final DateTime at;
}

/// Works out the notifications for the coming days.
abstract final class PrayerAlertPlan {
  /// First id of the after-prayer adhkar reminders.
  static const int firstAfterId = 7000000;

  /// First id of the alerts at the prayer time.
  static const int firstAtTimeId = 7001000;

  /// First id of the reminders before the prayer time.
  static const int firstBeforeId = 7002000;

  /// The most days a plan covers. Each day takes one id of each kind per
  /// prayer, so ids stay below the next kind's first.
  static const int maxDays = 31;

  static int get _perDay => DailyPrayer.values.length;

  /// Whether [id] belongs to a prayer plan, of any kind.
  static bool owns(int id) =>
      (id >= firstAfterId && id < firstAfterId + maxDays * _perDay) ||
      (id >= firstAtTimeId && id < firstAtTimeId + maxDays * _perDay) ||
      (id >= firstBeforeId && id < firstBeforeId + maxDays * _perDay);

  /// The notifications after [now] at [place], by time, for [days] days.
  static List<PrayerAlert> compute({
    required PrayerPlace place,
    required PrayerSettings settings,
    required DateTime now,
    int days = 7,
  }) {
    assert(days >= 1 && days <= maxDays);
    final method = settings.method ?? PrayerMethod.forPlace(place);
    final alerts = <PrayerAlert>[];
    for (var day = 0; day < days; day++) {
      final times = PrayerDay.compute(
        place,
        method,
        DateTime(now.year, now.month, now.day + day),
      );
      for (final prayer in DailyPrayer.values) {
        final slot = day * _perDay + prayer.index;
        final start = times.of(prayer);
        final alerting = settings.alerts.contains(prayer);
        final before = start.subtract(
          Duration(minutes: settings.beforeMinutes),
        );
        if (alerting && settings.beforeReminder && before.isAfter(now)) {
          alerts.add(
            PrayerAlert(
              id: firstBeforeId + slot,
              kind: PrayerAlertKind.beforePrayer,
              prayer: prayer,
              at: before,
            ),
          );
        }
        if (alerting && start.isAfter(now)) {
          alerts.add(
            PrayerAlert(
              id: firstAtTimeId + slot,
              kind: PrayerAlertKind.atTime,
              prayer: prayer,
              at: start,
            ),
          );
        }
        final after = start.add(Duration(minutes: settings.afterMinutes));
        if (settings.adhkarReminder && after.isAfter(now)) {
          alerts.add(
            PrayerAlert(
              id: firstAfterId + slot,
              kind: PrayerAlertKind.afterPrayer,
              prayer: prayer,
              at: after,
            ),
          );
        }
      }
    }
    alerts.sort((a, b) => a.at.compareTo(b.at));
    return alerts;
  }
}
