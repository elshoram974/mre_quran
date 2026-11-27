import 'dart:math' as math;
import 'dart:typed_data';

import 'wmm2025_coefficients.dart';

/// How far a magnetic compass can be trusted at a place, by how strong the
/// horizontal part of the Earth's field is there. The limits are the World
/// Magnetic Model's own: around each magnetic pole the field points almost
/// straight down, and too little of it is left to turn a compass.
enum CompassZone {
  /// A horizontal field of 6000 nT or more: a compass works.
  reliable,

  /// From 2000 nT up to 6000 nT, the model's "caution zone": a compass may be
  /// several degrees off.
  caution,

  /// Under 2000 nT, the model's "blackout zone": a compass is not to be
  /// relied on, and neither is the declination the model gives.
  blackout;

  /// The zone of a place whose horizontal field is [horizontal] nanotesla.
  static CompassZone of(double horizontal) => horizontal < 2000
      ? CompassZone.blackout
      : horizontal < 6000
      ? CompassZone.caution
      : CompassZone.reliable;
}

/// The Earth's magnetic field at one place and time, in nanotesla.
class MagneticField {
  /// Creates a field from its three parts.
  const MagneticField({
    required this.north,
    required this.east,
    required this.down,
  });

  /// The part that points to true north.
  final double north;

  /// The part that points east.
  final double east;

  /// The part that points down.
  final double down;

  /// The strength of the horizontal part, the one that turns a compass.
  double get horizontal => math.sqrt(north * north + east * east);

  /// The magnetic declination: how far magnetic north is from true north, in
  /// degrees between -180 and 180, positive to the east. A compass heading
  /// plus this is a heading from true north.
  double get declination => math.atan2(east, north) * 180 / math.pi;

  /// How far a compass can be trusted in this field.
  CompassZone get zone => CompassZone.of(horizontal);

  /// A heading or bearing a compass reads here, counted from true north
  /// instead: [degrees] clockwise from magnetic north in, 0 to 360 clockwise
  /// from true north out.
  double trueFromMagnetic(double degrees) => (degrees + declination) % 360;

  /// A bearing from true north as a compass reads it here: [degrees]
  /// clockwise from true north in, 0 to 360 clockwise from magnetic north
  /// out.
  double magneticFromTrue(double degrees) => (degrees - declination) % 360;
}

/// The semi-major axis of the WGS-84 ellipsoid, in kilometres.
const double _equatorRadius = 6378.137;

/// The flattening of the WGS-84 ellipsoid.
const double _flattening = 1 / 298.257223563;

/// The radius of the sphere the coefficients are given on, in kilometres.
const double _modelRadius = 6371.2;

/// [date] as a decimal year: 2026.5 is the middle of 2026.
double decimalYear(DateTime date) {
  final moment = date.toUtc();
  final start = DateTime.utc(moment.year);
  final length = DateTime.utc(moment.year + 1).difference(start);
  return moment.year +
      moment.difference(start).inMicroseconds / length.inMicroseconds;
}

