import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/prayer/application/compass_provider.dart';
import 'package:mre_quran/features/prayer/domain/qibla.dart';

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
  /// listened to as the Qibla page does.
  ProviderContainer listenTo(_Source source) {
    final container = ProviderContainer(
      overrides: [compassSourceProvider.overrideWithValue(source)],
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
}
