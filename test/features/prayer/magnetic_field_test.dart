import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/prayer/domain/magnetic_field.dart';
import 'package:mre_quran/features/prayer/domain/wmm2025_coefficients.dart';

/// The SHA-256 of the official `WMM.COF` (in `WMM2025COF.zip`, from
/// https://www.ncei.noaa.gov/products/world-magnetic-model).
const String _coefficientFileSha =
    'dfa8597825af4e0b87ff4198a5b4fb661b3c49f4cd090cd0164e0259b075582f';

/// The numbers on each line of an official test-value file in
/// `test/fixtures/wmm`, after checking the file is the one published.
///
/// The published files end their lines with a line feed; Git may add carriage
/// returns on Windows, so those are dropped before the check.
List<List<double>> _officialValues(String name, String sha) {
  final bytes = File('test/fixtures/wmm/$name')
      .readAsBytesSync()
      .where((byte) => byte != 0x0d)
      .toList();
  expect(sha256.convert(bytes).toString(), sha, reason: name);
  return [
    for (final line in const LineSplitter().convert(ascii.decode(bytes)))
      if (line.trim().isNotEmpty && !line.startsWith('#'))
        [
          for (final number in line.trim().split(RegExp(r'\s+')))
            double.parse(number),
        ],
  ];
}

double _degrees(double radians) => radians * 180 / math.pi;

/// The dip of [field] below the horizontal, in degrees.
double _inclination(MagneticField field) =>
    _degrees(math.atan2(field.down, field.horizontal));

double _total(MagneticField field) =>
    math.sqrt(field.horizontal * field.horizontal + field.down * field.down);

MagneticField _at(double latitude, double longitude, [double year = 2026]) =>
    magneticField(latitude: latitude, longitude: longitude, year: year);

