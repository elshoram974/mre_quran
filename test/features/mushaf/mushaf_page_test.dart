import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/application/reader_immersive_provider.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_page.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';
import '../../helpers/memory_reading_position_repository.dart';
import '../../helpers/memory_settings_repository.dart';

Future<(ProviderContainer, MemoryReadingPositionRepository)> _pump(
  WidgetTester tester, {
  int? savedPage,
  String locale = 'ar',
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final positions = MemoryReadingPositionRepository()..page = savedPage;
  final container = ProviderContainer(
    overrides: [
      quranMetadataSourceProvider.overrideWithValue(FakeQuranMetadataSource()),
      quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
      readingPositionRepositoryProvider.overrideWithValue(positions),
      settingsRepositoryProvider.overrideWithValue(
        MemorySettingsRepository()..settings = AppSettings(localeCode: locale),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: MushafPage()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container, positions);
}

void main() {
  testWidgets('opens at page 1 with Al-Fatiha and the bar actions', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('سورة الفاتحة'), findsWidgets);
    expect(find.byTooltip('الفهرس'), findsOneWidget);
    expect(find.byTooltip('ابحث في القرآن'), findsOneWidget);
    expect(find.byTooltip('العرض'), findsOneWidget);
  });

  testWidgets('opens at the saved page', (tester) async {
    await _pump(tester, savedPage: 42);
    expect(find.textContaining('صفحة ٤٢'), findsWidgets);
  });

  testWidgets('swiping turns the page right to left and saves it', (
    tester,
  ) async {
    final (_, positions) = await _pump(tester);
    // In a right-to-left Mushaf the next page comes from the left.
    await tester.fling(find.byType(PageView), const Offset(400, 0), 1500);
    await tester.pumpAndSettle();
    expect(positions.page, 2);
    expect(find.text('سورة البقرة'), findsWidgets);
  });

  testWidgets('a page change made elsewhere moves the pager', (tester) async {
    final (container, _) = await _pump(tester);
    await container.read(readingPositionProvider.notifier).setPage(604);
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحة ٦٠٤'), findsWidgets);
  });

  testWidgets('a tap hides the bar and another brings it back', (tester) async {
    final (container, _) = await _pump(tester);
    await tester.tapAt(const Offset(195, 500));
    await tester.pumpAndSettle();
    expect(container.read(readerImmersiveProvider), isTrue);
    expect(find.byTooltip('الفهرس'), findsNothing);
    await tester.tapAt(const Offset(195, 500));
    await tester.pumpAndSettle();
    expect(find.byTooltip('الفهرس'), findsOneWidget);
  });

  testWidgets('English, large text, narrow width, and long pages do not '
      'overflow', (tester) async {
    await _pump(tester, locale: 'en', width: 320, textScale: 2, savedPage: 50);
    expect(tester.takeException(), isNull);
  });
}
