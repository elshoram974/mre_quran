import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mre_quran/app/shell/expanding_nav_bar.dart';
import 'package:mre_quran/core/widgets/app_select_field.dart';
import 'package:mre_quran/features/quran_index/presentation/quran_index_page.dart';
import 'package:mre_quran/main.dart' as app;

/// Frame-timing scenarios, one report per phase. Run with:
/// `fvm flutter drive --no-dds --profile
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

    final phases = <String, Future<void> Function()>{
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
        if (find.byTooltip('الفهرس').evaluate().isEmpty) {
          await tester.tapAt(tester.getCenter(find.byType(Scaffold).first));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byTooltip('الفهرس'));
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

    // First pass warms up shaders and caches; only the second is measured.
    for (final phase in phases.values) {
      await phase();
    }
    for (final entry in phases.entries) {
      await binding.traceAction(entry.value, reportKey: entry.key);
    }
  });
}
