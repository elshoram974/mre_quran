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

  /// Takes a magnetic-field reading (`mx`, `my`, `mz`) with the gravity
  /// [tilts] has steadied, which is how the compass feeds it. Returns the new
  /// heading, or null when there is none to give ([add]), or no gravity yet.
  ///
  /// The accelerometer feels the hand as well as the Earth, and a gravity
  /// that is a little off turns the heading by more the steeper the Earth's
  /// field dips: twice as much in London as in Cairo, five times in the far
  /// north. Steadied, the hand's shaking is mostly gone from it.
  double? addWith(TiltFilter tilts, double mx, double my, double mz) {
    final gravity = tilts.gravity;
    if (gravity == null) return null;
    return add(gravity.x, gravity.y, gravity.z, mx, my, mz);
  }
}

/// How far from lying flat, in degrees, a phone may be and still count as
/// level: within it the compass can be trusted to point where the dial shows.
const double levelTolerance = 10;

/// How a phone is held, worked out from gravity alone.
class PhoneTilt {
  /// Creates a tilt.
  const PhoneTilt({
    required this.angle,
    required this.dx,
    required this.dy,
    required this.level,
  });

  /// Degrees away from lying flat with the screen up: 0 flat, 90 upright,
  /// 180 face down.
  final double angle;

  /// How far a spirit level's bubble is pushed toward the right edge of the
  /// screen, as a share of a full tilt (-1 to 1). A bubble floats to the
  /// raised side.
  final double dx;

  /// The same toward the bottom edge of the screen.
  final double dy;

  /// Whether the phone is level: within [levelTolerance] of flat, screen up.
  final bool level;

  @override
  bool operator ==(Object other) =>
      other is PhoneTilt &&
      other.angle == angle &&
      other.dx == dx &&
      other.dy == dy &&
      other.level == level;

  @override
  int get hashCode => Object.hash(angle, dx, dy, level);
}

/// Works out how a phone is held from its gravity readings, steadies the
/// jitter, and says when it is level without flickering at the line.
///
/// Readings are in the phone's own axes, as [HeadingFilter] takes them. At
/// rest the accelerometer reads straight up, so a phone lying flat with its
/// screen up reads (0, 0, +g).
class TiltFilter {
  /// Creates a filter. A lower [smoothing] (0 to 1) steadies the bubble more
  /// and makes it slower to follow.
  TiltFilter({
    this.smoothing = 0.15,
    this.levelWithin = levelTolerance,
    this.slack = 2,
  });

  /// Share of each new reading that is taken in.
  final double smoothing;

  /// How far from flat, in degrees, a phone may be to become level.
  final double levelWithin;

  /// How many degrees further a level phone may lean before it stops being
  /// level, so a hand held at the line does not flicker between the two.
  final double slack;

  double _x = 0;
  double _y = 0;
  double _z = 0;
  PhoneTilt? _tilt;

  /// The latest tilt, or null before the first usable reading.
  PhoneTilt? get tilt => _tilt;

  /// The steadied gravity reading the tilt is worked out from, in the phone's
  /// own axes and of length one, for [HeadingFilter.addWith]. Null before the
  /// first usable reading, and while two opposite readings cancel.
  ({double x, double y, double z})? get gravity {
    if (_tilt == null) return null;
    final length = math.sqrt(_x * _x + _y * _y + _z * _z);
    if (length < 0.1) return null;
    return (x: _x / length, y: _y / length, z: _z / length);
  }

  /// Takes a gravity reading (`ax`, `ay`, `az`) and returns the tilt. A
  /// reading with no gravity in it (free fall) changes nothing.
  PhoneTilt? add(double ax, double ay, double az) {
    final gravity = math.sqrt(ax * ax + ay * ay + az * az);
    if (gravity < 0.1) return _tilt;
    // Only the direction counts, so a jolt weighs no more than a still hand.
    final ux = ax / gravity;
    final uy = ay / gravity;
    final uz = az / gravity;
    if (_tilt == null) {
      _x = ux;
      _y = uy;
      _z = uz;
    } else {
      _x += (ux - _x) * smoothing;
      _y += (uy - _y) * smoothing;
      _z += (uz - _z) * smoothing;
    }
    final length = math.sqrt(_x * _x + _y * _y + _z * _z);
    // Flipped right over between two readings: they cancel, wait for more.
    if (length < 0.1) return _tilt;
    final angle = math.acos((_z / length).clamp(-1.0, 1.0)) * 180 / math.pi;
    final wasLevel = _tilt?.level ?? false;
    final level = angle <= (wasLevel ? levelWithin + slack : levelWithin);
    // The raised side: the right edge when x reads up, the top edge when y
    // does, and the top of the screen is the lesser y.
    var dx = _x / length;
    var dy = -_y / length;
    if (_z < 0) {
      // Past upright the screen faces the ground and the bubble would creep
      // back to the middle as if the phone were level again: it stays at
      // the rim, on the side that is still the higher one.
      final across = math.sqrt(dx * dx + dy * dy);
      if (across > 0.001) {
        dx /= across;
        dy /= across;
      }
    }
    return _tilt = PhoneTilt(angle: angle, dx: dx, dy: dy, level: level);
  }
}
