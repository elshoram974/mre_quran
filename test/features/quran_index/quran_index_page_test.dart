import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_index/presentation/quran_index_page.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/memory_settings_repository.dart';

Future<void> _pumpIndex(
  WidgetTester tester, {
  String locale = 'ar',
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.push<int>('/index'),
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(
        path: '/index',
        builder: (context, state) => const QuranIndexPage(),
      ),
    ],
  );
  final container = ProviderContainer(
    overrides: [
      quranMetadataSourceProvider.overrideWithValue(FakeQuranMetadataSource()),
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
}

void main() {
  testWidgets('lists surahs in Arabic and filters by search', (tester) async {
    await _pumpIndex(tester);
    expect(find.text('الفاتحة'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'بقره');
    await tester.pumpAndSettle();
    expect(find.text('البقرة'), findsOneWidget);
    expect(find.text('الفاتحة'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد نتائج'), findsOneWidget);
  });

  testWidgets('switches to the juz list', (tester) async {
    await _pumpIndex(tester);
    await tester.tap(find.text('الأجزاء'));
    await tester.pumpAndSettle();
    expect(find.text('الجزء ٢'), findsOneWidget);
  });

  testWidgets('English, large text, and a narrow screen do not overflow', (
    tester,
  ) async {
    await _pumpIndex(tester, locale: 'en', width: 320, textScale: 2);
    expect(find.text('Index'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
