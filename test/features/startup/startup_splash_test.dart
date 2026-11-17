import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/quran_text/domain/quran_text.dart';
import 'package:mre_quran/features/startup/application/startup_providers.dart';
import 'package:mre_quran/features/startup/presentation/reader_painted_mark.dart';
import 'package:mre_quran/features/startup/presentation/startup_splash.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

void main() {
  /// The splash over a screen, with the text read when [text] completes,
  /// opening on [location].
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required Completer<QuranText> text,
    String location = '/reader',
    bool reduceMotion = false,
  }) async {
    final container = ProviderContainer(
      overrides: [
        quranTextProvider.overrideWith((ref) => text.future),
        initialLocationProvider.overrideWithValue(location),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: appLocalizationsDelegates,
            home: StartupSplash(child: Text('screen')),
          ),
        ),
      ),
    );
    return container;
  }

  final name = find.text('مصحفي');

  testWidgets('stays until the text is read and the page is on screen, '
      'then fades away', (tester) async {
    final text = Completer<QuranText>();
    final container = await pump(tester, text: text);
    expect(AppRoute.reader.path, '/reader');
    await tester.pump(const Duration(seconds: 1));
    expect(name, findsOneWidget);
    // The screen is built underneath all along.
    expect(find.text('screen'), findsOneWidget);

    text.completeError(StateError('no text'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(name, findsOneWidget, reason: 'the page is not on screen yet');

    container.read(readerPaintedProvider.notifier).painted();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(name, findsNothing);
    expect(find.text('screen'), findsOneWidget);
  });

  testWidgets('a screen other than the Mushaf waits only for the text, and '
      'never less than the least time', (tester) async {
    final text = Completer<QuranText>();
    await pump(tester, text: text, location: '/prayer');
    text.completeError(StateError('none'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(name, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(name, findsNothing);
  });

  testWidgets('gives way after the longest wait, whatever is still loading', (
    tester,
  ) async {
    await pump(tester, text: Completer<QuranText>(), reduceMotion: true);
    await tester.pump(const Duration(seconds: 3));
    expect(name, findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(name, findsNothing);
  });

  testWidgets('a page view marks the reader painted once it has faded in', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ReaderPaintedMark(child: SizedBox()),
      ),
    );
    expect(container.read(readerPaintedProvider), isFalse);
    // Once the page has faded in over its placeholder.
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(readerPaintedProvider), isTrue);
  });
}
