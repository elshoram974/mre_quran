import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/quran_text/domain/quran_text.dart';
import 'package:mre_quran/features/startup/application/launch_hold.dart';
import 'package:mre_quran/features/startup/application/startup_providers.dart';
import 'package:mre_quran/features/startup/presentation/launch_gate.dart';
import 'package:mre_quran/features/startup/presentation/reader_painted_mark.dart';

void main() {
  /// The gate over a screen, holding the first frame for at most [most],
  /// with the text read when [text] completes, opening on [location].
  Future<(ProviderContainer, LaunchHold)> pump(
    WidgetTester tester, {
    required Completer<QuranText> text,
    String location = '/reader',
    Duration most = const Duration(seconds: 4),
    List<String>? reasons,
  }) async {
    final hold = LaunchHold.hold(most: most, onRelease: reasons?.add);
    addTearDown(hold.release);
    final container = ProviderContainer(
      overrides: [
        quranTextProvider.overrideWith((ref) => text.future),
        initialLocationProvider.overrideWithValue(location),
        launchHoldProvider.overrideWithValue(hold),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const Directionality(
          textDirection: TextDirection.rtl,
          child: LaunchGate(child: Text('screen')),
        ),
      ),
    );
    return (container, hold);
  }

  testWidgets('holds the launch screen until the text is read and the page '
      'is on screen, building the screen underneath', (tester) async {
    final text = Completer<QuranText>();
    final (container, hold) = await pump(tester, text: text);
    expect(find.text('screen'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(hold.held, isTrue);

    text.completeError(StateError('no text'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(hold.held, isTrue, reason: 'the page is not on screen yet');

    container.read(readerPaintedProvider.notifier).painted();
    await tester.pump(Duration.zero);
    await tester.pump(Duration.zero);
    expect(hold.held, isFalse);
  });

  testWidgets('a screen other than the Mushaf does not wait for the page', (
    tester,
  ) async {
    final (_, hold) = await pump(
      tester,
      text: Completer<QuranText>(),
      location: '/prayer',
    );
    await tester.pump(Duration.zero);
    expect(hold.held, isFalse);
  });

  testWidgets('lets the launch screen go after its limit, whatever is still '
      'loading, and says so', (tester) async {
    final reasons = <String>[];
    final (_, hold) = await pump(
      tester,
      text: Completer<QuranText>(),
      reasons: reasons,
    );
    await tester.pump(const Duration(seconds: 3));
    expect(hold.held, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(hold.held, isFalse);
    expect(reasons, ['limit']);
  });

  testWidgets('a screen ready in time is let through as ready, once', (
    tester,
  ) async {
    final reasons = <String>[];
    await pump(
      tester,
      text: Completer<QuranText>(),
      location: '/prayer',
      reasons: reasons,
    );
    await tester.pump(Duration.zero);
    await tester.pump(const Duration(seconds: 5));
    expect(reasons, ['ready']);
  });

  testWidgets('a release after the first is ignored', (tester) async {
    final (_, hold) = await pump(
      tester,
      text: Completer<QuranText>(),
      location: '/prayer',
    );
    await tester.pump(Duration.zero);
    expect(hold.held, isFalse);
    hold.release();
    expect(hold.held, isFalse);
  });

  testWidgets('when a notification or widget opens another screen over the '
      'Mushaf, it opens even with the text still loading', (tester) async {
    final (container, hold) = await pump(tester, text: Completer<QuranText>());
    container.read(opensOnReaderProvider.notifier).openedElsewhere();
    await tester.pump(Duration.zero);
    await tester.pump(Duration.zero);
    expect(container.read(readerPaintedProvider), isFalse);
    expect(hold.held, isFalse);
  });

  testWidgets('a page view marks the reader painted on its first frame', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(readerPaintedProvider), isFalse);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ReaderPaintedMark(child: SizedBox()),
      ),
    );
    expect(container.read(readerPaintedProvider), isTrue);
  });
}
