import 'package:meta/meta.dart';

import 'prayer_times.dart';
import 'prayer_tuning.dart';

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
    this.beforeCountdown = true,
    this.automaticLocation = true,
    this.offsets = const {},
    this.daylight = DaylightSaving.automatic,
    this.elevation,
    this.hijriShift = 0,
    this.beforeSound = true,
    this.iqamaReminder = false,
    this.iqamaMinutes = const {},
    this.iqamaSound = true,
  });

  /// Reads settings saved by [toJson]. Anything unreadable gives the defaults.
  factory PrayerSettings.fromJson(Object? json) {
    if (json is! Map<String, Object?>) return const PrayerSettings();
    final after = json['after'];
    final alerts = json['alerts'];
    final before = json['before'];
    final offsets = json['offsets'];
    final elevation = json['elevation'];
    final hijriShift = json['hijriShift'];
    final iqama = json['iqamaMinutes'];
    return PrayerSettings(
      adhkarReminder: json['on'] == true,
      method: PrayerMethod.tryParse(json['method']),
      afterMinutes: after is int && choices.contains(after) ? after : 15,
      beforeReminder: json['beforeOn'] != false,
      beforeMinutes: before is int && beforeChoices.contains(before)
          ? before
          : 15,
      beforeCountdown: json['beforeCountdown'] != false,
      // Older settings did not record how the place was chosen. Preserve the
      // saved place until the person explicitly chooses device location again.
      automaticLocation: json['automaticLocation'] == true,
      offsets: {
        if (offsets is Map<String, Object?>)
          for (final prayer in DailyPrayer.values)
            if (offsets[prayer.name] case final int minutes
                when minutes != 0 && minutes.abs() <= PrayerTuning.maxOffset)
              prayer: minutes,
      },
      daylight: DaylightSaving.parse(json['daylight']),
      elevation:
          elevation is int &&
              elevation >= 0 &&
              elevation <= PrayerTuning.maxElevation
          ? elevation
          : null,
      hijriShift: hijriShift is int && hijriShift.abs() <= maxHijriShift
          ? hijriShift
          : 0,
      beforeSound: json['beforeSound'] != false,
      iqamaReminder: json['iqama'] == true,
      iqamaSound: json['iqamaSound'] != false,
      iqamaMinutes: {
        if (iqama is Map<String, Object?>)
          for (final prayer in DailyPrayer.values)
            if (iqama[prayer.name] case final int minutes
                when minutes >= minIqama &&
                    minutes <= maxIqama &&
                    minutes != defaultIqamaMinutes[prayer])
              prayer: minutes,
      },
      alerts: {
        if (alerts is List<Object?>)
          for (final name in alerts)
            for (final prayer in DailyPrayer.values)
              if (prayer.name == name) prayer,
      },
    );
  }

  /// The most days the Hijri date may be moved, either way.
  static const int maxHijriShift = 2;

  /// The fewest and most minutes after the adhan the iqama may be put.
  static const int minIqama = 5;

  /// The most minutes after the adhan the iqama may be put.
  static const int maxIqama = 60;

  /// How long after the adhan the iqama comes, until the person says: the
  /// usual gap in mosques, longer at Fajr and shorter at Maghrib.
  static const Map<DailyPrayer, int> defaultIqamaMinutes = {
    DailyPrayer.fajr: 20,
    DailyPrayer.dhuhr: 15,
    DailyPrayer.asr: 15,
    DailyPrayer.maghrib: 10,
    DailyPrayer.isha: 15,
  };

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

  /// Whether that reminder counts down to the adhan, to the second, and
  /// stays until it, with a button to take it away (Android).
  final bool beforeCountdown;

  /// Whether a previously granted device location may refresh the place.
  final bool automaticLocation;

  /// Whether the reminder before a prayer makes its sound.
  final bool beforeSound;

  /// Whether a notice comes when the iqama does, for each of the five prayers:
  /// «قد قامت الصلاة».
  final bool iqamaReminder;

  /// The minutes after the adhan the person chose for a prayer's iqama; a
  /// prayer not here keeps its [defaultIqamaMinutes].
  final Map<DailyPrayer, int> iqamaMinutes;

  /// Whether the iqama's notice makes its sound.
  final bool iqamaSound;

  /// Minutes after [prayer]'s adhan the iqama comes.
  int iqamaAfter(DailyPrayer prayer) =>
      iqamaMinutes[prayer] ?? defaultIqamaMinutes[prayer]!;

  /// Minutes the person added to a prayer's time, up to
  /// [PrayerTuning.maxOffset] either way; a prayer not here is not moved.
  final Map<DailyPrayer, int> offsets;

  /// What the person says about summer time.
  final DaylightSaving daylight;

  /// Metres above sea level the person typed, or null to use what the phone's
  /// GPS read for the place.
  final int? elevation;

  /// Days the person moved the Hijri date, because the calendar's tables can
  /// differ from the moon sighting where they are: -2 to 2.
  final int hijriShift;

  /// The height used at [place]: the person's own, else the GPS's, else sea
  /// level.
  int elevationAt(PrayerPlace place) =>
      (elevation ?? place.altitude?.round() ?? 0).clamp(
        0,
        PrayerTuning.maxElevation,
      );

  /// How the times at [place] are moved from the calculation.
  PrayerTuning tuningAt(PrayerPlace place) => PrayerTuning(
    offsets: offsets,
    daylight: daylight,
    elevation: elevationAt(place),
  );

  /// Whether anything needs the prayer times scheduled.
  bool get needsSchedule =>
      adhkarReminder || iqamaReminder || alerts.isNotEmpty;

  /// A copy with the given changes. [automaticMethod] clears [method].
  PrayerSettings copyWith({
    bool? adhkarReminder,
    PrayerMethod? method,
    bool automaticMethod = false,
    int? afterMinutes,
    Set<DailyPrayer>? alerts,
    bool? beforeReminder,
    int? beforeMinutes,
    bool? beforeCountdown,
    bool? automaticLocation,
    Map<DailyPrayer, int>? offsets,
    DaylightSaving? daylight,
    int? elevation,
    bool automaticElevation = false,
    int? hijriShift,
    bool? beforeSound,
    bool? iqamaReminder,
    Map<DailyPrayer, int>? iqamaMinutes,
    bool? iqamaSound,
  }) => PrayerSettings(
    adhkarReminder: adhkarReminder ?? this.adhkarReminder,
    method: automaticMethod ? null : (method ?? this.method),
    afterMinutes: afterMinutes ?? this.afterMinutes,
    alerts: alerts ?? this.alerts,
    beforeReminder: beforeReminder ?? this.beforeReminder,
    beforeMinutes: beforeMinutes ?? this.beforeMinutes,
    beforeCountdown: beforeCountdown ?? this.beforeCountdown,
    automaticLocation: automaticLocation ?? this.automaticLocation,
    offsets: offsets ?? this.offsets,
    daylight: daylight ?? this.daylight,
    elevation: automaticElevation ? null : (elevation ?? this.elevation),
    hijriShift: hijriShift ?? this.hijriShift,
    beforeSound: beforeSound ?? this.beforeSound,
    iqamaReminder: iqamaReminder ?? this.iqamaReminder,
    iqamaMinutes: iqamaMinutes ?? this.iqamaMinutes,
    iqamaSound: iqamaSound ?? this.iqamaSound,
  );

  /// Compact form for storage.
  Map<String, Object?> toJson() => {
    'on': adhkarReminder,
    'method': method?.name,
    'after': afterMinutes,
    'alerts': [for (final prayer in alerts) prayer.name],
    'beforeOn': beforeReminder,
    'before': beforeMinutes,
    'beforeCountdown': beforeCountdown,
    'automaticLocation': automaticLocation,
    'offsets': {
      for (final MapEntry(:key, :value) in offsets.entries)
        if (value != 0) key.name: value,
    },
    'daylight': daylight.name,
    'elevation': ?elevation,
    'hijriShift': hijriShift,
    'beforeSound': beforeSound,
    'iqama': iqamaReminder,
    'iqamaSound': iqamaSound,
    'iqamaMinutes': {
      for (final MapEntry(:key, :value) in iqamaMinutes.entries)
        key.name: value,
    },
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

  /// When the iqama comes, a set time after the adhan.
  iqama,
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

  /// First id of the notices at the iqama. The fasting reminders' ids end below
  /// it.
  static const int firstIqamaId = 7004000;

  /// The most days a plan covers. Each day takes one id of each kind per
  /// prayer, so ids stay below the next kind's first.
  static const int maxDays = 31;

  static int get _perDay => DailyPrayer.values.length;

  /// Whether [id] belongs to a prayer plan, of any kind.
  static bool owns(int id) =>
      (id >= firstAfterId && id < firstAfterId + maxDays * _perDay) ||
      (id >= firstAtTimeId && id < firstAtTimeId + maxDays * _perDay) ||
      (id >= firstBeforeId && id < firstBeforeId + maxDays * _perDay) ||
      (id >= firstIqamaId && id < firstIqamaId + maxDays * _perDay);

  /// The notifications after [now] at [place], by time, for [days] days.
  static List<PrayerAlert> compute({
    required PrayerPlace place,
    required PrayerSettings settings,
    required DateTime now,
    int days = 7,
  }) {
    assert(days >= 1 && days <= maxDays);
    final method = settings.method ?? PrayerMethod.forPlace(place);
    final tuning = settings.tuningAt(place);
    final alerts = <PrayerAlert>[];
    for (var day = 0; day < days; day++) {
      final times = PrayerDay.compute(
        place,
        method,
        DateTime(now.year, now.month, now.day + day),
        tuning: tuning,
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
        final iqama = start.add(Duration(minutes: settings.iqamaAfter(prayer)));
        if (settings.iqamaReminder && iqama.isAfter(now)) {
          alerts.add(
            PrayerAlert(
              id: firstIqamaId + slot,
              kind: PrayerAlertKind.iqama,
              prayer: prayer,
              at: iqama,
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
