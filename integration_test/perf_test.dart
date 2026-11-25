import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/app/shell/expanding_nav_bar.dart';
import 'package:mre_quran/app/quran_app.dart';
import 'package:mre_quran/core/hints/hints.dart';
import 'package:mre_quran/core/widgets/app_select_field.dart';
import 'package:mre_quran/features/quran_index/presentation/quran_index_page.dart';
import 'package:mre_quran/main.dart' as app;

/// Frame-timing scenarios, one report per phase. Run with:
/// `flutter drive --no-dds --profile
///  --driver=test_driver/perf_driver.dart
///  --target=integration_test/perf_test.dart -d DEVICE_ID`
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tabs, sheets, and index stay smooth', (tester) async {
    debugProfileBuildsEnabled = true;
    debugProfilePaintsEnabled = true;
    final testErrorHandler = FlutterError.onError;
    await app.main();
    FlutterError.onError = testErrorHandler;
    // Wait for the bounded startup overlay before exercising controls.
    await tester.pump();
    final brand = find.image(const AssetImage('assets/brand/splash_brand.png'));
    for (var i = 0; i < 20 && brand.evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(brand, findsNothing);
    await ProviderScope.containerOf(tester.element(find.byType(QuranApp)))
        .read(hintsProvider.notifier)
        .take(AppHint.configureAdhan);
    await tester.pumpAndSettle();
    // A first run may offer the offline Mushaf before the reader is used.
    if (find.text('لاحقًا').evaluate().isNotEmpty) {
      await tester.tap(find.text('لاحقًا'));
      await tester.pumpAndSettle();
    }
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

    Future<void> tapText(String text) async {
      await tester.tap(find.text(text).first);
      await tester.pumpAndSettle();
    }

    Future<void> tapTab(int index) async {
      final tabs = find.descendant(
        of: find.byType(ExpandingNavBar),
        matching: find.byType(InkWell),
      );
      await tester.tapAt(tester.getCenter(tabs.at(index), warnIfMissed: false));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ExpandingNavBar>(find.byType(ExpandingNavBar)).index,
        index,
      );
    }

    // The pages reached from the prayer times and the settings, opened by
    // their routes, as a tap on their tile does.
    GoRouter router() =>
        GoRouter.of(tester.element(find.byType(Scaffold).first));
    Future<void> openPage(AppRoute route, {bool scroll = false}) async {
      unawaited(router().push<void>(route.path));
      await tester.pumpAndSettle();
      if (scroll) {
        final list = find.byType(Scrollable).last;
        await tester.fling(list, const Offset(0, -1500), 3000);
        await tester.pumpAndSettle();
        await tester.fling(list, const Offset(0, 1500), 3000);
        await tester.pumpAndSettle();
      }
      router().pop();
      await tester.pumpAndSettle();
    }

    final phases = <String, Future<void> Function()>{
      'adhan_page': () => openPage(AppRoute.adhan, scroll: true),
      'tuning_page': () => openPage(AppRoute.prayerTuning, scroll: true),
      'iqama_page': () => openPage(AppRoute.iqama),
      'reminders_page': () => openPage(AppRoute.reminders, scroll: true),
      'tabs': () async {
        for (final tab in [1, 2, 3, 0]) {
          await tapTab(tab);
        }
      },
      'sheet': () async {
        await tapTab(3);
        await tester.tap(find.byType(AppSelectField<String>).first);
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(20, 120));
        await tester.pumpAndSettle();
        await tapTab(0);
      },
      'index_open': () async {
        if (find.byTooltip('الفهرس').hitTestable().evaluate().isEmpty) {
          await tester.tapAt(tester.getCenter(find.byType(Scaffold).first));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byTooltip('الفهرس').hitTestable().first);
        await tester.pumpAndSettle();
      },
      'index_scroll': () async {
        final list = find
            .descendant(
              of: find.byType(QuranIndexPage),
              matching: find.byType(Scrollable),
            )
            .last;
        await tester.fling(list, const Offset(0, -2500), 4000);
        await tester.pumpAndSettle();
        await tester.fling(list, const Offset(0, 2500), 4000);
        await tester.pumpAndSettle();
      },
      'index_search': () async {
        await tester.enterText(find.byType(TextField).first, 'بقره');
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, '');
        await tester.pumpAndSettle();
        await tapText('الأجزاء');
      },
      'index_close': () async {
        await tester.tap(find.byIcon(Icons.close).last);
        await tester.pumpAndSettle();
      },
    };

    // `--dart-define=PHASES=adhan_page,tuning_page` runs only those.
    const only = String.fromEnvironment('PHASES');
    if (only.isNotEmpty) {
      final names = only.split(',').toSet();
      phases.removeWhere((name, _) => !names.contains(name));
    }
    // First pass warms up shaders and caches; only the second is measured.
    for (final phase in phases.values) {
      await phase();
    }
    for (final entry in phases.entries) {
      await binding.traceAction(entry.value, reportKey: entry.key);
    }
  });
}
