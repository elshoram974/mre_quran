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

  /// Works out the times at [place] on [date] with [method].
  factory PrayerDay.compute(
    PrayerPlace place,
    PrayerMethod method,
    DateTime date,
  ) {
    final times = PrayerTimes(
      Coordinates(place.latitude, place.longitude),
      DateComponents.from(date),
      method._method.getParameters(),
    );
    return PrayerDay(
      fajr: times.fajr.toLocal(),
      sunrise: times.sunrise.toLocal(),
      dhuhr: times.dhuhr.toLocal(),
      asr: times.asr.toLocal(),
      maghrib: times.maghrib.toLocal(),
      isha: times.isha.toLocal(),
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
}

/// Finds the prayer after [now] at [place]: today's, or tomorrow's Fajr.
NextPrayer nextPrayer(PrayerPlace place, PrayerMethod method, DateTime now) {
  final today = PrayerDay.compute(place, method, now);
  for (final prayer in DailyPrayer.values) {
    if (today.of(prayer).isAfter(now)) {
      return NextPrayer(prayer, today.of(prayer));
    }
  }
  final tomorrow = PrayerDay.compute(
    place,
    method,
    DateTime(now.year, now.month, now.day + 1),
  );
  return NextPrayer(DailyPrayer.fajr, tomorrow.fajr);
}
