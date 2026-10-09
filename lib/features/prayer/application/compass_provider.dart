import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../domain/qibla.dart';

/// A stream of the way the top of the phone points, in degrees clockwise from
/// magnetic north, while the phone is held flat.
abstract interface class CompassSource {
  /// Starts listening when the stream does and stops when it is cancelled.
  /// Emits an error when the device has no usable sensors.
  Stream<double> headings();
}

/// Reads the accelerometer and magnetometer. Both stay on the device and need
/// no permission.
class SensorsCompassSource implements CompassSource {
  /// Creates the source.
  const SensorsCompassSource();

  @override
  Stream<double> headings() {
    late final StreamController<double> controller;
    StreamSubscription<AccelerometerEvent>? gravity;
    StreamSubscription<MagnetometerEvent>? field;
    controller = StreamController<double>(
      onListen: () {
        final filter = HeadingFilter();
        AccelerometerEvent? last;
        gravity = accelerometerEventStream(
          samplingPeriod: SensorInterval.uiInterval,
        ).listen((event) => last = event, onError: controller.addError);
        field =
            magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval)
                .listen((event) {
                  final g = last;
                  if (g == null) return;
                  final heading = filter.add(
                    g.x,
                    g.y,
                    g.z,
                    event.x,
                    event.y,
                    event.z,
                  );
                  if (heading != null) controller.add(heading);
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

/// The live heading while the Qibla page is open; an error when the device has
/// no compass.
final compassHeadingProvider = StreamProvider.autoDispose<double>(
  (ref) => ref.watch(compassSourceProvider).headings(),
);
