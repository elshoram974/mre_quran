import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/adhan/application/adhan_providers.dart';
import 'package:mre_quran/features/adhan/data/adhan_repository.dart';
import 'package:mre_quran/features/adhan/domain/adhan_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/adhan_fixtures.dart';

void main() {
  group('LocalAdhanRepository', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('starts with the bundled voice, the adhan on, and flip on', () async {
      final settings = await LocalAdhanRepository(SharedPreferencesAsync())
          .load();
      expect(settings, const AdhanSettings());
      expect(settings.voiceId, 'default');
      expect(settings.playAdhan, isTrue);
      expect(settings.stopWhenFlipped, isTrue);
    });

    test('keeps what was saved', () async {
      final repository = LocalAdhanRepository(SharedPreferencesAsync());
      await repository.save(
        const AdhanSettings(
          voiceId: 'madinah',
          playAdhan: false,
          stopWhenFlipped: false,
        ),
      );
      final back = await LocalAdhanRepository(SharedPreferencesAsync()).load();
      expect(back.voiceId, 'madinah');
      expect(back.playAdhan, isFalse);
      expect(back.stopWhenFlipped, isFalse);
    });
  });

  test('copyWith changes only what it is given', () {
    const settings = AdhanSettings(voiceId: 'x');
    expect(settings.copyWith(playAdhan: false).voiceId, 'x');
    expect(settings.copyWith(voiceId: 'y').playAdhan, isTrue);
  });

  group('taps on the adhan notice', () {
    test('the one that opened the app comes first, then later taps', () async {
      final platform = FakeAdhanPlatform(launch: 'prayer:times');
      final container = ProviderContainer(
        overrides: [adhanPlatformProvider.overrideWithValue(platform)],
      );
      addTearDown(container.dispose);
      final seen = <String>[];
      container.listen(
        adhanTapsProvider,
        (_, next) => next.whenData((tap) => seen.add(tap.payload)),
        fireImmediately: true,
      );
      await pumpEventQueue();
      platform.tapController.add('prayer:times');
      await pumpEventQueue();
      expect(seen, ['prayer:times', 'prayer:times']);
    });

    test('nothing opens when the app was not started by it', () async {
      final container = ProviderContainer(
        overrides: [
          adhanPlatformProvider.overrideWithValue(FakeAdhanPlatform()),
        ],
      );
      addTearDown(container.dispose);
      final seen = <String>[];
      container.listen(
        adhanTapsProvider,
        (_, next) => next.whenData((tap) => seen.add(tap.payload)),
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(seen, isEmpty);
    });
  });
}
