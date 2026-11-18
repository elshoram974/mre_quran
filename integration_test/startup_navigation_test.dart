import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/app/app_shortcuts.dart';
import 'package:mre_quran/app/quran_app.dart';
import 'package:mre_quran/app/reminder_opener.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/app/shell/expanding_nav_bar.dart';
import 'package:mre_quran/core/notifications/reminder_payload.dart';
import 'package:mre_quran/features/adhan/presentation/adhan_page.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_page_view.dart';
import 'package:mre_quran/features/mushaf/presentation/tafsir_sheet.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_times_page.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/main.dart' as app;

/// Exercises the real application across startup, reader, shortcuts and
/// reminder destinations. Native launcher taps need a separate Android test.
/// Run with `fvm flutter drive --no-dds --profile
/// --driver=test_driver/perf_driver.dart
/// --target=integration_test/startup_navigation_test.dart -d DEVICE_ID`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('startup, tafsir, adhkar and prayer navigation work together', (
    tester,
  ) async {
    final testErrors = FlutterError.onError;
    await app.main();
    FlutterError.onError = testErrors;

    Future<void> run([Duration duration = const Duration(seconds: 1)]) async {
      const frame = Duration(milliseconds: 100);
      for (var elapsed = Duration.zero; elapsed < duration; elapsed += frame) {
        await tester.pump(frame);
      }
    }

    await run(const Duration(seconds: 6));
    if (find.text('لاحقًا').evaluate().isNotEmpty) {
      await tester.tap(find.text('لاحقًا'));
      await run();
    }
    expect(find.byType(QuranApp), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/brand/splash_brand.png')),
      findsNothing,
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(QuranApp)),
    );
    final settings = container.read(settingsProvider).value!;
    final position = await container.read(readingPositionProvider.future);
    final router = container.read(routerProvider);
    try {
      await container
          .read(settingsProvider.notifier)
          .save(
            settings.copyWith(localeCode: 'ar', readerMode: ReaderMode.text),
          );
      await container.read(readingPositionProvider.notifier).setPage(1);
      router.go(AppRoute.reader.path);
      await run(const Duration(seconds: 3));
      final reader = find.byType(MushafPageView).hitTestable();
      expect(reader, findsOneWidget);
      final paragraph = find.descendant(
        of: reader,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('ٱلۡحَمۡدُ'),
        ),
      );
      expect(paragraph, findsOneWidget);
      final top = tester.getTopRight(paragraph);
      for (
        var y = 20.0;
        y < 350 && find.text('نسخ الآية').evaluate().isEmpty;
        y += 18
      ) {
        await tester.longPressAt(top + Offset(-90, y));
        await run(const Duration(milliseconds: 200));
      }
      expect(find.text('التفسير'), findsOneWidget);
      await tester.tap(find.text('التفسير'));
      await run(const Duration(seconds: 2));
      expect(find.byType(TafsirSheet), findsOneWidget);
      final pager = find.descendant(
        of: find.byType(TafsirSheet),
        matching: find.byType(PageView),
      );
      final controller = tester.widget<PageView>(pager).controller!;
      final initialPage = controller.page!.round();
      await tester.drag(pager, const Offset(300, 0));
      await run();
      expect(controller.page!.round(), initialPage + 1);
      await tester.binding.handlePopRoute();
      await run();

      // The actual shortcut handler routes to prayer times; the notification
      // payload opens adhan settings on top of it.
      unawaited(AppShortcut.prayerTimes.open(router));
      await run(const Duration(seconds: 2));
      expect(find.byType(PrayerTimesPage).hitTestable(), findsOneWidget);
      unawaited(openReminder(router, ReminderPayload.adhanSettings));
      await run(const Duration(seconds: 2));
      expect(find.byType(AdhanPage).hitTestable(), findsOneWidget);
      await tester.binding.handlePopRoute();
      await run();

      unawaited(openReminder(router, ReminderPayload.forCollection('morning')));
      await run(const Duration(seconds: 3));
      expect(find.textContaining('أذكار الصباح'), findsWidgets);
      expect(find.textContaining('الخطوة'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await run();
      expect(
        tester.widget<ExpandingNavBar>(find.byType(ExpandingNavBar)).index,
        1,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await container.read(settingsProvider.notifier).save(settings);
      await container.read(readingPositionProvider.notifier).setPage(position);
    }
  });
}
