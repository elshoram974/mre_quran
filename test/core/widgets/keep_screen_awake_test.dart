import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/widgets/keep_screen_awake.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

class _FakeWakelock extends WakelockPlusPlatformInterface {
  bool on = false;

  @override
  Future<void> toggle({required bool enable}) async => on = enable;

  @override
  Future<bool> get enabled async => on;
}

Widget _guards({required bool reader, required bool sheet}) => Column(
  textDirection: TextDirection.rtl,
  children: [
    KeepScreenAwake(enabled: reader, child: const SizedBox()),
    if (sheet) const KeepScreenAwake(child: SizedBox()),
  ],
);

void main() {
  late _FakeWakelock fake;
  late WakelockPlusPlatformInterface original;

  setUp(() {
    original = wakelockPlusPlatformInstance;
    fake = _FakeWakelock();
    wakelockPlusPlatformInstance = fake;
  });
  tearDown(() => wakelockPlusPlatformInstance = original);

  testWidgets('holds the screen on while any guard wants it', (tester) async {
    await tester.pumpWidget(_guards(reader: true, sheet: false));
    expect(fake.on, isTrue);

    // An adhkar sheet opens over the reader, then closes: the reader still
    // wants the screen on.
    await tester.pumpWidget(_guards(reader: true, sheet: true));
    await tester.pumpWidget(_guards(reader: true, sheet: false));
    expect(fake.on, isTrue);

    // Away from the reader, a sheet alone keeps it on until it closes.
    await tester.pumpWidget(_guards(reader: false, sheet: true));
    expect(fake.on, isTrue);
    await tester.pumpWidget(_guards(reader: false, sheet: false));
    expect(fake.on, isFalse);
  });

  testWidgets('lets go in the background and takes it back on resume', (
    tester,
  ) async {
    await tester.pumpWidget(_guards(reader: false, sheet: true));
    expect(fake.on, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(fake.on, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(fake.on, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(fake.on, isFalse);
  });
}
