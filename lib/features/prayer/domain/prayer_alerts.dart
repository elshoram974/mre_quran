import 'package:adhan/adhan.dart';
import 'package:meta/meta.dart';

/// The five daily prayers.
enum DailyPrayer {
  /// Dawn prayer.
  fajr,

  /// Midday prayer.
  dhuhr,

  /// Afternoon prayer.
  asr,

  /// Sunset prayer.
  maghrib,

  /// Night prayer.
  isha,
}

/// How prayer times are worked out. Each one is a published method.
enum PrayerMethod {
  /// Egyptian General Authority of Survey.
  egyptian,

  /// Muslim World League.
  muslimWorldLeague,

  /// Umm al-Qura University, Makkah.
  ummAlQura,

  /// University of Islamic Sciences, Karachi.
  karachi,

  /// Islamic Society of North America.
  northAmerica,

  /// Dubai.
  dubai,

  /// Kuwait.
  kuwait,

  /// Qatar.
  qatar,

  /// Turkey's Diyanet.
  turkey,

  /// Singapore.
  singapore;

  /// Reads a saved name, falling back to [egyptian].
  static PrayerMethod parse(Object? name) => PrayerMethod.values.firstWhere(
    (method) => method.name == name,
    orElse: () => egyptian,
  );

  CalculationMethod get _method => switch (this) {
    egyptian => CalculationMethod.egyptian,
    muslimWorldLeague => CalculationMethod.muslim_world_league,
    ummAlQura => CalculationMethod.umm_al_qura,
    karachi => CalculationMethod.karachi,
    northAmerica => CalculationMethod.north_america,
    dubai => CalculationMethod.dubai,
    kuwait => CalculationMethod.kuwait,
    qatar => CalculationMethod.qatar,
    turkey => CalculationMethod.turkey,
    singapore => CalculationMethod.singapore,
  };
}

/// A rounded place, enough for prayer times and never more precise than
/// about a kilometre.
@immutable
class PrayerPlace {
  /// Creates a place, rounding to two decimals.
  PrayerPlace(double latitude, double longitude)
    : latitude = (latitude * 100).roundToDouble() / 100,
      longitude = (longitude * 100).roundToDouble() / 100;

  /// Reads a place saved by [toJson], or null.
  static PrayerPlace? tryFromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final lat = json['lat'];
    final lng = json['lng'];
    if (lat is! num || lng is! num) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return PrayerPlace(lat.toDouble(), lng.toDouble());
  }

  /// Degrees north.
  final double latitude;

  /// Degrees east.
  final double longitude;

  /// Compact form for storage.
  Map<String, Object?> toJson() => {'lat': latitude, 'lng': longitude};
}

/// The after-prayer reminder choices.
@immutable
class PrayerReminderSettings {
  /// Creates the settings.
  const PrayerReminderSettings({
    this.enabled = false,
    this.method = PrayerMethod.egyptian,
    this.afterMinutes = 15,
  });

  /// Reads settings saved by [toJson]. Anything unreadable gives the defaults.
  factory PrayerReminderSettings.fromJson(Object? json) {
    if (json is! Map<String, Object?>) return const PrayerReminderSettings();
    final after = json['after'];
    return PrayerReminderSettings(
      enabled: json['on'] == true,
      method: PrayerMethod.parse(json['method']),
      afterMinutes: after is int && choices.contains(after) ? after : 15,
    );
  }

  /// Minutes after the prayer time a reminder may come.
  static const List<int> choices = [10, 15, 20, 30];

  /// Whether the reminders are on.
  final bool enabled;

  /// How the times are worked out.
  final PrayerMethod method;

  /// Minutes after each prayer time.
  final int afterMinutes;

  /// A copy with the given changes.
  PrayerReminderSettings copyWith({
    bool? enabled,
    PrayerMethod? method,
    int? afterMinutes,
  }) => PrayerReminderSettings(
    enabled: enabled ?? this.enabled,
    method: method ?? this.method,
    afterMinutes: afterMinutes ?? this.afterMinutes,
  );

  /// Compact form for storage.
  Map<String, Object?> toJson() => {
    'on': enabled,
    'method': method.name,
    'after': afterMinutes,
  };
}

/// One reminder to schedule.
@immutable
class PrayerReminder {
  /// Creates a reminder for [prayer], [at] a local time.
  const PrayerReminder({
    required this.id,
    required this.prayer,
    required this.at,
  });

  /// Stable notification id.
  final int id;

  /// The prayer it follows.
  final DailyPrayer prayer;

  /// When to show it, in local time.
  final DateTime at;
}

/// Works out the reminders for the coming days.
abstract final class PrayerReminderPlan {
  /// First notification id used by prayer reminders; the ids that follow, up to
  /// [days] times five, belong to them.
  static const int firstId = 7000000;

  /// How many days ahead are scheduled. Reminders are scheduled again every
  /// time the app opens, so a week is enough and stays far below the 64
  /// pending notifications iOS keeps.
  static const int days = 7;

  /// Every id a plan can use, so they can all be cancelled before a new plan.
  static List<int> get allIds => [
    for (var i = 0; i < days * DailyPrayer.values.length; i++) firstId + i,
  ];

  /// The reminders after [now] for [place], one per prayer per day.
  static List<PrayerReminder> compute({
    required PrayerPlace place,
    required PrayerReminderSettings settings,
    required DateTime now,
  }) {
    final parameters = settings.method._method.getParameters();
    final reminders = <PrayerReminder>[];
    for (var day = 0; day < days; day++) {
      final date = DateTime(now.year, now.month, now.day + day);
      final times = PrayerTimes(
        Coordinates(place.latitude, place.longitude),
        DateComponents.from(date),
        parameters,
      );
      final byPrayer = {
        DailyPrayer.fajr: times.fajr,
        DailyPrayer.dhuhr: times.dhuhr,
        DailyPrayer.asr: times.asr,
        DailyPrayer.maghrib: times.maghrib,
        DailyPrayer.isha: times.isha,
      };
      for (final entry in byPrayer.entries) {
        final at = entry.value.toLocal().add(
          Duration(minutes: settings.afterMinutes),
        );
        if (at.isAfter(now)) {
          reminders.add(
            PrayerReminder(
              id: firstId + day * DailyPrayer.values.length + entry.key.index,
              prayer: entry.key,
              at: at,
            ),
          );
        }
      }
    }
    return reminders;
  }
}
