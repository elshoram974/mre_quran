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

  group('TiltFilter', () {
    const g = 9.81;
    double rad(double degrees) => degrees * math.pi / 180;

    // Takes each reading whole, to test the geometry apart from the
    // smoothing.
    TiltFilter raw() => TiltFilter(smoothing: 1);

    // A phone lying flat, then leaned by [degrees] so that one edge is the
    // higher: [toward] is that edge as on a clock face, 0 the top edge, 90
    // the right, 180 the bottom, 270 the left.
    PhoneTilt lean(TiltFilter filter, double degrees, {double toward = 0}) {
      final across = g * math.sin(rad(degrees));
      return filter.add(
        across * math.sin(rad(toward)),
        across * math.cos(rad(toward)),
        g * math.cos(rad(degrees)),
      )!;
    }

    test('flat on its back is level, the bubble in the middle', () {
      final tilt = raw().add(0, 0, g)!;
      expect(tilt.angle, closeTo(0, 1e-6));
      expect(tilt.dx, closeTo(0, 1e-9));
      expect(tilt.dy, closeTo(0, 1e-9));
      expect(tilt.level, isTrue);
    });

    test('the bubble floats to the raised side', () {
      final far = math.sin(rad(20));
      // (the raised edge, where the bubble goes: right, down the screen)
      final cases = <double, (double, double)>{
        0: (0, -far), // top edge up: up the screen
        90: (far, 0), // right edge up: to the right
        180: (0, far), // bottom edge up: down the screen
        270: (-far, 0), // left edge up: to the left
      };
      for (final entry in cases.entries) {
        final tilt = lean(raw(), 20, toward: entry.key);
        final (dx, dy) = entry.value;
        expect(tilt.angle, closeTo(20, 1e-6));
        expect(tilt.dx, closeTo(dx, 1e-9), reason: 'edge ${entry.key}');
        expect(tilt.dy, closeTo(dy, 1e-9), reason: 'edge ${entry.key}');
        expect(tilt.level, isFalse);
      }
    });

    test('only the direction of gravity counts, not its strength', () {
      final weak = raw().add(1, 0, 1)!;
      final strong = raw().add(20, 0, 20)!;
      expect(weak.angle, closeTo(45, 1e-6));
      expect(strong.angle, closeTo(45, 1e-6));
      expect(weak.dx, closeTo(strong.dx, 1e-12));
    });

    test('upright is 90 degrees, and not level', () {
      final tilt = raw().add(0, g, 0)!;
      expect(tilt.angle, closeTo(90, 1e-6));
      expect(tilt.dy, closeTo(-1, 1e-9));
      expect(tilt.level, isFalse);
    });

    test('face down is not level, though no edge is the higher', () {
      final tilt = raw().add(0, 0, -g)!;
      expect(tilt.angle, closeTo(180, 1e-6));
      expect(tilt.level, isFalse);
    });

    test('past upright the bubble stays at the rim', () {
      // Leaning over its top edge toward face down: sin(150°) is only a
      // half, as at 30°, but this is nothing like level.
      final tilt = lean(raw(), 150);
      expect(tilt.angle, closeTo(150, 1e-6));
      expect(tilt.dx, closeTo(0, 1e-9));
      expect(tilt.dy, closeTo(-1, 1e-9));
      expect(tilt.level, isFalse);
    });

    test('level means within ten degrees of flat', () {
      expect(levelTolerance, 10);
      expect(lean(raw(), 9.9).level, isTrue);
      expect(lean(raw(), 10.1).level, isFalse);
    });

    test('a level phone stays level a little past the line, and a tilted '
        'one stays tilted until it is back inside it', () {
      final filter = raw();
      expect(lean(filter, 9).level, isTrue);
      expect(lean(filter, 11.5).level, isTrue);
      expect(lean(filter, 12.5).level, isFalse);
      expect(lean(filter, 11.5).level, isFalse);
      expect(lean(filter, 10.5).level, isFalse);
      expect(lean(filter, 9.5).level, isTrue);
    });

    test('a hand trembling at the line does not flicker', () {
      for (final start in [5.0, 20.0]) {
        final filter = raw();
        final first = lean(filter, start).level;
        for (var i = 0; i < 40; i++) {
          expect(lean(filter, i.isEven ? 10.4 : 11.6).level, first);
        }
      }
    });

    test('smoothing steadies a jolt, and still arrives', () {
      final filter = TiltFilter();
      filter.add(0, 0, g);
      final jolt = lean(filter, 40, toward: 90);
      expect(jolt.angle, lessThan(levelTolerance));
      expect(jolt.level, isTrue);
      var tilt = jolt;
      for (var i = 0; i < 60; i++) {
        tilt = lean(filter, 40, toward: 90);
      }
      expect(tilt.angle, closeTo(40, 0.5));
      expect(tilt.dx, closeTo(math.sin(rad(40)), 0.01));
      expect(tilt.level, isFalse);
    });

    test('free fall teaches nothing', () {
      final filter = TiltFilter();
      expect(filter.add(0, 0, 0), isNull);
      expect(filter.tilt, isNull);
      final flat = filter.add(0, 0, g);
      expect(filter.add(0.01, 0.01, 0.01), same(flat));
      expect(filter.tilt, same(flat));
    });

    test('gives the gravity it has steadied, of length one', () {
      final filter = TiltFilter();
      expect(filter.gravity, isNull);
      filter.add(0, 0, g);
      expect(filter.gravity, (x: 0.0, y: 0.0, z: 1.0));
      // A jolt to the right moves it only a little of the way.
      filter.add(g, 0, 0);
      final steadied = filter.gravity!;
      expect(steadied.x, inExclusiveRange(0.1, 0.2));
      expect(
        steadied.x * steadied.x +
            steadied.y * steadied.y +
            steadied.z * steadied.z,
        closeTo(1, 1e-9),
      );
    });
  });

  group('the heading with a steadied gravity', () {
    const g = 9.81;

    // A phone lying flat with its top to the north in London, where the
    // Earth's field dips 66 degrees: 19.6 microtesla level, 44.9 down. The
    // hand shakes it sideways by half a metre a second squared, about three
    // degrees of false tilt, one way and then the other. Each heading is
    // taken whole, to see the gravity's doing alone.
    double worst({required bool steadied}) {
      final headings = HeadingFilter(smoothing: 1);
      final tilts = TiltFilter()..add(0, 0, g);
      var worst = 0.0;
      for (var i = 0; i < 60; i++) {
        final push = i.isEven ? 0.5 : -0.5;
        tilts.add(push, 0, g);
        final heading = steadied
            ? headings.addWith(tilts, 0, 19.6, -44.9)!
            : headings.add(push, 0, g, 0, 19.6, -44.9)!;
        worst = math.max(worst, angleBetween(0, heading).abs());
      }
      return worst;
    }

    test('a shaking hand turns the needle by degrees through the raw '
        'gravity, and hardly at all through the steadied one', () {
      expect(worst(steadied: false), greaterThan(5));
      expect(worst(steadied: true), lessThan(1.5));
    });

    test('a phone that stays tilted is still read right', () {
      // Leaned 30 degrees, right edge up, top to the north-east: once the
      // gravity has settled the heading is the one the raw reading gives.
      const lean = 30 * math.pi / 180;
      const turn = 45 * math.pi / 180;
      final ax = g * math.sin(lean);
      final az = g * math.cos(lean);
      // The field in the phone's axes: north and down, turned by the
      // heading and then leaned with the phone.
      const level = 19.6;
      const down = 44.9;
      final across = -level * math.sin(turn);
      final mx = across * math.cos(lean) - down * math.sin(lean);
      final my = level * math.cos(turn);
      final mz = -across * math.sin(lean) - down * math.cos(lean);
      final exact = HeadingFilter(smoothing: 1).add(ax, 0, az, mx, my, mz)!;
      expect(exact, closeTo(45, 0.01));

      final headings = HeadingFilter(smoothing: 1);
      final tilts = TiltFilter()..add(0, 0, g);
      double? heading;
      for (var i = 0; i < 80; i++) {
        tilts.add(ax, 0, az);
        heading = headings.addWith(tilts, mx, my, mz);
      }
      expect(heading, closeTo(exact, 0.05));
    });

    test('there is no heading before there is any gravity', () {
      final headings = HeadingFilter();
      expect(headings.addWith(TiltFilter(), 0, 19.6, -44.9), isNull);
      expect(headings.heading, isNull);
    });
  });
}
