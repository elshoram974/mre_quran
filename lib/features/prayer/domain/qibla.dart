import 'dart:math' as math;

import 'package:adhan/adhan.dart';

import 'prayer_times.dart';

/// The direction of the Qibla at [place], in degrees clockwise from true north
/// (0 to 360), along the shortest path to the Kaaba.
double qiblaBearing(PrayerPlace place) =>
    Qibla(Coordinates(place.latitude, place.longitude)).direction % 360;

/// The eight compass points.
enum CompassPoint {
  /// 0°.
  north,

  /// 45°.
  northEast,

  /// 90°.
  east,

  /// 135°.
  southEast,

  /// 180°.
  south,

  /// 225°.
  southWest,

  /// 270°.
  west,

  /// 315°.
  northWest;

  /// The point nearest to [degrees].
  static CompassPoint of(double degrees) =>
      values[((degrees % 360) / 45).round() % 8];
}

/// How far [from] is from [to] on a circle, in degrees, signed: positive when
/// [to] is clockwise of [from]. Always between -180 and 180.
double angleBetween(double from, double to) {
  final turn = (to - from) % 360;
  return turn > 180 ? turn - 360 : turn;
}

/// Works out which way a phone held flat points, from its gravity and
/// magnetic-field readings, and smooths the jitter.
///
/// Readings are in the phone's own axes: x to the right, y toward the top, z
/// out of the screen, as Android and `sensors_plus` report them.
class HeadingFilter {
  /// Creates a filter. A lower [smoothing] (0 to 1) steadies the needle more
  /// and makes it slower to follow.
  HeadingFilter({this.smoothing = 0.15});

  /// Share of each new reading that is taken in.
  final double smoothing;

  double? _heading;

  /// The smoothed heading in degrees clockwise from magnetic north, or null
  /// before the first reading.
  double? get heading => _heading;

  /// Takes a reading: gravity (`ax`, `ay`, `az`) and the magnetic field (`mx`,
  /// `my`, `mz`). Returns the new heading, or null when the readings cannot
  /// give one (in free fall, or no field).
  double? add(
    double ax,
    double ay,
    double az,
    double mx,
    double my,
    double mz,
  ) {
    // east = magnetic field x gravity; the heading is where the top of the
    // phone points relative to north (the same maths as Android's
    // SensorManager.getRotationMatrix).
    var hx = my * az - mz * ay;
    var hy = mz * ax - mx * az;
    var hz = mx * ay - my * ax;
    final east = math.sqrt(hx * hx + hy * hy + hz * hz);
    final gravity = math.sqrt(ax * ax + ay * ay + az * az);
    if (east < 0.1 || gravity < 0.1) return null;
    hx /= east;
    hy /= east;
    hz /= east;
    final gx = ax / gravity;
    final gz = az / gravity;
    // north = gravity x east
    final ny = gz * hx - gx * hz;
    final next = (math.atan2(hy, ny) * 180 / math.pi + 360) % 360;
    final current = _heading;
    _heading = current == null
        ? next
        : (current + angleBetween(current, next) * smoothing + 360) % 360;
    return _heading;
  }
}
