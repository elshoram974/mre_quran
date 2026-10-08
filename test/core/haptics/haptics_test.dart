import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/haptics/haptics.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';

class _Recorder implements HapticsBackend {
  final List<String> calls = [];

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<void> select() async => calls.add('select');

  @override
  Future<void> tick() async => calls.add('tick');

  @override
  Future<void> step() async => calls.add('step');

  @override
  Future<void> celebrate() async => calls.add('celebrate');
}

void main() {
  final original = Haptics.backend;
  late _Recorder recorder;

  setUp(() {
    recorder = _Recorder();
    Haptics.backend = recorder;
    Haptics.enabled = true;
  });

  tearDown(() {
    Haptics.backend = original;
    Haptics.enabled = true;
  });

  test('each function reaches its own kind of feedback', () async {
    await Haptics.select();
    await Haptics.tick();
    await Haptics.step();
    await Haptics.celebrate();
    expect(recorder.calls, ['select', 'tick', 'step', 'celebrate']);
  });

  test('nothing is felt when the person turned vibration off', () async {
    Haptics.enabled = false;
    await Haptics.select();
    await Haptics.tick();
    await Haptics.step();
    await Haptics.celebrate();
    expect(recorder.calls, isEmpty);
    Haptics.enabled = true;
    await Haptics.tick();
    expect(recorder.calls, ['tick']);
  });

  test('vibration is on by default and the setting can turn it off', () {
    expect(const AppSettings().hapticsEnabled, isTrue);
    expect(
      const AppSettings().copyWith(hapticsEnabled: false).hapticsEnabled,
      isFalse,
    );
  });
}
