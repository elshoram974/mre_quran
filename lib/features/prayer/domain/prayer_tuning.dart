import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'prayer_times.dart';

/// What the person says about summer time (daylight saving).
///
/// The times are shown on the phone's clock, which follows its own time zone.
/// The app has no map of time zones, so it cannot tell by itself when the
/// phone's clock is wrong for the place; the person says so here.
enum DaylightSaving {
  /// The phone's clock is right.
  automatic,

  /// The place is on summer time, whatever the phone says.
  summer,

  /// The place is on standard (winter) time, whatever the phone says.
  winter;

  /// Reads a saved name, or [automatic] for anything else.
  static DaylightSaving parse(Object? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return automatic;
  }

  /// The minutes to add to the times so they read as the person said, when
  /// the phone's clock is [deviceOnSummer]: nothing when it already agrees.
  int shift({required bool deviceOnSummer}) => switch (this) {
    automatic => 0,
    summer => deviceOnSummer ? 0 : 60,
    winter => deviceOnSummer ? -60 : 0,
  };

  /// [shift] for the times of [date], by the phone's own time zone.
  int shiftOn(DateTime date) {
    if (this == automatic) return 0;
    final noon = DateTime(date.year, date.month, date.day, 12);
    return shift(deviceOnSummer: deviceOnSummerTime(noon));
  }

  /// Whether the phone's clock is on summer time at [moment]: its offset from
  /// UTC is more than the smaller of its January and July offsets, which is
  /// its standard offset (in either hemisphere).
  static bool deviceOnSummerTime(DateTime moment) {
    final january = DateTime(moment.year, 1, 1, 12).timeZoneOffset;
    final july = DateTime(moment.year, 7, 1, 12).timeZoneOffset;
    final standard = january < july ? january : july;
    return moment.timeZoneOffset > standard;
  }
}

/// How the person moved the prayer times away from the calculation: some
/// minutes for each prayer, summer time, and the height above sea level.
@immutable
class PrayerTuning {
  /// Creates the tuning.
  const PrayerTuning({
    this.offsets = const {},
    this.daylight = DaylightSaving.automatic,
    this.elevation = 0,
  });

  /// No change.
  static const PrayerTuning none = PrayerTuning();

  /// The most minutes a prayer may be moved, either way.
  static const int maxOffset = 30;

  /// The highest place the app corrects for, in metres.
  static const int maxElevation = 9000;

  /// Minutes added to a prayer's time (negative to bring it forward).
  final Map<DailyPrayer, int> offsets;

  /// What the person says about summer time.
  final DaylightSaving daylight;

  /// Metres above sea level, 0 to [maxElevation].
  final int elevation;

  /// The minutes added to [prayer].
  int offsetOf(DailyPrayer prayer) => offsets[prayer] ?? 0;

  /// Whether this changes nothing.
  bool get isNone =>
      daylight == DaylightSaving.automatic &&
      elevation == 0 &&
      offsets.values.every((minutes) => minutes == 0);

  @override
  bool operator ==(Object other) =>
      other is PrayerTuning &&
      other.daylight == daylight &&
      other.elevation == elevation &&
      DailyPrayer.values.every(
        (prayer) => other.offsetOf(prayer) == offsetOf(prayer),
      );

  @override
  int get hashCode => Object.hash(
    daylight,
    elevation,
    Object.hashAll([for (final prayer in DailyPrayer.values) offsetOf(prayer)]),
  );
}

/// The effect of height above sea level on sunrise and sunset.
///
/// From higher up the horizon lies lower, so the sun is seen to rise earlier
/// and set later. The correction is the one the PrayTimes calculator uses: the
/// horizon dips by `0.0347° × √metres` below the usual `0.833°`. Fajr, Dhuhr,
/// Asr and Isha do not depend on the horizon, so they are not moved; Maghrib
/// follows the sunset.
abstract final class PrayerElevation {
  /// The usual altitude of the sun's centre at sunrise and sunset, in degrees.
  static const double _horizon = -0.833;

  /// The minutes sunrise comes earlier ([sunrise], negative) and sunset
  /// later ([sunset], positive) for someone [metres] above sea level at
  /// [place] on [date]. Both are zero at sea level, and where the sun does
  /// not rise or set.
  static ({int sunrise, int sunset}) shift(
    PrayerPlace place,
    DateTime date,
    int metres,
  ) {
    final height = metres.clamp(0, PrayerTuning.maxElevation);
    if (height == 0) return (sunrise: 0, sunset: 0);
    final dip = 0.0347 * math.sqrt(height);
    final level = _hourAngle(place.latitude, date, _horizon);
    final raised = _hourAngle(place.latitude, date, _horizon - dip);
    if (level.isNaN || raised.isNaN) return (sunrise: 0, sunset: 0);
    // Fifteen degrees of hour angle are an hour: four minutes a degree.
    final minutes = ((raised - level) * 4).round();
    return (sunrise: -minutes, sunset: minutes);
  }

  /// The sun's hour angle, in degrees, when it is [altitude] degrees above
  /// the horizon at [latitude] on [date]; NaN when it never is.
  static double _hourAngle(double latitude, DateTime date, double altitude) {
    final day = date.difference(DateTime(date.year)).inDays + 1;
    // Cooper's approximation of the sun's declination: good to half a degree,
    // which moves the result by far less than a minute.
    final declination =
        _radians(23.45) * math.sin(_radians(360 / 365 * (284 + day)));
    final phi = _radians(latitude);
    final cosine =
        (math.sin(_radians(altitude)) - math.sin(phi) * math.sin(declination)) /
        (math.cos(phi) * math.cos(declination));
    if (cosine < -1 || cosine > 1) return double.nan;
    return math.acos(cosine) * 180 / math.pi;
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
