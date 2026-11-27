import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/time/ticking_clock.dart';
import 'package:mre_quran/features/prayer/application/compass_provider.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/domain/magnetic_field.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/prayer/domain/qibla.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_settings_repository.dart';

/// A compass that counts how often it is opened and listened to.
class _Source implements CompassSource {
  int opened = 0;
  int listeners = 0;
  late final StreamController<CompassReading> controller =
      StreamController<CompassReading>(onListen: () => listeners++);

  @override
  Stream<CompassReading> readings() {
    opened++;
    return controller.stream;
  }
}

void main() {
  const level = PhoneTilt(angle: 2, dx: 0.03, dy: 0, level: true);

  /// A container reading [source], with the heading and the tilt both
  /// listened to as the Qibla page does, at a place whose magnetic [field] is
  /// given (none: magnetic north is taken for true north).
  ProviderContainer listenTo(_Source source, {MagneticField? field}) {
    final container = ProviderContainer(
      overrides: [
        compassSourceProvider.overrideWithValue(source),
        magneticFieldProvider.overrideWithValue(field),
      ],
    );
    addTearDown(container.dispose);
    container
      ..listen(compassHeadingProvider, (_, _) {})
      ..listen(compassMissingProvider, (_, _) {})
      ..listen(phoneTiltProvider, (_, _) {});
    return container;
  }

  test('the heading and the tilt come from one subscription', () async {
    final source = _Source();
    final container = listenTo(source);
    await pumpEventQueue();
    expect(source.opened, 1);
    expect(source.listeners, 1);
    expect(container.read(compassHeadingProvider), isNull);
    expect(container.read(phoneTiltProvider), isNull);

    source.controller.add(const CompassReading(heading: 90, tilt: level));
    await pumpEventQueue();
    expect(container.read(compassHeadingProvider), 90);
    expect(container.read(phoneTiltProvider), level);
    expect(source.opened, 1);
    expect(source.listeners, 1);
  });

  test('a phone that cannot tell its tilt still gives the heading', () async {
    final source = _Source();
    final container = listenTo(source);
    source.controller.add(const CompassReading(heading: 10));
    await pumpEventQueue();
    expect(container.read(compassHeadingProvider), 10);
    expect(container.read(compassMissingProvider), isFalse);
    expect(container.read(phoneTiltProvider), isNull);
  });

  test('without sensors there is an error and no level, even after '
      'readings', () async {
    final source = _Source();
    final container = listenTo(source);
    source.controller.add(const CompassReading(heading: 90, tilt: level));
    await pumpEventQueue();
    expect(container.read(phoneTiltProvider), level);

    source.controller.addError('no sensor');
    await pumpEventQueue();
    expect(container.read(compassMissingProvider), isTrue);
    expect(container.read(phoneTiltProvider), isNull);
  });

  group('true north', () {
    test('the heading is the sensors\' plus the declination of the place, '
        'east or west', () async {
      for (final (east, readings) in [
        // Magnetic north 20° east of true north: the phone points further
        // round than its compass says.
        (10261.0, {90.0: 110.0, 350.0: 10.0, 0.0: 20.0}),
        // And 20° west of it.
        (-10261.0, {90.0: 70.0, 10.0: 350.0, 0.0: 340.0}),
      ]) {
        final source = _Source();
        final container = listenTo(
          source,
          field: MagneticField(north: 28191, east: east, down: 30000),
        );
        for (final MapEntry(key: magnetic, value: fromTrueNorth)
            in readings.entries) {
          source.controller.add(CompassReading(heading: magnetic, tilt: level));
          await pumpEventQueue();
          expect(
            container.read(compassHeadingProvider),
            closeTo(fromTrueNorth, 0.01),
          );
          // The tilt has nothing to do with north.
          expect(container.read(phoneTiltProvider), level);
        }
        expect(source.opened, 1);
      }
    });

    /// The field the app works out for a phone whose saved place is [place],
    /// on 27 November 2026.
    Future<MagneticField?> fieldAt(PrayerPlace? place) async {
      final container = ProviderContainer(
        overrides: [
          prayerRepositoryProvider.overrideWithValue(
            MemoryPrayerRepository()..place = place,
          ),
          locationSourceProvider.overrideWithValue(FakeLocationSource()),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 27)),
        ],
      );
      addTearDown(container.dispose);
      container.listen(magneticFieldProvider, (_, _) {});
      await container.read(prayerProvider.future);
      return container.read(magneticFieldProvider);
    }

    test('the field is the model\'s at the saved place on today\'s date, '
        'and each place has its own', () async {
      // Named, so nothing goes looking for a name.
      final cairo = await fieldAt(PrayerPlace(30.04, 31.24, name: 'Cairo'));
      final model = magneticField(
        latitude: 30.04,
        longitude: 31.24,
        year: decimalYear(DateTime.utc(2026, 11, 27)),
      );
      expect(cairo!.declination, closeTo(model.declination, 1e-9));
      // Nearly five degrees east in Cairo: the error the page used to have.
      expect(cairo.declination, inInclusiveRange(4, 6));

      final capeTown = await fieldAt(
        PrayerPlace(-33.92, 18.42, name: 'Cape Town'),
      );
      expect(capeTown!.declination, inInclusiveRange(-30, -23));
      final seattle = await fieldAt(
        PrayerPlace(47.6, -122.33, name: 'Seattle'),
      );
      expect(seattle!.declination, inInclusiveRange(12, 17));
    });

    test('there is no field while there is no place', () async {
      expect(await fieldAt(null), isNull);
    });
  });
}
