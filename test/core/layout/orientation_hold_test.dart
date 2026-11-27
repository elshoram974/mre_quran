import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/layout/orientation_hold.dart';

const _portrait = [DeviceOrientation.portraitUp];
const _landscape = [
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];
const _askedPortrait = ['DeviceOrientation.portraitUp'];
const _askedLandscape = [
  'DeviceOrientation.landscapeLeft',
  'DeviceOrientation.landscapeRight',
];
const _appsOwn = <Object?>[];

/// What the app asked the system for, each time it asked.
final List<Object?> _asked = [];

void _listen(TestWidgetsFlutterBinding binding) {
  _asked.clear();
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        _asked.add(call.arguments);
      }
      return null;
    },
  );
  addTearDown(
    () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('OrientationHolds', () {
    test('asks nothing until somebody holds the screen, and not twice for '
        'the same thing', () {
      _listen(binding);
      final holds = OrientationHolds();
      final reader = Object();
      holds.hold(reader, const []);
      expect(_asked, isEmpty);
      holds.hold(reader, _landscape);
      holds.hold(reader, _landscape);
      expect(_asked, [_askedLandscape]);
      holds.hold(reader, const []);
      holds.hold(reader, const []);
      expect(_asked, [_askedLandscape, _appsOwn]);
    });

    test('the newest holder is the one asked for, and letting go gives the '
        'screen back to whoever still holds it', () {
      _listen(binding);
      final holds = OrientationHolds();
      final reader = Object();
      final qibla = Object();
      holds.hold(reader, _landscape);
      holds.hold(qibla, _portrait);
      expect(_asked.last, _askedPortrait);
      // The older one saying the same thing again does not take it back.
      holds.hold(reader, _landscape);
      expect(_asked.last, _askedPortrait);
      holds.hold(qibla, const []);
      expect(_asked.last, _askedLandscape);
      holds.hold(reader, const []);
      expect(_asked.last, _appsOwn);
      expect(_asked, [
        _askedLandscape,
        _askedPortrait,
        _askedLandscape,
        _appsOwn,
      ]);
    });

    test('one page leaving and another arriving end the same way whichever '
        'speaks first', () {
      for (final readerFirst in [true, false]) {
        _listen(binding);
        final holds = OrientationHolds();
        final reader = Object();
        final qibla = Object();
        holds.hold(reader, _landscape);
        // The Qibla page covers the reader.
        if (readerFirst) {
          holds.hold(reader, const []);
          holds.hold(qibla, _portrait);
        } else {
          holds.hold(qibla, _portrait);
          holds.hold(reader, const []);
        }
        expect(_asked.last, _askedPortrait, reason: 'covered, $readerFirst');
        // And leaves it again.
        if (readerFirst) {
          holds.hold(reader, _landscape);
          holds.hold(qibla, const []);
        } else {
          holds.hold(qibla, const []);
          holds.hold(reader, _landscape);
        }
        expect(_asked.last, _askedLandscape, reason: 'back, $readerFirst');
      }
    });

    test('a holder that changes its mind is asked for anew', () {
      _listen(binding);
      final holds = OrientationHolds();
      final reader = Object();
      holds.hold(reader, _landscape);
      holds.hold(reader, _portrait);
      expect(_asked, [_askedLandscape, _askedPortrait]);
    });
  });

  group('OrientationHoldScope', () {
    Future<void> pump(
      WidgetTester tester,
      ValueNotifier<bool> inSight, {
      List<DeviceOrientation> orientations = _portrait,
    }) => tester.pumpWidget(
      ProviderScope(
        child: ValueListenableBuilder(
          valueListenable: inSight,
          builder: (_, visible, _) => TickerMode(
            enabled: visible,
            child: OrientationHoldScope(
              orientations: orientations,
              child: const SizedBox(),
            ),
          ),
        ),
      ),
    );

    testWidgets('holds the screen while its page is in sight, lets go when '
        'it is covered, and when it is gone', (tester) async {
      _listen(tester.binding);
      final inSight = ValueNotifier(true);
      await pump(tester, inSight);
      expect(_asked, [_askedPortrait]);

      inSight.value = false;
      await tester.pump();
      expect(_asked, [_askedPortrait, _appsOwn]);

      inSight.value = true;
      await tester.pump();
      expect(_asked, [_askedPortrait, _appsOwn, _askedPortrait]);

      await tester.pumpWidget(const SizedBox());
      expect(_asked, [_askedPortrait, _appsOwn, _askedPortrait, _appsOwn]);
    });

    testWidgets('with nothing to hold it asks nothing, coming or going', (
      tester,
    ) async {
      _listen(tester.binding);
      await pump(tester, ValueNotifier(true), orientations: const []);
      await tester.pumpWidget(const SizedBox());
      expect(_asked, isEmpty);
    });
  });

  group('canHoldOrientation', () {
    Future<bool> ask(WidgetTester tester, Size screen, {Size? window}) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = window ?? screen;
      tester.view.display.size = screen;
      addTearDown(tester.view.reset);
      addTearDown(tester.view.display.reset);
      late bool can;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              can = canHoldOrientation(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return can;
    }

    testWidgets('a phone is held as the app asks, upright or sideways', (
      tester,
    ) async {
      expect(await ask(tester, const Size(390, 844)), isTrue);
      expect(await ask(tester, const Size(844, 390)), isTrue);
    });

    testWidgets('a tablet turns only with the device, and so does an iPad '
        'that gives the app a phone-sized window', (tester) async {
      expect(await ask(tester, const Size(820, 1180)), isFalse);
      expect(
        await ask(tester, const Size(820, 1180), window: const Size(375, 1180)),
        isFalse,
      );
    });
  });
}