void main() {
  group('WMM2025 coefficients', () {
    test('are the official file, byte for byte', () {
      // Written back out the way WMM.COF prints them, the table has the
      // published file's checksum: no number was mistyped or left out.
      String fixed(double value, int width) =>
          value.toStringAsFixed(1).padLeft(width);
      final file = StringBuffer(
        '    ${wmm2025Epoch.toStringAsFixed(1)}'
        '            WMM-2025     11/13/2024\n',
      );
      for (final line in wmm2025Coefficients) {
        file
          ..write('${line.n}'.padLeft(3))
          ..write('${line.m}'.padLeft(3))
          ..write(fixed(line.g, 10))
          ..write(fixed(line.h, 10))
          ..write(fixed(line.gDot, 11))
          ..write(fixed(line.hDot, 11))
          ..write('\n');
      }
      final end = '9' * 48;
      file.write('$end\n$end\n');
      expect(
        sha256.convert(ascii.encode(file.toString())).toString(),
        _coefficientFileSha,
      );
    });

    test('are in the order the model reads them', () {
      expect(
        wmm2025Coefficients,
        hasLength((wmm2025Degree + 1) * (wmm2025Degree + 2) ~/ 2 - 1),
      );
      for (var n = 1; n <= wmm2025Degree; n++) {
        for (var m = 0; m <= n; m++) {
          final line = wmm2025Coefficients[n * (n + 1) ~/ 2 + m - 1];
          expect((line.n, line.m), (n, m));
        }
      }
    });
  });

  group('magneticField', () {
    test('gives the 100 test values that ship with the model', () {
      // WMM2025_TestValues.txt from WMM2025COF.zip, unmodified: year,
      // altitude (km), latitude, longitude, then D, I, H, X, Y, Z, F.
      final rows = _officialValues(
        'WMM2025_TestValues.txt',
        'e6975b093dddeb6153e0b23cc418425c438167e7c5b1dd795da379cb654f5819',
      );
      expect(rows, hasLength(100));
      for (final row in rows) {
        final field = magneticField(
          year: row[0],
          altitude: row[1],
          latitude: row[2],
          longitude: row[3],
        );
        final reason = 'year ${row[0]}, ${row[1]} km, ${row[2]}, ${row[3]}';
        // The angles are printed to a hundredth of a degree.
        expect(field.declination, closeTo(row[4], 0.005), reason: reason);
        expect(_inclination(field), closeTo(row[5], 0.005), reason: reason);
        // The strengths are printed to a millionth of a nanotesla. East and
        // down agree that far; north (and so H and F) to under a thousandth,
        // which is all the file's own north column holds.
        expect(field.horizontal, closeTo(row[6], 1e-3), reason: reason);
        expect(field.north, closeTo(row[7], 1e-3), reason: reason);
        expect(field.east, closeTo(row[8], 1e-6), reason: reason);
        expect(field.down, closeTo(row[9], 5e-6), reason: reason);
        expect(_total(field), closeTo(row[10], 1e-3), reason: reason);
        // The declination to far more than two decimals, from the file's own
        // north and east.
        expect(
          field.declination,
          closeTo(_degrees(math.atan2(row[8], row[7])), 1e-5),
          reason: reason,
        );
      }
    });

    test('gives the 12 test values of the model page', () {
      // WMM2025_TEST_VALUES.txt from the model's page, unmodified: six of
      // them on the ground, where the app is. Year, altitude (km), latitude,
      // longitude, then X, Y, Z, H, F to a tenth of a nanotesla, I and D.
      final rows = _officialValues(
        'WMM2025_TEST_VALUES.txt',
        'ae289c94e2200e4deeae2dfdedf543a8a0e93096512b30d6a754199731f570d0',
      );
      expect(rows, hasLength(12));
      expect(rows.where((row) => row[1] == 0), hasLength(6));
      for (final row in rows) {
        final field = magneticField(
          year: row[0],
          altitude: row[1],
          latitude: row[2],
          longitude: row[3],
        );
        final reason = 'year ${row[0]}, ${row[1]} km, ${row[2]}, ${row[3]}';
        expect(field.north, closeTo(row[4], 0.05), reason: reason);
        expect(field.east, closeTo(row[5], 0.05), reason: reason);
        expect(field.down, closeTo(row[6], 0.05), reason: reason);
        expect(field.horizontal, closeTo(row[7], 0.05), reason: reason);
        expect(_total(field), closeTo(row[8], 0.05), reason: reason);
        expect(_inclination(field), closeTo(row[9], 0.005), reason: reason);
        expect(field.declination, closeTo(row[10], 0.005), reason: reason);
      }
    });

    // Well-known declinations of the 2020s, loosely: the sign and the size.
    final cities = <String, (double, double, double, double)>{
      'Makkah, a little east': (21.4225, 39.8262, 2, 5),
      'Cairo, a little east': (30.04, 31.24, 3, 7),
      'Jakarta, almost none': (-6.2, 106.82, -1, 2),
      'Moscow, east': (55.75, 37.62, 10, 14.5),
      'Seattle, east': (47.6, -122.33, 12, 17),
      'Auckland, east': (-36.85, 174.76, 18, 23),
      'New York, west': (40.71, -74, -15, -10),
      'Reykjavik, west': (64.15, -21.94, -14, -8),
      'Sao Paulo, far west': (-23.55, -46.63, -25, -19),
      'Cape Town, far west': (-33.92, 18.42, -30, -23),
    };
    for (final MapEntry(key: name, value: (lat, lng, low, high))
        in cities.entries) {
      test('declination in $name', () {
        expect(_at(lat, lng).declination, inInclusiveRange(low, high));
      });
    }

    test('does not jump at the date line', () {
      final west = _at(-17.7, -180);
      final east = _at(-17.7, 180);
      expect(east.declination, closeTo(west.declination, 1e-9));
      expect(
        _at(-17.7, 179.999).declination,
        closeTo(_at(-17.7, -179.999).declination, 1e-3),
      );
      // A longitude counted the long way round is the same place.
      expect(_at(47.6, 237.67).north, closeTo(_at(47.6, -122.33).north, 1e-6));
    });

    test('stays finite at the geographic poles', () {
      for (final latitude in [90.0, -90.0]) {
        final pole = _at(latitude, 0);
        expect(pole.north.isFinite && pole.east.isFinite, isTrue);
        // The pole is one place whatever the longitude: the same strength,
        // and a north that only turns with the meridian it is named along.
        for (final longitude in [90.0, -123.0, 180.0]) {
          final again = _at(latitude, longitude);
          expect(again.horizontal, closeTo(pole.horizontal, 1e-6));
          expect(again.down, closeTo(pole.down, 1e-6));
          final turned = latitude > 0 ? longitude : -longitude;
          final apart = (again.declination - pole.declination - turned) % 360;
          expect(math.min(apart, 360 - apart), lessThan(1e-9));
        }
        // And next to it the field is the same.
        final near = _at(latitude > 0 ? 89.999999 : -89.999999, 0);
        expect(near.north, closeTo(pole.north, 0.01));
        expect(near.east, closeTo(pole.east, 0.01));
      }
    });

    test('points straight down at the magnetic poles', () {
      // Where the model's own horizontal field vanishes at 2025.0.
      final north = _at(85.762, 139.298, 2025);
      expect(north.horizontal, lessThan(5));
      expect(north.down, greaterThan(50000));
      final south = _at(-63.851, 135.078, 2025);
      expect(south.horizontal, lessThan(5));
      expect(south.down, lessThan(-50000));
    });

    test('carries on past the years the model is made for', () {
      // Each coefficient changes at a steady yearly rate, so the field at a
      // place changes by the same amount every five years: before 2025,
      // through 2025 to 2030, and after.
      for (final (latitude, longitude) in [(30.04, 31.24), (-33.92, 18.42)]) {
        final fields = [
          for (final year in [2020.0, 2025.0, 2030.0, 2035.0, 2040.0])
            _at(latitude, longitude, year),
        ];
        for (var i = 2; i < fields.length; i++) {
          expect(
            fields[i].north - fields[i - 1].north,
            closeTo(fields[i - 1].north - fields[i - 2].north, 1e-6),
          );
          expect(
            fields[i].east - fields[i - 1].east,
            closeTo(fields[i - 1].east - fields[i - 2].east, 1e-6),
          );
          // No jump at either end: a few degrees in five years at most.
          expect(
            (fields[i].declination - fields[i - 1].declination).abs(),
            lessThan(3),
          );
        }
      }
    });
  });

  group('true and magnetic north', () {
    // Magnetic north 20° east of true north, and 20° west of it.
    const east = MagneticField(north: 28191, east: 10261, down: 30000);
    const west = MagneticField(north: 28191, east: -10261, down: 30000);

    test('a compass heading is counted from true north', () {
      expect(east.declination, closeTo(20, 0.01));
      // The needle's own north is 20° east of true north.
      expect(east.trueFromMagnetic(0), closeTo(20, 0.01));
      expect(east.trueFromMagnetic(350), closeTo(10, 0.01));
      expect(west.trueFromMagnetic(0), closeTo(340, 0.01));
      expect(west.trueFromMagnetic(100), closeTo(80, 0.01));
    });

    test('a true bearing is given as a compass reads it', () {
      expect(east.magneticFromTrue(136), closeTo(116, 0.01));
      expect(east.magneticFromTrue(10), closeTo(350, 0.01));
      expect(west.magneticFromTrue(350), closeTo(10, 0.01));
    });

    test('one undoes the other, and both stay between 0 and 360', () {
      for (final field in [
        east,
        west,
        _at(-33.92, 18.42),
        _at(47.6, -122.33),
      ]) {
        for (var degrees = 0.0; degrees < 360; degrees += 22.5) {
          final magnetic = field.magneticFromTrue(degrees);
          expect(magnetic, inInclusiveRange(0, 360));
          final back = field.trueFromMagnetic(magnetic);
          expect(back, inInclusiveRange(0, 360));
          final apart = (back - degrees) % 360;
          expect(math.min(apart, 360 - apart), lessThan(1e-9));
        }
      }
    });
  });

  group('CompassZone', () {
    test('follows the limits of the model', () {
      expect(CompassZone.of(0), CompassZone.blackout);
      expect(CompassZone.of(1999.9), CompassZone.blackout);
      expect(CompassZone.of(2000), CompassZone.caution);
      expect(CompassZone.of(5999.9), CompassZone.caution);
      expect(CompassZone.of(6000), CompassZone.reliable);
      expect(CompassZone.of(40000), CompassZone.reliable);
    });

    test('is reliable where people live, and not near a magnetic pole', () {
      expect(_at(21.4225, 39.8262).zone, CompassZone.reliable);
      expect(_at(30.04, 31.24).zone, CompassZone.reliable);
      expect(_at(64.15, -21.94).zone, CompassZone.reliable);
      expect(_at(-33.92, 18.42).zone, CompassZone.reliable);
      // Resolute Bay, in the Canadian Arctic.
      expect(_at(74.7, -94.83).zone, CompassZone.caution);
      expect(_at(86, 139).zone, CompassZone.blackout);
      expect(_at(-64, 135).zone, CompassZone.blackout);
    });
  });

  group('decimalYear', () {
    test('counts the part of the year gone by', () {
      expect(decimalYear(DateTime.utc(2026)), 2026);
      expect(decimalYear(DateTime.utc(2026, 7, 2, 12)), 2026.5);
      // A leap year is a day longer.
      expect(decimalYear(DateTime.utc(2028, 7, 2)), 2028.5);
      expect(
        decimalYear(DateTime.utc(2029, 12, 31, 23, 59, 59)),
        closeTo(2030, 1e-6),
      );
    });

    test('is the same instant in any time zone', () {
      final noon = DateTime.utc(2026, 7, 2, 12);
      expect(decimalYear(noon.toLocal()), 2026.5);
    });
  });
}
