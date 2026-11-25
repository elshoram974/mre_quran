import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/mushaf/application/reader_orientation_provider.dart';
import 'package:mre_quran/features/mushaf/presentation/reader_orientation.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

const _landscape = [
  'DeviceOrientation.landscapeLeft',
  'DeviceOrientation.landscapeRight',
];

/// A phone's screen and a tablet's, in logical pixels (the tests draw at one
/// pixel to the point).
const _phone = Size(390, 844);
const _tablet = Size(820, 1180);

/// What the app asked the system for, each time it asked.
final List<Object?> _asked = [];

/// The reader on a [platform] device with a [screen], its window as large
/// as the screen unless [window] is given; [onScreen] is whether the reader
/// is the tab in sight.
Future<ProviderContainer> _pump(
  WidgetTester tester, {
  TargetPlatform platform = TargetPlatform.iOS,
  Size screen = _phone,
  Size? window,
  ValueNotifier<bool>? onScreen,
}) async {
  _asked.clear();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        _asked.add(call.arguments);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = window ?? screen;
  tester.view.display.size = screen;
  addTearDown(tester.view.reset);
  addTearDown(tester.view.display.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final shown = onScreen ?? ValueNotifier(true);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        theme: AppTheme.light.copyWith(platform: platform),
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: shown,
            builder: (_, visible, _) => TickerMode(
              enabled: visible,
              child: const ReaderOrientationScope(
                child: Column(children: [ReaderOrientationTile()]),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

/// Turns the device: the window takes [size].
Future<void> _turn(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  await tester.pump();
}

void main() {
  test('upright asks only for portrait on iOS, which has no upside-down '
      'iPhone, and both ways up on Android', () {
    expect(readerOrientations(ReaderOrientation.portrait, cupertino: true), [
      DeviceOrientation.portraitUp,
    ]);
    expect(readerOrientations(ReaderOrientation.portrait, cupertino: false), [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    for (final cupertino in [true, false]) {
      expect(
        readerOrientations(ReaderOrientation.landscape, cupertino: cupertino),
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
      );
      // Free gives the app back its own orientations.
      expect(
        readerOrientations(ReaderOrientation.free, cupertino: cupertino),
        isEmpty,
      );
    }
  });

  for (final (platform, portrait) in [
    (TargetPlatform.iOS, ['DeviceOrientation.portraitUp']),
    (
      TargetPlatform.android,
      ['DeviceOrientation.portraitUp', 'DeviceOrientation.portraitDown'],
    ),
  ]) {
    testWidgets('on ${platform.name} a phone turns the reader sideways and '
        'back upright', (tester) async {
      await _pump(tester, platform: platform);
      // Nothing is asked until the person turns the reader.
      expect(_asked, isEmpty);
      await tester.tap(find.text('قراءة أفقية'));
      await tester.pump();
      expect(_asked, [_landscape]);

      await _turn(tester, _phone.flipped);
      expect(find.text('قراءة رأسية'), findsOneWidget);
      await tester.tap(find.text('قراءة رأسية'));
      await tester.pump();
      expect(_asked, [_landscape, portrait]);
    });
  }

  testWidgets('leaving the reader gives the app its own orientations back, '
      'and coming back turns the reader again', (tester) async {
    final onScreen = ValueNotifier(true);
    final container = await _pump(tester, onScreen: onScreen);
    container
        .read(readerOrientationProvider.notifier)
        .hold(ReaderOrientation.landscape);
    await tester.pump();
    expect(_asked, [_landscape]);

    // Another tab: the reader stays alive behind it, out of sight.
    onScreen.value = false;
    await tester.pump();
    expect(_asked, [_landscape, <Object?>[]]);

    onScreen.value = true;
    await tester.pump();
    expect(_asked, [_landscape, <Object?>[], _landscape]);
  });

  testWidgets('the reader going away gives the app its own orientations '
      'back', (tester) async {
    final container = await _pump(tester);
    container
        .read(readerOrientationProvider.notifier)
        .hold(ReaderOrientation.landscape);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(_asked, [_landscape, <Object?>[]]);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('a tablet on ${platform.name}, which turns only with the '
        'device, there is no button and nothing is asked', (tester) async {
      final container = await _pump(
        tester,
        platform: platform,
        screen: _tablet,
      );
      expect(find.text('قراءة أفقية'), findsNothing);
      expect(find.text('قراءة رأسية'), findsNothing);
      container
          .read(readerOrientationProvider.notifier)
          .hold(ReaderOrientation.landscape);
      await tester.pump();
      expect(_asked, isEmpty);
    });
  }

  testWidgets('an iPad sharing its screen still cannot be turned, though '
      'its window is a phone\'s width', (tester) async {
    await _pump(tester, screen: _tablet, window: const Size(375, 1180));
    expect(find.text('قراءة أفقية'), findsNothing);
  });
}
