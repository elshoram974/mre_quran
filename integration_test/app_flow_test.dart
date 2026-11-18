import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/app/shell/expanding_nav_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/mushaf/application/svg_page_providers.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/book_flip.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_page_view.dart';
import 'package:mre_quran/features/mushaf/presentation/offline_packs_section.dart';
import 'package:mre_quran/features/mushaf/presentation/svg_page_view.dart';
import 'package:mre_quran/features/quran_index/presentation/index_tiles.dart';
import 'package:mre_quran/features/quran_index/presentation/quran_index_page.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/main.dart' as app;

/// The app as a reader uses it, on a device: open the Mushaf, turn pages,
/// find a surah, change the display, and look at the offline download. Run
/// it online and again with the device in airplane mode; it must pass both
/// ways. Run in profile mode:
/// `fvm flutter drive --no-dds --profile
///  --driver=test_driver/perf_driver.dart
///  --target=integration_test/app_flow_test.dart -d DEVICE_ID`
/// To check an uncached page offline, disable the device's network and add
/// `--dart-define=FLOW_PAGE=200 --dart-define=FLOW_EXPECT_UNCACHED=true`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the main reading flow works, online or not', (tester) async {
    // The app installs its own error handlers; keep the test's, so a failed
    // expectation fails the test instead of being logged as a crash.
    final testErrors = FlutterError.onError;
    await app.main();
    FlutterError.onError = testErrors;

    /// Lets the app run for [time]. Not `pumpAndSettle`: a page that is
    /// still loading shimmers for as long as it loads.
    Future<void> run([Duration time = const Duration(seconds: 1)]) async {
      const frame = Duration(milliseconds: 100);
      for (var spent = Duration.zero; spent < time; spent += frame) {
        await tester.pump(frame);
      }
    }

    await run(const Duration(seconds: 6));
    if (find.byType(BookFlip).evaluate().isEmpty) {
      final readerTab = find
          .descendant(
            of: find.byType(ExpandingNavBar),
            matching: find.byType(InkWell),
          )
          .first;
      await tester.tapAt(tester.getCenter(readerTab, warnIfMissed: false));
      await run(const Duration(seconds: 2));
    }
    final book = find.byType(BookFlip);
    expect(book, findsOneWidget, reason: 'the Mushaf opens');
    final container = ProviderScope.containerOf(tester.element(book));
    final originalSettings = container.read(settingsProvider).value!;
    final originalPage = await container.read(readingPositionProvider.future);
    int page() => container.read(readingPositionProvider).value!;
    Future<void> settings(AppSettings Function(AppSettings) change) async {
      final now = container.read(settingsProvider).value!;
      await container.read(settingsProvider.notifier).save(change(now));
      await run(const Duration(seconds: 2));
    }

    try {
      // Start from a known place, in the printed Mushaf, sliding pages.
      await settings(
        (s) => s.copyWith(
          readerMode: ReaderMode.printed,
          realisticPageTurn: false,
          mushafEdition: MushafEditions.hafs,
        ),
      );
      const startPage = int.fromEnvironment('FLOW_PAGE', defaultValue: 50);
      if (const bool.fromEnvironment('FLOW_EXPECT_UNCACHED')) {
        final cached = await container
            .read(svgPageStoreProvider(MushafEditions.hafs))
            .isOnDevice(startPage);
        expect(cached, isFalse, reason: 'the offline page must start uncached');
      }
      await container.read(readingPositionProvider.notifier).setPage(startPage);
      await run(const Duration(seconds: 3));
      // The first uncached printed page may offer the offline pack.
      if (find.text('لاحقًا').evaluate().isNotEmpty) {
        await tester.tap(find.text('لاحقًا'));
        await run();
      }
      expect(page(), startPage);

      // The page shows: as artwork, or, offline and not yet on the device, as
      // text. Never an error.
      bool pageShows() =>
          find.byType(SvgPageView).hitTestable().evaluate().isNotEmpty &&
          find.textContaining('تعذّر تحميل').evaluate().isEmpty;
      expect(pageShows(), isTrue);

      // A drag to the right turns forward, to the left back.
      await tester.timedDrag(
        book,
        const Offset(320, 0),
        const Duration(milliseconds: 350),
      );
      await run(const Duration(seconds: 2));
      expect(page(), startPage + 1);
      await tester.timedDrag(
        book,
        const Offset(-320, 0),
        const Duration(milliseconds: 350),
      );
      await run(const Duration(seconds: 2));
      expect(page(), startPage);

      // Realistic turning turns the same way.
      await settings((s) => s.copyWith(realisticPageTurn: true));
      await tester.timedDrag(
        book,
        const Offset(320, 0),
        const Duration(milliseconds: 500),
      );
      await run(const Duration(seconds: 2));
      expect(page(), startPage + 1);
      expect(pageShows(), isTrue);

      // The index finds a surah and opens its page.
      if (find.byTooltip('الفهرس').hitTestable().evaluate().isEmpty) {
        await tester.tapAt(tester.getCenter(book));
        await run();
      }
      await tester.tap(find.byTooltip('الفهرس').hitTestable().first);
      await run(const Duration(seconds: 2));
      expect(find.byType(QuranIndexPage), findsOneWidget, reason: 'index open');
      final field = find.descendant(
        of: find.byType(QuranIndexPage),
        matching: find.byType(EditableText),
      );
      // Typed through the test's own keyboard, not the device's.
      tester.testTextInput.register();
      await tester.tap(field);
      await run();
      await tester.enterText(field, '36');
      await run();
      final yaSin = find.byWidgetPredicate(
        (widget) => widget is SurahTile && widget.surah.number == 36,
      );
      expect(yaSin.hitTestable(), findsOneWidget, reason: 'search found it');
      await tester.tap(yaSin);
      await run(const Duration(seconds: 3));
      expect(page(), 440);

      // The typeset text reads the same place.
      await settings((s) => s.copyWith(readerMode: ReaderMode.text));
      expect(find.byType(MushafPageView).hitTestable(), findsOneWidget);
      await settings((s) => s.copyWith(readerMode: ReaderMode.printed));
      expect(page(), 440);

      // Settings lists the offline download of every reading, with its state.
      // The tab bar hides with the reader's bars; go there as a tab does.
      GoRouter.of(tester.element(book)).go(AppRoute.settings.path);
      await run(const Duration(seconds: 2));
      await tester.scrollUntilVisible(
        find.byWidgetPredicate(
          (widget) =>
              widget is PackTile && widget.edition == MushafEditions.douri,
        ),
        300,
        scrollable: find.byType(Scrollable).hitTestable().first,
      );
      await run(const Duration(seconds: 3));
      expect(find.byType(PackTile, skipOffstage: false), findsNWidgets(5));
      expect(find.text('تعذّرت قراءة حالة التحميل'), findsNothing);
    } finally {
      await container.read(settingsProvider.notifier).save(originalSettings);
      await container
          .read(readingPositionProvider.notifier)
          .setPage(originalPage);
    }
  });
}
