import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_index/domain/reader_destination.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/quran_text/presentation/quran_search_page.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';
import '../../helpers/memory_settings_repository.dart';

Future<List<ReaderDestination?>> _pumpSearch(
  WidgetTester tester, {
  String locale = 'ar',
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final popped = <ReaderDestination?>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () async =>
                popped.add(await context.push<ReaderDestination>('/search')),
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const QuranSearchPage(),
      ),
    ],
  );
  final container = ProviderContainer(
    overrides: [
      quranMetadataSourceProvider.overrideWithValue(FakeQuranMetadataSource()),
      quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
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
        child: MaterialApp.router(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return popped;
}

void main() {
  testWidgets('shows a prompt before typing', (tester) async {
    await _pumpSearch(tester);
    expect(find.text('ابحث عن سورة أو آية أو كلمات'), findsOneWidget);
  });

  testWidgets('a reference jumps to its ayah and returns its page', (
    tester,
  ) async {
    final popped = await _pumpSearch(tester);
    await tester.enterText(find.byType(TextField), 'البقرة 255');
    await tester.pumpAndSettle();
    expect(find.text('انتقال مباشر'), findsOneWidget);
    expect(find.text('البقرة · آية ٢٥٥'), findsOneWidget);
    await tester.tap(find.text('البقرة · آية ٢٥٥'));
    await tester.pumpAndSettle();
    expect(popped, [const ReaderDestination(page: 42, ayah: AyahRef(2, 255))]);
  });

  testWidgets('words without tashkeel list text results with a count', (
    tester,
  ) async {
    await _pumpSearch(tester);
    await tester.enterText(find.byType(TextField), 'الحمد لله رب العالمين');
    await tester.pumpAndSettle();
    expect(find.textContaining('نتائج النص'), findsOneWidget);
    expect(find.text('الفاتحة · آية ٢'), findsOneWidget);
  });

  testWidgets('a page number opens that page', (tester) async {
    final popped = await _pumpSearch(tester);
    await tester.enterText(find.byType(TextField), 'صفحة 300');
    await tester.pumpAndSettle();
    expect(find.text('صفحة ٣٠٠'), findsWidgets);
    await tester.tap(find.text('صفحة ٣٠٠').first);
    await tester.pumpAndSettle();
    expect(popped, [const ReaderDestination(page: 300)]);
  });

  testWidgets('no match shows the empty state', (tester) async {
    await _pumpSearch(tester);
    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد نتائج'), findsOneWidget);
  });

  testWidgets('English, large text, and a narrow screen do not overflow', (
    tester,
  ) async {
    await _pumpSearch(tester, locale: 'en', width: 320, textScale: 2);
    await tester.enterText(find.byType(TextField), 'الله');
    await tester.pumpAndSettle();
    expect(find.textContaining('Results in the text'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
