import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/app/quran_app.dart';
import 'package:mre_quran/features/settings/presentation/settings_controller.dart';
import 'helpers/memory_settings_repository.dart';

void main() {
  for (final width in [320.0, 600.0, 839.0, 840.0, 1200.0]) {
    testWidgets('Arabic navigation and theme at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = MemorySettingsRepository();
      final settings = SettingsController(repository);
      addTearDown(settings.dispose);
      await tester.pumpWidget(QuranApp(settings: settings));
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.byType(Scaffold))),
        TextDirection.rtl,
      );
      expect(
        find.byType(NavigationBar),
        width < 600 ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(NavigationRail),
        width < 600 ? findsNothing : findsOneWidget,
      );
      await tester.tap(find.text('العلامات'));
      await tester.pumpAndSettle();
      expect(find.text('لا توجد علامات محفوظة'), findsOneWidget);
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<ThemeMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('داكن').last);
      await tester.pumpAndSettle();
      expect(repository.mode, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.dark,
      );
      tester.view.physicalSize = const Size(1000, 800);
      await tester.pumpAndSettle();
      expect(find.text('المظهر'), findsOneWidget);
      expect(settings.themeMode, ThemeMode.dark);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Large Arabic text fits a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final settings = SettingsController(MemorySettingsRepository());
    addTearDown(settings.dispose);
    await tester.pumpWidget(QuranApp(settings: settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
