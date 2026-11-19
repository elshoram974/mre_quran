import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
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
  bool reduceMotion = false,
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
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: MaterialApp.router(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
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
  testWidgets('changing index tabs respects reduced motion', (tester) async {
    await _pumpIndex(tester, reduceMotion: true);
    await tester.tap(find.text('الأجزاء'));
    await tester.pump();
    final tabs = tester.widget<TabBarView>(find.byType(TabBarView)).controller!;
    expect(tabs.index, 1);
    expect(tabs.animation!.value, 1);
    await tester.pumpAndSettle();
    expect(find.text('الجزء ٢'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('lists the hizb under the juz they are halves of', (
    tester,
  ) async {
    await _pumpIndex(tester);
    await tester.tap(find.text('الأحزاب'));
    await tester.pumpAndSettle();
    expect(find.text('الجزء ١'), findsOneWidget);
    expect(find.text('الحزب ١'), findsOneWidget);
    expect(find.text('الحزب ٢'), findsOneWidget);
    expect(find.text('الجزء ٢'), findsOneWidget);
    // The third hizb opens the second juz, in Al-Baqara on page 22.
    expect(find.text('الحزب ٣'), findsOneWidget);
    expect(find.text('يبدأ من البقرة، الآية ١٤٢'), findsOneWidget);
    expect(find.text('صفحة ٢٢'), findsOneWidget);
    // Each heading comes before its hizb.
    expect(
      tester.getTopLeft(find.text('الجزء ٢')).dy,
      greaterThan(tester.getTopLeft(find.text('الحزب ٢')).dy),
    );
    expect(
      tester.getTopLeft(find.text('الجزء ٢')).dy,
      lessThan(tester.getTopLeft(find.text('الحزب ٣')).dy),
    );
  });

  testWidgets('a search in the hizb list finds hizb, without headings', (
    tester,
  ) async {
    await _pumpIndex(tester);
    await tester.tap(find.text('الأحزاب'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '٣');
    await tester.pumpAndSettle();
    expect(find.text('الحزب ٣'), findsOneWidget);
    expect(find.text('الحزب ١'), findsNothing);
    expect(find.text('الجزء ٢'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد نتائج'), findsOneWidget);
  });

  testWidgets('the hizb list reads in English at a narrow width and 2x text', (
    tester,
  ) async {
    await _pumpIndex(tester, locale: 'en', width: 320, textScale: 2);
    await tester.tap(find.text('Hizb'));
    await tester.pumpAndSettle();
    // The numbers keep the app's digit style, here the default Arabic-Indic.
    expect(find.text('Hizb ١'), findsOneWidget);
    expect(find.text('Juz ١'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English, large text, and a narrow screen do not overflow', (
    tester,
  ) async {
    await _pumpIndex(tester, locale: 'en', width: 320, textScale: 2);
    expect(find.text('Index'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tabs and the search stay on screen while a list scrolls', (
    tester,
  ) async {
    await _pumpIndex(tester);
    final search = find.byType(TextField);
    final top = tester.getTopLeft(search).dy;
    await tester.fling(
      find.byType(Scrollable).last,
      const Offset(0, -2000),
      3000,
    );
    await tester.pumpAndSettle();
    expect(find.text('الفاتحة'), findsNothing, reason: 'the list moved');
    expect(search.hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(search).dy, top);
    expect(find.text('الأجزاء').hitTestable(), findsOneWidget);
  });

  testWidgets('a swipe goes from the surahs to the juz and the tab follows', (
    tester,
  ) async {
    await _pumpIndex(tester);
    // The Mushaf's lists run right to left like the app: the next tab is
    // to the left, so a swipe to the right brings it.
    await tester.fling(find.byType(TabBarView), const Offset(300, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('الجزء ٢'), findsOneWidget);
    expect(find.text('الفاتحة'), findsNothing);
  });
}
