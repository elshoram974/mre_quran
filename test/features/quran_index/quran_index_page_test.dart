import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';
import 'package:mre_quran/features/bookmarks/domain/bookmark.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_index/domain/reader_destination.dart';
import 'package:mre_quran/features/quran_index/presentation/quran_index_page.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';
import '../../helpers/memory_bookmarks_repository.dart';
import '../../helpers/memory_settings_repository.dart';

/// What the index was closed with, by the last [_pumpIndex].
Object? _chosen;

Future<ProviderContainer> _pumpIndex(
  WidgetTester tester, {
  String locale = 'ar',
  double width = 390,
  double textScale = 1,
  bool reduceMotion = false,
  List<Bookmark> bookmarks = const [],
}) async {
  _chosen = null;
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
            onPressed: () async =>
                _chosen = await context.push<Object?>('/index'),
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
      quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
      bookmarksRepositoryProvider.overrideWithValue(
        MemoryBookmarksRepository()..items = [...bookmarks],
      ),
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
        data: MediaQueryData.fromView(tester.view).copyWith(
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
  return container;
}

/// Brings the tab [label] into view and opens it.
Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
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

  testWidgets('the surahs are divided by the juz they begin in', (
    tester,
  ) async {
    await _pumpIndex(tester);
    // Al-Fatiha and Al-Baqara begin in juz 1, Al-Imran in juz 3; no surah
    // begins in juz 2, so it has no heading.
    expect(find.text('الجزء ١'), findsOneWidget);
    expect(find.text('الجزء ٣'), findsOneWidget);
    expect(find.text('الجزء ٢'), findsNothing);
    final first = tester.getTopLeft(find.text('الجزء ١')).dy;
    expect(first, lessThan(tester.getTopLeft(find.text('الفاتحة')).dy));
    expect(
      tester.getTopLeft(find.text('الجزء ٣')).dy,
      greaterThan(tester.getTopLeft(find.text('البقرة')).dy),
    );
    expect(
      tester.getTopLeft(find.text('الجزء ٣')).dy,
      lessThan(tester.getTopLeft(find.text('آل عمران')).dy),
    );
    // A search lists what it finds, with no headings.
    await tester.enterText(find.byType(TextField), 'بقره');
    await tester.pumpAndSettle();
    expect(find.text('البقرة'), findsOneWidget);
    expect(find.text('الجزء ١'), findsNothing);
  });

  testWidgets('lists the sajda ayahs, in order, with their juz', (
    tester,
  ) async {
    await _pumpIndex(tester);
    await tester.ensureVisible(find.text('السجدات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('السجدات'));
    await tester.pumpAndSettle();
    expect(find.text('سجدة الأعراف'), findsOneWidget);
    expect(find.text('الآية ٢٠٦ · الجزء ٩'), findsOneWidget);
    // Al-Hajj has two.
    expect(find.text('سجدة الحج'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('سجدة الأعراف')).dy,
      lessThan(tester.getTopLeft(find.text('سجدة الرعد')).dy),
    );
    await tester.enterText(find.byType(TextField), 'الحج');
    await tester.pumpAndSettle();
    expect(find.text('سجدة الحج'), findsNWidgets(2));
    expect(find.text('سجدة الأعراف'), findsNothing);
  });

  testWidgets('on a narrow screen at 2x text the tabs scroll, and each can '
      'be reached', (tester) async {
    await _pumpIndex(tester, locale: 'en', width: 320, textScale: 2);
    await tester.ensureVisible(find.text('Sajdas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sajdas'));
    await tester.pumpAndSettle();
    expect(find.text('Sajda in الأعراف'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    await tester.ensureVisible(find.text('Hizb'));
    await tester.pumpAndSettle();
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

  testWidgets('the bookmarks are a section of the index; one opens at its '
      'ayah', (tester) async {
    await _pumpIndex(
      tester,
      bookmarks: [
        Bookmark(ref: const AyahRef(2, 255), createdAt: DateTime(2026, 11)),
      ],
    );
    await _openTab(tester, 'العلامات');
    expect(find.text('البقرة · آية ٢٥٥'), findsOneWidget);
    await tester.tap(find.text('البقرة · آية ٢٥٥'));
    await tester.pumpAndSettle();
    expect(_chosen, const ReaderDestination(page: 42, ayah: AyahRef(2, 255)));
  });

  testWidgets('with no bookmarks, the section says how to add one', (
    tester,
  ) async {
    await _pumpIndex(tester);
    await _openTab(tester, 'العلامات');
    expect(find.text('لا توجد علامات بعد'), findsOneWidget);
  });

  testWidgets('every surah says Meccan or Medinan, and the list narrows to '
      'either', (tester) async {
    await _pumpIndex(tester);
    expect(find.text('مكية'), findsWidgets);
    await tester.tap(find.text('مدنية ٢٨'));
    await tester.pumpAndSettle();
    expect(find.text('البقرة'), findsOneWidget);
    expect(find.text('الفاتحة'), findsNothing);
    await tester.tap(find.text('مكية ٨٦'));
    await tester.pumpAndSettle();
    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.text('البقرة'), findsNothing);
    await tester.tap(find.text('الكل'));
    await tester.pumpAndSettle();
    expect(find.text('البقرة'), findsOneWidget);
  });

  testWidgets('by revelation, the surah revealed first leads', (tester) async {
    await _pumpIndex(tester);
    await tester.tap(find.text('حسب النزول'));
    await tester.pumpAndSettle();
    expect(find.text('العلق'), findsOneWidget);
    expect(find.text('ترتيب النزول ١'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('العلق')).dy,
      lessThan(tester.getTopLeft(find.text('الفاتحة')).dy),
    );
    // No juz headings: the juz do not follow each other in this order.
    expect(find.text('الجزء ٣٠'), findsNothing);
  });

  testWidgets(
    'the sheet of a surah tells its place in the revelation, and reads '
    'it',
    (tester) async {
      final container = await _pumpIndex(tester);
      final metadata = await container.read(quranMetadataProvider.future);
      final fatiha = metadata.surah(1);
      String nameAt(int order) => metadata.surahs
          .firstWhere((surah) => surah.revelationOrder == order)
          .arabicName;
      await tester.tap(find.byTooltip('عن سورة الفاتحة'));
      await tester.pumpAndSettle();
      expect(find.text('ترتيبها في النزول'), findsOneWidget);
      expect(
        find.text('سورة ${nameAt(fatiha.revelationOrder - 1)}'),
        findsOneWidget,
      );
      expect(
        find.text('سورة ${nameAt(fatiha.revelationOrder + 1)}'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('اقرأ السورة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('اقرأ السورة'));
      await tester.pumpAndSettle();
      expect(_chosen, const ReaderDestination(page: 1));
    },
  );

  testWidgets('each juz shows the words it begins with', (tester) async {
    final container = await _pumpIndex(tester);
    final text = await container.read(quranTextProvider.future);
    await _openTab(tester, 'الأجزاء');
    final words = text.mushaf(const AyahRef(2, 142)).split(' ');
    expect(find.text('${words.take(4).join(' ')} …'), findsOneWidget);
  });

  testWidgets('the surah rows fit a narrow screen at 2x text', (tester) async {
    await _pumpIndex(tester, width: 320, textScale: 2);
    expect(find.text('الفاتحة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
