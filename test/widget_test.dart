import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/app/quran_app.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';

import 'helpers/memory_settings_repository.dart';

void main() {
  for (final width in [320.0, 600.0, 840.0]) {
    testWidgets('Arabic navigation adapts at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = MemorySettingsRepository();
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const QuranApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        Directionality.of(tester.element(find.byType(Scaffold).first)),
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

      await tester.tap(find.text('العلامات').first);
      await tester.pumpAndSettle();
      expect(find.text('لا توجد علامات بعد'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('English locale uses left-to-right direction', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemorySettingsRepository()
      ..settings = const AppSettings(localeCode: 'en');
    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const QuranApp()),
    );
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.ltr,
    );
    expect(find.text('Verified reader preparation'), findsOneWidget);
  });

  testWidgets('Large Arabic text has no layout exception', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const QuranApp()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
