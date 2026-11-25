import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/app/shell/expanding_nav_bar.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/book_flip.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/main.dart' as app;

/// Frame timing of turning the printed Mushaf's pages, one report per way of
/// turning. Run with:
/// `flutter drive --no-dds --profile
///  --driver=test_driver/perf_driver.dart
///  --target=integration_test/reader_perf_test.dart -d DEVICE_ID`
///
/// The device needs the pages around the reading position on it (or a
/// connection to fetch them in the warm-up pass).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('turning pages stays smooth', (tester) async {
    // The app installs its own error handlers; keep the test's, so a failed
    // expectation fails the test instead of being logged as a crash.
    final testErrors = FlutterError.onError;
    await app.main();
    FlutterError.onError = testErrors;

    /// Lets the app run for [time]. Not `pumpAndSettle`: a page that is
    /// still loading shimmers for as long as it loads.
    Future<void> run(Duration time) async {
      const frame = Duration(milliseconds: 100);
      for (var spent = Duration.zero; spent < time; spent += frame) {
        await tester.pump(frame);
      }
    }

    await run(const Duration(seconds: 6));
    final nav = find.byType(ExpandingNavBar);
    if (tester.widget<ExpandingNavBar>(nav).index != 0) {
      final readerTab = find
          .descendant(of: nav, matching: find.byType(InkWell))
          .first;
      await tester.tapAt(tester.getCenter(readerTab, warnIfMissed: false));
      await run(const Duration(seconds: 3));
    }
    if (find.text('لاحقًا').evaluate().isNotEmpty) {
      await tester.tap(find.text('لاحقًا'));
      await run(const Duration(seconds: 1));
    }
    final book = find.byType(BookFlip);
    expect(book, findsOneWidget, reason: 'the reader is open');
    final container = ProviderScope.containerOf(tester.element(book));
    final original = container.read(settingsProvider).value!;
    final originalPage = await container.read(readingPositionProvider.future);

    await container
        .read(settingsProvider.notifier)
        .save(original.copyWith(readerMode: ReaderMode.printed));
    await container.read(readingPositionProvider.notifier).setPage(50);
    await run(const Duration(seconds: 2));
    if (find.text('لاحقًا').evaluate().isNotEmpty) {
      await tester.tap(find.text('لاحقًا'));
      await run(const Duration(seconds: 1));
    }

    Future<void> realistic(bool on) async {
      final settings = container.read(settingsProvider).value!;
      await container
          .read(settingsProvider.notifier)
          .save(
            settings.copyWith(
              pageTurn: on ? PageTurnStyle.realistic : PageTurnStyle.slide,
            ),
          );
      await run(const Duration(seconds: 1));
    }

    /// Turns [count] pages: forward with a drag to the right, as the Mushaf
    /// opens right to left.
    Future<void> turn(int count, {required bool forward}) async {
      for (var i = 0; i < count; i++) {
        final previous = container.read(readingPositionProvider).value!;
        await tester.timedDrag(
          book,
          Offset(forward ? 320 : -320, 0),
          const Duration(milliseconds: 350),
        );
        await run(const Duration(milliseconds: 1200));
        expect(
          container.read(readingPositionProvider).value,
          previous + (forward ? 1 : -1),
        );
      }
    }

    const turns = 6;
    final phases = <String, Future<void> Function()>{
      'reader_slide_forward': () async {
        await realistic(false);
        await turn(turns, forward: true);
      },
      'reader_slide_back': () => turn(turns, forward: false),
      'reader_book_forward': () async {
        await realistic(true);
        await turn(turns, forward: true);
      },
      'reader_book_back': () => turn(turns, forward: false),
    };

    // First pass fetches and prepares the pages; only the second is measured.
    try {
      for (final phase in phases.values) {
        await phase();
      }
      for (final entry in phases.entries) {
        await binding.traceAction(entry.value, reportKey: entry.key);
      }
    } finally {
      await container.read(settingsProvider.notifier).save(original);
      await container
          .read(readingPositionProvider.notifier)
          .setPage(originalPage);
    }
  });
}
