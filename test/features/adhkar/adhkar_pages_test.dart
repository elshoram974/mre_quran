import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/haptics/haptics.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/adhkar/application/adhkar_providers.dart';
import 'package:mre_quran/features/adhkar/application/favorites_provider.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/adhkar/application/reminders_provider.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_collection.dart';
import 'package:mre_quran/features/adhkar/domain/quran_passage.dart';
import 'package:mre_quran/features/adhkar/presentation/adhkar_group_page.dart';
import 'package:mre_quran/features/adhkar/presentation/collection_card.dart';
import 'package:mre_quran/features/adhkar/presentation/favorite_button.dart';
import 'package:mre_quran/features/adhkar/presentation/adhkar_search_page.dart';
import 'package:mre_quran/features/adhkar/presentation/adhkar_session_page.dart';
import 'package:mre_quran/features/adhkar/presentation/duas_page.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';
import '../../helpers/memory_settings_repository.dart';

import 'package:mre_quran/core/time/ticking_clock.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';

Future<FakeReminderScheduler> _pump(
  WidgetTester tester, {
  String locale = 'ar',
  Size size = const Size(390, 844),
  double textScale = 1,
  ThemeData? theme,
  bool allowNotifications = true,
  AdhkarCatalog? catalog,
  MemoryFavoritesRepository? favorites,
  FakeLocationSource? location,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scheduler = FakeReminderScheduler(allow: allowNotifications);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: DuasPage()),
      ),
      GoRoute(
        path: AppRoute.adhkarSession.path,
        builder: (_, state) => AdhkarSessionPage(
          collectionId: state.pathParameters['id']!,
          focusOrder: int.tryParse(state.uri.queryParameters['focus'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoute.adhkarGroup.path,
        builder: (_, state) =>
            AdhkarGroupPage(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoute.adhkarSearch.path,
        builder: (_, _) => const AdhkarSearchPage(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adhkarSourceProvider.overrideWithValue(FakeAdhkarSource(catalog)),
        adhkarProgressRepositoryProvider.overrideWithValue(
          MemoryAdhkarProgressRepository(),
        ),
        remindersRepositoryProvider.overrideWithValue(
          MemoryRemindersRepository(),
        ),
        reminderSchedulerProvider.overrideWithValue(scheduler),
        adhkarFavoritesRepositoryProvider.overrideWithValue(
          favorites ?? MemoryFavoritesRepository(),
        ),
        prayerRepositoryProvider.overrideWithValue(MemoryPrayerRepository()),
        locationSourceProvider.overrideWithValue(
          location ??
              FakeLocationSource(requestResult: PrayerPlace(30.04, 31.24)),
        ),
        quranMetadataSourceProvider.overrideWithValue(
          FakeQuranMetadataSource(),
        ),
        quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 8, 9)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme ?? AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return scheduler;
}

/// Taps [finder] after scrolling it into view, as a person would.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
}

void main() {
  group('home', () {
    testWidgets('Arabic RTL leads with the list for the time of day', (
      tester,
    ) async {
      await _pump(tester);
      expect(
        Directionality.of(tester.element(find.byType(DuasPage))),
        TextDirection.rtl,
      );
      expect(find.text('المقترح الآن'), findsOneWidget);
      expect(find.text('أذكار الصباح'), findsOneWidget);
      expect(find.text('ابدأ'), findsOneWidget);
      expect(find.text('الأقسام'), findsOneWidget);
      expect(find.text('الأذكار اليومية'), findsOneWidget);
      expect(find.text('لا يوجد تذكير مفعّل'), findsOneWidget);
      // The morning list is the featured one at 09:00; the evening list is
      // inside its group.
      expect(find.text('أذكار المساء'), findsNothing);
    });

    testWidgets('English LTR', (tester) async {
      await _pump(tester, locale: 'en');
      expect(
        Directionality.of(tester.element(find.byType(DuasPage))),
        TextDirection.ltr,
      );
      expect(find.text('Suggested now'), findsOneWidget);
      expect(find.text('Morning adhkar'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    });

    for (final (name, size) in [
      ('compact', const Size(320, 640)),
      ('medium', const Size(700, 900)),
      ('expanded', const Size(1100, 800)),
    ]) {
      testWidgets('lays out without error when $name', (tester) async {
        await _pump(tester, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text('الأقسام'), findsOneWidget);
      });
    }

    testWidgets('survives dark mode and text scaled to 2', (tester) async {
      await _pump(tester, theme: AppTheme.dark, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('أذكار الصباح'), findsOneWidget);
    });
  });

  group('groups', () {
    testWidgets('lists each group under its own heading', (tester) async {
      await _pump(tester, catalog: fixtureCatalogWithPrayer());
      expect(find.text('المقترح الآن'), findsOneWidget);
      expect(find.text('الأقسام'), findsOneWidget);
      expect(find.text('الأذكار اليومية'), findsOneWidget);
      expect(find.text('الصلاة والمسجد'), findsOneWidget);
      // Each group opens its own lists.
      await _tapVisible(tester, find.text('الصلاة والمسجد'));
      await tester.pumpAndSettle();
      expect(find.text('أذكار بعد الصلاة'), findsOneWidget);
      expect(find.text('أذكار النوم'), findsNothing);
    });

    testWidgets('a list in progress leads the tab', (tester) async {
      await _pump(tester, catalog: fixtureCatalogWithPrayer());
      await _tapVisible(tester, find.text('الصلاة والمسجد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('أذكار بعد الصلاة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('٠ من ٣'));
      await tester.pumpAndSettle();
      final router = GoRouter.of(
        tester.element(find.byType(AdhkarSessionPage)),
      );
      router.pop();
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('أكمل من حيث توقفت'), findsOneWidget);
      expect(find.text('المقترح الآن'), findsNothing);
      expect(find.text('تابع'), findsOneWidget);
    });

    testWidgets('finishing a list offers the next one', (tester) async {
      await _pump(tester, catalog: fixtureCatalogWithPrayer());
      await _tapVisible(tester, find.text('ابدأ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('٠ من ١'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.textContaining(' من ٣'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('التالي: أذكار المساء'));
      await tester.pumpAndSettle();
      expect(find.text('أذكار المساء'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('favourites', () {
    testWidgets('a starred list sits under "now" and is saved', (tester) async {
      final favorites = MemoryFavoritesRepository();
      await _pump(
        tester,
        catalog: fixtureCatalogWithPrayer(),
        favorites: favorites,
      );
      expect(find.text('المفضلة'), findsNothing);
      // Open the daily group and star the sleep list.
      await _tapVisible(tester, find.text('الأذكار اليومية'));
      await tester.pumpAndSettle();
      final sleepCard = find.ancestor(
        of: find.text('أذكار النوم'),
        matching: find.byType(CollectionCard),
      );
      await tester.tap(
        find.descendant(of: sleepCard, matching: find.byType(FavoriteButton)),
      );
      await tester.pumpAndSettle();
      expect(favorites.saved, ['sleep']);

      GoRouter.of(tester.element(find.byType(AdhkarGroupPage))).pop();
      await tester.pumpAndSettle();
      expect(find.text('المفضلة'), findsOneWidget);
      final favoritesTop = tester.getTopLeft(find.text('المفضلة')).dy;
      final nowTop = tester.getTopLeft(find.text('المقترح الآن')).dy;
      final sectionsTop = tester.getTopLeft(find.text('الأقسام')).dy;
      expect(nowTop, lessThan(favoritesTop));
      expect(favoritesTop, lessThan(sectionsTop));
      expect(find.text('أذكار النوم'), findsOneWidget);
    });

    testWidgets('the star on a starred list takes it out again', (
      tester,
    ) async {
      final favorites = MemoryFavoritesRepository()..saved = ['sleep'];
      await _pump(
        tester,
        catalog: fixtureCatalogWithPrayer(),
        favorites: favorites,
      );
      expect(find.text('أذكار النوم'), findsOneWidget);
      final card = find.ancestor(
        of: find.text('أذكار النوم'),
        matching: find.byType(CollectionCard),
      );
      await tester.tap(
        find.descendant(of: card, matching: find.byType(FavoriteButton)),
      );
      await tester.pumpAndSettle();
      expect(favorites.saved, isEmpty);
      expect(find.text('المفضلة'), findsNothing);
    });

    testWidgets('a list that is no longer in the data is ignored', (
      tester,
    ) async {
      await _pump(
        tester,
        favorites: MemoryFavoritesRepository()..saved = ['gone'],
      );
      expect(tester.takeException(), isNull);
      expect(find.text('المفضلة'), findsNothing);
    });
  });

  group('search', () {
    testWidgets('names first, then words; a word opens its list at the dhikr', (
      tester,
    ) async {
      await _pump(tester, catalog: fixtureCatalogWithPrayer());
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.byType(AdhkarSearchPage), findsOneWidget);
      expect(
        find.text('اكتب اسمًا مثل «النوم» أو كلمات من الدعاء.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'النوم');
      await tester.pumpAndSettle();
      expect(find.text('القوائم'), findsOneWidget);
      await tester.tap(find.text('أذكار النوم').first);
      await tester.pumpAndSettle();
      expect(find.byType(AdhkarSessionPage), findsOneWidget);
    });

    testWidgets('says so when nothing matches', (tester) async {
      await _pump(tester);
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ززززز');
      await tester.pumpAndSettle();
      expect(find.text('لا توجد نتائج'), findsOneWidget);
    });

    testWidgets('a match inside a list is found by its words', (tester) async {
      await _pump(tester, catalog: fixtureCatalogWithQuran());
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ذكر 2');
      await tester.pumpAndSettle();
      expect(find.text('أذكار مطابقة'), findsOneWidget);
      await tester.tap(find.textContaining('ذكر 2').last);
      await tester.pumpAndSettle();
      expect(find.byType(AdhkarSessionPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('after-prayer reminders in the sheet', () {
    testWidgets('on: asks for notifications and location, then shows choices', (
      tester,
    ) async {
      final location = FakeLocationSource(
        requestResult: PrayerPlace(30.04, 31.24),
      );
      final scheduler = await _pump(tester, location: location);
      await _tapVisible(tester, find.text('التذكيرات'));
      await tester.pumpAndSettle();
      expect(find.text('بعد كل صلاة'), findsOneWidget);
      expect(find.text('التذكير بعد الصلاة'), findsNothing);

      await tester.tap(find.byType(Switch).last);
      await tester.pumpAndSettle();
      expect(location.requests, 1);
      expect(scheduler.once, isNotEmpty);
      expect(find.text('التذكير بعد الصلاة'), findsOneWidget);
      // The method and the time alerts live on the prayer times page.
      expect(find.text('طريقة الحساب'), findsNothing);
    });

    testWidgets('says why when location is refused', (tester) async {
      final scheduler = await _pump(tester, location: FakeLocationSource());
      await _tapVisible(tester, find.text('التذكيرات'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).last);
      await tester.pumpAndSettle();
      expect(scheduler.once, isEmpty);
      expect(find.textContaining('الموقع متوقف'), findsOneWidget);
      expect(find.text('طريقة الحساب'), findsNothing);
    });
  });

  group('Quran dhikr', () {
    testWidgets('shows the isti\'adha and the verified ayah, and cites it', (
      tester,
    ) async {
      await _pump(tester, catalog: fixtureCatalogWithQuran());
      await _tapVisible(tester, find.text('ابدأ'));
      await tester.pumpAndSettle();
      final words = tester.widget<Text>(
        find.textContaining('أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ'),
      );
      expect(words.data, startsWith(Recitation.istiadha));
      final quran = ProviderScope.containerOf(
        tester.element(find.byType(AdhkarSessionPage)),
      ).read(quranTextProvider).value!;
      expect(words.data, contains(quran.uthmani(const AyahRef(2, 255))));

      await tester.tap(find.text('الدليل').first);
      await tester.pumpAndSettle();
      expect(find.text('من القرآن'), findsOneWidget);
      expect(find.textContaining('٢٥٥'), findsWidgets);
      expect(find.text('رواه النسائي'), findsOneWidget);
    });
  });

  testWidgets('iOS glass chrome lays out without error', (tester) async {
    await _pump(
      tester,
      theme: AppTheme.light.copyWith(platform: TargetPlatform.iOS),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('أذكار الصباح'), findsOneWidget);
    await _tapVisible(tester, find.text('ابدأ'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('vibration', () {
    final original = Haptics.backend;
    late RecordingHaptics recorder;

    setUp(() {
      recorder = RecordingHaptics();
      Haptics.backend = recorder;
      Haptics.enabled = true;
    });

    tearDown(() {
      Haptics.backend = original;
      Haptics.enabled = true;
    });

    testWidgets(
      'a tick for a repeat, a firm pulse when a dhikr is done, two at the end',
      (tester) async {
        await _pump(tester);
        await _tapVisible(tester, find.text('ابدأ'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('٠ من ١'));
        await tester.pumpAndSettle();
        expect(recorder.calls, ['step']);

        await tester.tap(find.text('٠ من ٣'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('١ من ٣'));
        await tester.pumpAndSettle();
        expect(recorder.calls, ['step', 'tick', 'tick']);

        await tester.tap(find.text('٢ من ٣'));
        await tester.pumpAndSettle();
        expect(recorder.calls, ['step', 'tick', 'tick', 'celebrate']);
      },
    );

    testWidgets('nothing when the person turned vibration off', (tester) async {
      Haptics.enabled = false;
      await _pump(tester);
      await _tapVisible(tester, find.text('ابدأ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('٠ من ١'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('٠ من ٣'));
      await tester.pumpAndSettle();
      expect(recorder.calls, isEmpty);
      // The count still went up.
      expect(find.text('١ من ٣'), findsOneWidget);
    });
  });

  group('session', () {
    testWidgets('counts a dhikr, finishes the list, and can start over', (
      tester,
    ) async {
      await _pump(tester);
      await _tapVisible(tester, find.text('ابدأ'));
      await tester.pumpAndSettle();

      expect(find.text('ذكر 1'), findsOneWidget);
      expect(find.text('٠ من ٢'), findsOneWidget);
      expect(find.text('٠ من ١'), findsOneWidget);

      await tester.tap(find.text('٠ من ١'));
      await tester.pumpAndSettle();
      expect(find.text('١ من ٢'), findsOneWidget);
      expect(find.text('تم'), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.textContaining(' من ٣'));
        await tester.pumpAndSettle();
      }
      expect(find.text('تقبّل الله منك'), findsOneWidget);
      expect(find.text('أتممت أذكار الصباح لليوم.'), findsOneWidget);

      await tester.tap(find.text('ابدأ من جديد'));
      await tester.pumpAndSettle();
      expect(find.text('تقبّل الله منك'), findsNothing);
      expect(find.text('٠ من ٢'), findsOneWidget);
    });

    testWidgets('undo takes one repeat back', (tester) async {
      await _pump(tester);
      await _tapVisible(tester, find.text('ابدأ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('٠ من ٣'));
      await tester.pumpAndSettle();
      expect(find.text('١ من ٣'), findsOneWidget);
      await tester.tap(find.byTooltip('تراجع عن مرة'));
      await tester.pumpAndSettle();
      expect(find.text('٠ من ٣'), findsOneWidget);
    });

    testWidgets('the evidence sheet shows the source and the virtue', (
      tester,
    ) async {
      await _pump(tester);
      await _tapVisible(tester, find.text('ابدأ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الدليل').first);
      await tester.pumpAndSettle();
      expect(find.text('المصدر 1'), findsOneWidget);
      expect(find.text('فضل'), findsOneWidget);
      expect(find.text('الفضل'), findsOneWidget);
    });

    testWidgets('an unknown collection id shows the error state', (
      tester,
    ) async {
      await _pump(tester);
      GoRouter.of(tester.element(find.byType(DuasPage))).push('/adhkar/nope');
      await tester.pumpAndSettle();
      expect(find.text('تعذّر تحميل الأذكار. حاول مرة أخرى.'), findsOneWidget);
    });

    testWidgets('English session has no layout error at text scale 2', (
      tester,
    ) async {
      await _pump(
        tester,
        locale: 'en',
        textScale: 2,
        size: const Size(320, 640),
      );
      await _tapVisible(tester, find.text('Start'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Evidence'), findsWidgets);
    });
  });

  group('reminders', () {
    testWidgets('turning one on asks permission and schedules it', (
      tester,
    ) async {
      final scheduler = await _pump(tester);
      await tester.tap(find.text('التذكيرات'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(scheduler.permissionRequests, 1);
      expect(scheduler.scheduled, hasLength(1));
      expect(find.text('وقت التذكير'), findsOneWidget);
    });

    testWidgets('says why when notifications are not allowed', (tester) async {
      final scheduler = await _pump(tester, allowNotifications: false);
      await tester.tap(find.text('التذكيرات'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(scheduler.scheduled, isEmpty);
      expect(find.textContaining('الإشعارات متوقفة'), findsOneWidget);
      expect(find.text('وقت التذكير'), findsNothing);
    });
  });
}
