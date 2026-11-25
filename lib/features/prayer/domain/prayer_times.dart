import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:meta/meta.dart';

import 'prayer_tuning.dart';

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

/// A place rounded to four decimal degrees, about eleven metres of latitude.
@immutable
class PrayerPlace {
  /// Creates a place, rounding to four decimals. [name] is what the place is
  /// called ("Cairo, Egypt"), when it is known. [altitude] is the height the
  /// phone's GPS gave, in metres above sea level, rounded to a metre.
  PrayerPlace(double latitude, double longitude, {this.name, double? altitude})
    : latitude = (latitude * 10000).roundToDouble() / 10000,
      longitude = (longitude * 10000).roundToDouble() / 10000,
      altitude = altitude != null && altitude.isFinite
          ? altitude.roundToDouble()
          : null;

  /// Reads a place saved by [toJson], or null.
  static PrayerPlace? tryFromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final lat = json['lat'];
    final lng = json['lng'];
    if (lat is! num || lng is! num) return null;
    if (!lat.isFinite ||
        !lng.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      return null;
    }
    final name = json['name'];
    final altitude = json['alt'];
    return PrayerPlace(
      lat.toDouble(),
      lng.toDouble(),
      name: name is String && name.trim().isNotEmpty ? name.trim() : null,
      altitude: altitude is num ? altitude.toDouble() : null,
    );
  }

  /// Degrees north.
  final double latitude;

  /// Degrees east.
  final double longitude;

  /// What the place is called, such as "Cairo, Egypt"; null when not known
  /// (offline, or the phone has no geocoder). It is not part of what makes two
  /// places the same: the same point with and without a name is one place.
  final String? name;

  /// Metres above sea level as the phone's GPS read them; null when it gave
  /// none (a place picked on the map has none). Like the name, it is not part
  /// of what makes two places the same.
  final double? altitude;

  /// The same place, called [name].
  PrayerPlace withName(String? name) =>
      PrayerPlace(latitude, longitude, name: name, altitude: altitude);

  /// The same place at [altitude] metres.
  PrayerPlace withAltitude(double? altitude) =>
      PrayerPlace(latitude, longitude, name: name, altitude: altitude);

  /// The distance to [other] in kilometres, along the surface.
  double distanceKm(PrayerPlace other) {
    double radians(double degrees) => degrees * math.pi / 180;
    final dLat = radians(other.latitude - latitude);
    final dLng = radians(other.longitude - longitude);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(radians(latitude)) *
            math.cos(radians(other.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 6371 * 2 * math.asin(math.sqrt(a));
  }

  /// Compact form for storage.
  Map<String, Object?> toJson() => {
    'lat': latitude,
    'lng': longitude,
    if (name != null) 'name': name,
    if (altitude != null) 'alt': altitude,
  };

  @override
  bool operator ==(Object other) =>
      other is PrayerPlace &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
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

  /// Reads a saved name, or null for anything else (automatic).
  static PrayerMethod? tryParse(Object? name) {
    for (final method in values) {
      if (method.name == name) return method;
    }
    return null;
  }

  /// The method most used where [place] is: the one a person there would
  /// expect, from a coarse map of regions. It is a starting point; the person
  /// can pick another. Smaller regions come first so they win over the larger
  /// ones around them.
  static PrayerMethod forPlace(PrayerPlace place) {
    final lat = place.latitude;
    final lng = place.longitude;
    for (final region in _regions) {
      if (lat >= region.south &&
          lat <= region.north &&
          lng >= region.west &&
          lng <= region.east) {
        return region.method;
      }
    }
    return muslimWorldLeague;
  }

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

class _Region {
  const _Region(this.south, this.north, this.west, this.east, this.method);

  final double south;
  final double north;
  final double west;
  final double east;
  final PrayerMethod method;
}

// Rough boxes, in the order they are tried.
const List<_Region> _regions = [
  _Region(28.5, 30.2, 46.5, 48.6, PrayerMethod.kuwait),
  _Region(24.4, 26.2, 50.7, 51.7, PrayerMethod.qatar),
  _Region(25.5, 26.4, 50.3, 50.8, PrayerMethod.ummAlQura), // Bahrain
  _Region(22.5, 26.2, 51.5, 56.5, PrayerMethod.dubai), // UAE and north Oman
  _Region(29.4, 37.4, 34.8, 42.2, PrayerMethod.egyptian), // Levant
  _Region(29.1, 37.4, 42.2, 48.6, PrayerMethod.egyptian), // Iraq
  _Region(12.0, 32.2, 34.5, 55.7, PrayerMethod.ummAlQura), // Arabia, Yemen
  _Region(22.0, 31.7, 24.7, 36.9, PrayerMethod.egyptian), // Egypt
  _Region(3.5, 22.0, 21.8, 38.6, PrayerMethod.egyptian), // Sudan
  _Region(19.5, 33.2, 9.3, 25.2, PrayerMethod.egyptian), // Libya
  _Region(35.8, 42.2, 25.6, 44.8, PrayerMethod.turkey),
  _Region(5.5, 37.1, 60.8, 92.7, PrayerMethod.karachi), // South Asia
  _Region(-11.2, 7.5, 95.0, 141.0, PrayerMethod.singapore), // Malay world
  _Region(15.0, 72.0, -168.0, -52.0, PrayerMethod.northAmerica),
];

/// The times of one day.
@immutable
class PrayerDay {
  /// Creates a day of times, all in local time.
  const PrayerDay({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  /// Works out the times at [place] on [date] with [method], moved as
  /// [tuning] says: the minutes added to each prayer, the height above sea
  /// level (which brings sunrise earlier and Maghrib later), and summer time.
  factory PrayerDay.compute(
    PrayerPlace place,
    PrayerMethod method,
    DateTime date, {
    PrayerTuning tuning = PrayerTuning.none,
  }) {
    final parameters = method._method.getParameters();
    final horizon = PrayerElevation.shift(place, date, tuning.elevation);
    parameters.adjustments
      ..fajr = tuning.offsetOf(DailyPrayer.fajr)
      ..sunrise = horizon.sunrise
      ..dhuhr = tuning.offsetOf(DailyPrayer.dhuhr)
      ..asr = tuning.offsetOf(DailyPrayer.asr)
      ..maghrib = tuning.offsetOf(DailyPrayer.maghrib) + horizon.sunset
      ..isha = tuning.offsetOf(DailyPrayer.isha);
    final times = PrayerTimes(
      Coordinates(place.latitude, place.longitude),
      DateComponents.from(date),
      parameters,
    );
    final summer = Duration(minutes: tuning.daylight.shiftOn(date));
    return PrayerDay(
      fajr: times.fajr.toLocal().add(summer),
      sunrise: times.sunrise.toLocal().add(summer),
      dhuhr: times.dhuhr.toLocal().add(summer),
      asr: times.asr.toLocal().add(summer),
      maghrib: times.maghrib.toLocal().add(summer),
      isha: times.isha.toLocal().add(summer),
    );
  }

  /// Dawn.
  final DateTime fajr;

  /// Sunrise: the end of Fajr, not a prayer.
  final DateTime sunrise;

  /// Midday.
  final DateTime dhuhr;

  /// Afternoon.
  final DateTime asr;

  /// Sunset.
  final DateTime maghrib;

  /// Night.
  final DateTime isha;

  /// The time of [prayer].
  DateTime of(DailyPrayer prayer) => switch (prayer) {
    DailyPrayer.fajr => fajr,
    DailyPrayer.dhuhr => dhuhr,
    DailyPrayer.asr => asr,
    DailyPrayer.maghrib => maghrib,
    DailyPrayer.isha => isha,
  };

  // Compared by value, so working it out again as the clock ticks rebuilds
  // nothing until the day changes.
  @override
  bool operator ==(Object other) =>
      other is PrayerDay &&
      other.fajr == fajr &&
      other.sunrise == sunrise &&
      other.dhuhr == dhuhr &&
      other.asr == asr &&
      other.maghrib == maghrib &&
      other.isha == isha;

  @override
  int get hashCode => Object.hash(fajr, sunrise, dhuhr, asr, maghrib, isha);
}

/// The prayer that comes next.
@immutable
class NextPrayer {
  /// Creates the value.
  const NextPrayer(this.prayer, this.at);

  /// Which prayer.
  final DailyPrayer prayer;

  /// When it begins.
  final DateTime at;

  // Compared by value, so working it out again as the clock ticks rebuilds
  // nothing until the next prayer changes.
  @override
  bool operator ==(Object other) =>
      other is NextPrayer && other.prayer == prayer && other.at == at;

  @override
  int get hashCode => Object.hash(prayer, at);
}

/// Finds the prayer after [now] at [place]: today's, or tomorrow's Fajr.
NextPrayer nextPrayer(
  PrayerPlace place,
  PrayerMethod method,
  DateTime now, {
  PrayerTuning tuning = PrayerTuning.none,
}) {
  final today = PrayerDay.compute(place, method, now, tuning: tuning);
  for (final prayer in DailyPrayer.values) {
    if (today.of(prayer).isAfter(now)) {
      return NextPrayer(prayer, today.of(prayer));
    }
  }
  final tomorrow = PrayerDay.compute(
    place,
    method,
    DateTime(now.year, now.month, now.day + 1),
    tuning: tuning,
  );
  return NextPrayer(DailyPrayer.fajr, tomorrow.fajr);
}

/// The moments of the day the app works out besides the five prayers, for
/// the hour the person is in: sunrise, while Fajr's time runs, and the middle
/// of the night and the start of its last third, from Maghrib to Fajr.
@immutable
class DayMarks {
  /// Creates the marks.
  const DayMarks({this.sunrise, this.midnight, this.lastThird});

  /// When Fajr's time ends, while it runs; null otherwise.
  final DateTime? sunrise;

  /// The middle of the night (between Maghrib and Fajr), while the night
  /// runs; null otherwise.
  final DateTime? midnight;

  /// The start of the night's last third, while the night runs; null
  /// otherwise.
  final DateTime? lastThird;

  /// Whether there is nothing to show.
  bool get isEmpty => sunrise == null && midnight == null && lastThird == null;

  /// The marks at [place] at [now]: the night is Maghrib to the next Fajr,
  /// yesterday's when [now] is before today's Fajr.
  static DayMarks at(
    PrayerPlace place,
    PrayerMethod method,
    DateTime now, {
    PrayerTuning tuning = PrayerTuning.none,
  }) {
    PrayerDay day(int offset) => PrayerDay.compute(
      place,
      method,
      DateTime(now.year, now.month, now.day + offset),
      tuning: tuning,
    );
    final today = day(0);
    if (!now.isBefore(today.fajr) && now.isBefore(today.sunrise)) {
      return DayMarks(sunrise: today.sunrise);
    }
    final (DateTime, DateTime)? night = now.isBefore(today.fajr)
        ? (day(-1).maghrib, today.fajr)
        : !now.isBefore(today.maghrib)
        ? (today.maghrib, day(1).fajr)
        : null;
    if (night == null) return const DayMarks();
    final (start, end) = night;
    final length = end.difference(start);
    return DayMarks(
      midnight: start.add(length ~/ 2),
      lastThird: start.add(length * 2 ~/ 3),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DayMarks &&
      other.sunrise == sunrise &&
      other.midnight == midnight &&
      other.lastThird == lastThird;

  @override
  int get hashCode => Object.hash(sunrise, midnight, lastThird);
}
