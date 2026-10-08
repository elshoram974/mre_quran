import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/prayer/domain/qibla.dart';

void main() {
  group('qiblaBearing', () {
    // Great-circle bearings to the Kaaba, to within a degree.
    final cases = <String, (double, double, double)>{
      'Cairo': (30.04, 31.24, 136),
      'London': (51.51, -0.13, 119),
      'New York': (40.71, -74.0, 58.5),
      'Jakarta': (-6.2, 106.82, 295),
      'Riyadh': (24.71, 46.68, 244),
    };
    for (final entry in cases.entries) {
      test('${entry.key} faces the right way', () {
        final (lat, lng, expected) = entry.value;
        expect(qiblaBearing(PrayerPlace(lat, lng)), closeTo(expected, 1.5));
      });
    }

    test('is always between 0 and 360', () {
      for (final lat in [-80.0, -30.0, 0.0, 30.0, 80.0]) {
        for (final lng in [-170.0, -60.0, 0.0, 60.0, 170.0]) {
          final bearing = qiblaBearing(PrayerPlace(lat, lng));
          expect(bearing, inInclusiveRange(0, 360));
        }
      }
    });
  });

  group('CompassPoint', () {
    test('picks the nearest of eight', () {
      expect(CompassPoint.of(0), CompassPoint.north);
      expect(CompassPoint.of(136), CompassPoint.southEast);
      expect(CompassPoint.of(359), CompassPoint.north);
      expect(CompassPoint.of(22), CompassPoint.north);
      expect(CompassPoint.of(23), CompassPoint.northEast);
      expect(CompassPoint.of(270), CompassPoint.west);
      expect(CompassPoint.of(-90), CompassPoint.west);
    });
  });

  group('angleBetween', () {
    test('is the short way round, signed', () {
      expect(angleBetween(10, 20), 10);
      expect(angleBetween(20, 10), -10);
      expect(angleBetween(350, 10), 20);
      expect(angleBetween(10, 350), -20);
      expect(angleBetween(0, 180).abs(), 180);
    });
  });

  group('HeadingFilter', () {
    // A phone lying flat: gravity along +z. The magnetic field points to north
    // and down, so north is seen at the angle behind where the top points.
    double? feed(HeadingFilter filter, double degrees) {
      final radians = degrees * math.pi / 180;
      return filter.add(
        0,
        0,
        9.81,
        -25 * math.sin(radians),
        25 * math.cos(radians),
        -40,
      );
    }

    test('top of the phone to the north, east, south, west', () {
      for (final degrees in [0.0, 90.0, 180.0, 270.0]) {
        final heading = feed(HeadingFilter(smoothing: 1), degrees)!;
        expect(angleBetween(heading, degrees).abs(), lessThan(0.5));
      }
    });

    test('gives nothing when there is no field or no gravity', () {
      final filter = HeadingFilter();
      expect(filter.add(0, 0, 9.81, 0, 0, 0), isNull);
      expect(filter.add(0, 0, 0, 10, 10, 10), isNull);
      expect(filter.heading, isNull);
    });

    test('smooths a jump and takes the short way across north', () {
      final filter = HeadingFilter(smoothing: 0.5);
      feed(filter, 350);
      expect(filter.heading, closeTo(350, 1));
      feed(filter, 10);
      // Halfway between 350 and 10 is 0, not 180.
      expect(angleBetween(0, filter.heading!).abs(), lessThan(1.5));
    });
  });
}
