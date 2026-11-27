import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/time/ticking_clock.dart';
import '../domain/magnetic_field.dart';
import '../domain/qibla.dart';
import 'prayer_provider.dart';

/// What the phone's sensors say at one moment.
@immutable
class CompassReading {
  /// Creates a reading.
  const CompassReading({required this.heading, this.tilt});

  /// The way the top of the phone points, in degrees clockwise from magnetic
  /// north.
  final double heading;

  /// How the phone is held, or null where that cannot be told.
  final PhoneTilt? tilt;
}

/// The phone as a compass: which way its top points, and how it is held.
abstract interface class CompassSource {
  /// Starts listening when the stream does and stops when it is cancelled.
  /// Emits an error when the device has no usable sensors.
  Stream<CompassReading> readings();
}

/// Reads the accelerometer and magnetometer. Both stay on the device and need
/// no permission.
class SensorsCompassSource implements CompassSource {
  /// Creates the source.
  const SensorsCompassSource();

  @override
  Stream<CompassReading> readings() {
    late final StreamController<CompassReading> controller;
    StreamSubscription<AccelerometerEvent>? gravity;
    StreamSubscription<MagnetometerEvent>? field;
    controller = StreamController<CompassReading>(
      onListen: () {
        final headings = HeadingFilter();
        final tilts = TiltFilter();
        AccelerometerEvent? last;
        // One accelerometer subscription serves both: the heading needs
        // gravity to know which way is down, and the tilt is gravity itself.
        gravity =
            accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
                .listen((event) {
                  last = event;
                  tilts.add(event.x, event.y, event.z);
                }, onError: controller.addError);
        field =
            magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval)
                .listen((event) {
                  final g = last;
                  if (g == null) return;
                  final heading = headings.add(
                    g.x,
                    g.y,
                    g.z,
                    event.x,
                    event.y,
                    event.z,
                  );
                  if (heading != null) {
                    controller.add(
                      CompassReading(heading: heading, tilt: tilts.tilt),
                    );
                  }
                }, onError: controller.addError);
      },
      onCancel: () async {
        await gravity?.cancel();
        await field?.cancel();
      },
    );
    return controller.stream;
  }
}

/// Provides the compass. Tests override it.
final compassSourceProvider = Provider<CompassSource>(
  (ref) => const SensorsCompassSource(),
);

/// What the sensors say while the Qibla page is open; an error when the
/// device has no compass. It is the one subscription to them: the page reads
/// it through [compassHeadingProvider], [compassMissingProvider] and
/// [phoneTiltProvider].
final compassReadingProvider = StreamProvider.autoDispose<CompassReading>(
  (ref) => ref.watch(compassSourceProvider).readings(),
);

/// The Earth's magnetic field at the person's saved place today, from the
/// World Magnetic Model, or null while there is no place. Worked out once
/// each time the Qibla page opens: the field moves by about a tenth of a
/// degree in a year.
final magneticFieldProvider = Provider.autoDispose<MagneticField?>((ref) {
  final place = ref.watch(prayerProvider.select((state) => state.value?.place));
  if (place == null) return null;
  return magneticField(
    latitude: place.latitude,
    longitude: place.longitude,
    year: decimalYear(ref.watch(clockProvider)()),
    altitude: (place.altitude ?? 0) / 1000,
  );
});

/// The live heading while the Qibla page is open, in degrees clockwise from
/// true north, or null before the first reading and on a device with no
/// compass. Every heading the page shows comes through here.
///
/// The sensors count from magnetic north and the Qibla's bearing from true
/// north, so this is where the one becomes the other: the magnetic
/// declination at the saved place ([magneticFieldProvider]) is added.
final compassHeadingProvider = Provider.autoDispose<double?>((ref) {
  final magnetic = ref.watch(compassReadingProvider).value?.heading;
  if (magnetic == null) return null;
  return ref.watch(magneticFieldProvider)?.trueFromMagnetic(magnetic) ??
      magnetic;
});

/// Whether the device turned out to have no usable compass.
final compassMissingProvider = Provider.autoDispose<bool>(
  (ref) => ref.watch(compassReadingProvider).hasError,
);

/// How the phone is held, or null while that is not known: before the first
/// reading, and on a device that cannot tell or has no compass.
final phoneTiltProvider = Provider.autoDispose<PhoneTilt?>((ref) {
  final reading = ref.watch(compassReadingProvider);
  return reading.hasError ? null : reading.value?.tilt;
});
