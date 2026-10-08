import 'package:meta/meta.dart';

import 'prayer_times.dart';

/// The prayer choices: the time alerts, the after-prayer adhkar reminder, and
/// how the times are worked out.
@immutable
class PrayerSettings {
  /// Creates the settings.
  const PrayerSettings({
    this.adhkarReminder = false,
    this.method,
    this.afterMinutes = 15,
    this.alerts = const {},
  });

  /// Reads settings saved by [toJson]. Anything unreadable gives the defaults.
  factory PrayerSettings.fromJson(Object? json) {
    if (json is! Map<String, Object?>) return const PrayerSettings();
    final after = json['after'];
    final alerts = json['alerts'];
    return PrayerSettings(
      adhkarReminder: json['on'] == true,
      method: PrayerMethod.tryParse(json['method']),
      afterMinutes: after is int && choices.contains(after) ? after : 15,
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

  /// Whether the after-prayer adhkar reminder is on.
  final bool adhkarReminder;

  /// The method the person chose, or null to follow the place.
  final PrayerMethod? method;

  /// Minutes after each prayer time for the adhkar reminder.
  final int afterMinutes;

  /// The prayers that alert at their time.
  final Set<DailyPrayer> alerts;

  /// Whether anything needs the prayer times scheduled.
  bool get needsSchedule => adhkarReminder || alerts.isNotEmpty;

  /// A copy with the given changes. [automaticMethod] clears [method].
  PrayerSettings copyWith({
    bool? adhkarReminder,
    PrayerMethod? method,
    bool automaticMethod = false,
    int? afterMinutes,
    Set<DailyPrayer>? alerts,
  }) => PrayerSettings(
    adhkarReminder: adhkarReminder ?? this.adhkarReminder,
    method: automaticMethod ? null : (method ?? this.method),
    afterMinutes: afterMinutes ?? this.afterMinutes,
    alerts: alerts ?? this.alerts,
  );

  /// Compact form for storage.
  Map<String, Object?> toJson() => {
    'on': adhkarReminder,
    'method': method?.name,
    'after': afterMinutes,
    'alerts': [for (final prayer in alerts) prayer.name],
  };
}

/// Why a notification is scheduled.
enum PrayerAlertKind {
  /// At the prayer time.
  atTime,

  /// A while after the prayer, to read the adhkar.
  afterPrayer,
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

  /// How many days ahead are scheduled. They are scheduled again every time the
  /// app opens, so a week is enough and stays far below the 64 pending
  /// notifications iOS keeps.
  static const int days = 7;

  static int get _perDay => DailyPrayer.values.length;

  /// Every id a plan can use, so they can all be cancelled before a new plan.
  static List<int> get allIds => [
    for (var i = 0; i < days * _perDay; i++) ...[
      firstAfterId + i,
      firstAtTimeId + i,
    ],
  ];

  /// The notifications after [now] at [place], by time.
  static List<PrayerAlert> compute({
    required PrayerPlace place,
    required PrayerSettings settings,
    required DateTime now,
  }) {
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
        if (settings.alerts.contains(prayer) && start.isAfter(now)) {
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