/// The Earth's main magnetic field at [latitude] and [longitude] (degrees on
/// the WGS-84 ellipsoid, north and east positive) in [year], a decimal year
/// such as 2026.5 ([decimalYear]), [altitude] kilometres above the ellipsoid.
///
/// This is the World Magnetic Model 2025 of NOAA and the British Geological
/// Survey: a spherical-harmonic expansion to degree 12 whose coefficients
/// ([wmm2025Coefficients]) change linearly with time. It describes the field
/// of the Earth's core only: rock, steel and electronics near the compass
/// are not in it.
///
/// The model is made for 2025.0 to 2030.0. For any other year the field is
/// still worked out, each coefficient carried on at its yearly rate, because
/// a declination that is a little out of date is far nearer the truth than
/// none. Past 2030 the error grows with every year, so the table has to be
/// replaced by WMM2030 when that is published (it is due at the end of 2029).
MagneticField magneticField({
  required double latitude,
  required double longitude,
  required double year,
  double altitude = 0,
}) {
  final phi = latitude * math.pi / 180;
  final lambda = longitude * math.pi / 180;
  final sinPhi = math.sin(phi);
  final cosPhi = math.cos(phi);

  // From the ellipsoid to the sphere: the distance from the Earth's centre
  // and the sine and cosine of the geocentric latitude.
  const eccentricity2 = _flattening * (2 - _flattening);
  final curvature =
      _equatorRadius / math.sqrt(1 - eccentricity2 * sinPhi * sinPhi);
  final fromAxis = (curvature + altitude) * cosPhi;
  final fromEquator = (curvature * (1 - eccentricity2) + altitude) * sinPhi;
  final radius = math.sqrt(fromAxis * fromAxis + fromEquator * fromEquator);
  final sine = fromEquator / radius;
  final cosine = fromAxis / radius;

  // Schmidt semi-normalised associated Legendre functions of the sine, by
  // recursion; the function of degree n and order m is at n (n + 1) / 2 + m.
  // `slope` is its derivative by the geocentric latitude. `overCosine` is the
  // function divided by the cosine, for orders 1 and up: its own recursion
  // needs no division, so the east part stays finite at the poles.
  const count = (wmm2025Degree + 1) * (wmm2025Degree + 2) ~/ 2;
  final legendre = Float64List(count);
  final slope = Float64List(count);
  final overCosine = Float64List(count);
  legendre[0] = 1;
  for (var n = 1; n <= wmm2025Degree; n++) {
    final row = n * (n + 1) ~/ 2;
    final above = row - n;
    for (var m = 0; m < n; m++) {
      final i = row + m;
      final j = above + m;
      final norm = math.sqrt(n * n - m * m);
      final a = (2 * n - 1) / norm;
      legendre[i] = a * sine * legendre[j];
      slope[i] = a * (cosine * legendre[j] + sine * slope[j]);
      overCosine[i] = a * sine * overCosine[j];
      if (m < n - 1) {
        final k = above - (n - 1) + m;
        final b = math.sqrt((n - 1) * (n - 1) - m * m) / norm;
        legendre[i] -= b * legendre[k];
        slope[i] -= b * slope[k];
        overCosine[i] -= b * overCosine[k];
      }
    }
    final i = row + n;
    final j = above + n - 1;
    final a = n == 1 ? 1.0 : math.sqrt((2 * n - 1) / (2 * n));
    legendre[i] = a * cosine * legendre[j];
    slope[i] = a * (cosine * slope[j] - sine * legendre[j]);
    overCosine[i] = n == 1 ? 1 : a * cosine * overCosine[j];
  }

  final cosines = Float64List(wmm2025Degree + 1);
  final sines = Float64List(wmm2025Degree + 1);
  for (var m = 0; m <= wmm2025Degree; m++) {
    cosines[m] = math.cos(m * lambda);
    sines[m] = math.sin(m * lambda);
  }

  // The field on the sphere: minus the gradient of the potential.
  final elapsed = year - wmm2025Epoch;
  final ratio = _modelRadius / radius;
  var power = ratio * ratio;
  var north = 0.0;
  var east = 0.0;
  var down = 0.0;
  for (var n = 1; n <= wmm2025Degree; n++) {
    power *= ratio;
    for (var m = 0; m <= n; m++) {
      final i = n * (n + 1) ~/ 2 + m;
      final line = wmm2025Coefficients[i - 1];
      final g = line.g + elapsed * line.gDot;
      final h = line.h + elapsed * line.hDot;
      final wave = g * cosines[m] + h * sines[m];
      north -= power * wave * slope[i];
      east += power * m * (g * sines[m] - h * cosines[m]) * overCosine[i];
      down -= power * (n + 1) * wave * legendre[i];
    }
  }

  // Back to the ellipsoid: its vertical leans from the sphere's by the
  // difference between the two latitudes.
  final lean = sine * cosPhi - cosine * sinPhi;
  final upright = cosine * cosPhi + sine * sinPhi;
  return MagneticField(
    north: north * upright - down * lean,
    east: east,
    down: north * lean + down * upright,
  );
}
