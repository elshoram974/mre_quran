import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mre_quran/core/widgets/app_select_field.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
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
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    Future<void> tapText(String text) async {
      await tester.tap(find.text(text).first);
      await tester.pumpAndSettle();
    }

    final phases = <String, Future<void> Function()>{
      'tabs': () async {
        for (final tab in ['الأدعية', 'العلامات', 'الإعدادات', 'المصحف']) {
          await tapText(tab);
        }
      },
      'sheet': () async {
        await tapText('الإعدادات');
        await tester.tap(find.byType(AppSelectField<AppThemePreference>));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(20, 120));
        await tester.pumpAndSettle();
        await tapText('المصحف');
      },
      'index_open': () async {
        await tapText('الفهرس');
      },
      'index_scroll': () async {
        final list = find.byType(Scrollable).first;
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
        await tester.tap(find.byType(BackButton));
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
