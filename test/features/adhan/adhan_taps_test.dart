import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/adhan/application/adhan_providers.dart';

import '../../helpers/adhan_fixtures.dart';

class _DelayedLaunch extends FakeAdhanPlatform {
  final Completer<String?> gate = Completer<String?>();

  @override
  Future<String?> takeLaunchPayload() => gate.future;
}

void main() {
  test('keeps taps arriving while the launch payload is being read', () async {
    final platform = _DelayedLaunch();
    final container = ProviderContainer(
      overrides: [adhanPlatformProvider.overrideWithValue(platform)],
    );
    final received = <String>[];
    final subscription = container.listen(adhanTapsProvider, (_, next) {
      final tap = next.value;
      if (tap != null) received.add(tap.payload);
    });
    await Future<void>.delayed(Duration.zero);
    platform.tapController.add('prayer:times');
    await Future<void>.delayed(Duration.zero);
    platform.gate.complete('adhkar:morning');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(received, ['adhkar:morning', 'prayer:times']);
    subscription.close();
    container.dispose();
    await platform.tapController.close();
    await platform.ended.close();
  });
}
