import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/core/haptics/haptics.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/adhkar/domain/quran_passage.dart';
import 'package:mre_quran/features/adhkar/presentation/adhkar_group_page.dart';
import 'package:mre_quran/features/adhkar/presentation/collection_card.dart';
import 'package:mre_quran/features/adhkar/presentation/dhikr_card.dart';
import 'package:mre_quran/features/adhkar/presentation/favorite_button.dart';
import 'package:mre_quran/features/adhkar/presentation/group_card.dart';
import 'package:mre_quran/features/adhkar/presentation/adhkar_search_page.dart';
import 'package:mre_quran/features/adhkar/presentation/duas_page.dart';

import '../../helpers/adhkar_app.dart';
import '../../helpers/adhkar_fixtures.dart';

void main() {
  group('home', () {
    testWidgets('Arabic RTL leads with the list for the time of day', (
      tester,
    ) async {
      await pumpAdhkarApp(tester);
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
      // one tap away as a quick-access chip and has no card of its own.
      expect(find.widgetWithText(ActionChip, 'أذكار المساء'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CollectionCard),
          matching: find.text('أذكار المساء'),
        ),
        findsNothing,
      );
    });

    testWidgets('sections are tiles, two across on a phone', (tester) async {
      await pumpAdhkarApp(tester, catalog: fixtureCatalogWithPrayer());
      final tiles = find.byType(GroupCard);
      expect(tiles, findsNWidgets(2));
      expect(
        tester.getTopLeft(tiles.at(0)).dy,
        tester.getTopLeft(tiles.at(1)).dy,
        reason: 'two tiles share a row',
      );
      // Right to left: the first section is on the right.
      expect(
        tester.getCenter(tiles.at(0)).dx,
        greaterThan(tester.getCenter(tiles.at(1)).dx),
      );
    });

    testWidgets('a quick-access chip opens its list in one tap', (
      tester,
    ) async {
      await pumpAdhkarApp(tester, catalog: fixtureCatalogWithPrayer());
      await tapVisible(tester, find.widgetWithText(ActionChip, 'أذكار النوم'));
      await tester.pumpAndSettle();
      expect(find.textContaining('الخطوة ١ من'), findsOneWidget);
    });

    testWidgets('English LTR', (tester) async {
      await pumpAdhkarApp(tester, locale: 'en');
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
        await pumpAdhkarApp(tester, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text('الأقسام'), findsOneWidget);
      });
    }

    testWidgets('survives dark mode and text scaled to 2', (tester) async {
      await pumpAdhkarApp(tester, theme: AppTheme.dark, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('أذكار الصباح'), findsOneWidget);
    });
  });

  group('groups', () {
    testWidgets('lists each group under its own heading', (tester) async {
      await pumpAdhkarApp(tester, catalog: fixtureCatalogWithPrayer());
      expect(find.text('المقترح الآن'), findsOneWidget);
      expect(find.text('الأقسام'), findsOneWidget);
      expect(find.text('الأذكار اليومية'), findsOneWidget);
      expect(find.text('الصلاة والمسجد'), findsOneWidget);
      // Each group opens its own lists.
      await tapVisible(tester, find.text('الصلاة والمسجد'));
      await tester.pumpAndSettle();
      expect(find.text('أذكار بعد الصلاة'), findsOneWidget);
      expect(find.text('أذكار النوم'), findsNothing);
    });

    testWidgets('a list in progress leads the tab', (tester) async {
      await pumpAdhkarApp(tester, catalog: fixtureCatalogWithPrayer());
      await tapVisible(tester, find.text('الصلاة والمسجد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('أذكار بعد الصلاة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('٠ من ٣'));
      await tester.pumpAndSettle();
      // Close the steps (tap outside the sheet), then leave the group page.
      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(AdhkarGroupPage))).pop();
      await tester.pumpAndSettle();
      expect(find.text('أكمل من حيث توقفت'), findsOneWidget);
      expect(find.text('المقترح الآن'), findsNothing);
      expect(find.text('تابع'), findsOneWidget);
    });

    testWidgets('finishing a list offers the next one', (tester) async {
      await pumpAdhkarApp(tester, catalog: fixtureCatalogWithPrayer());
      await tapVisible(tester, find.text('ابدأ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('٠ من ١'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.textContaining(' من ٣'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('التالي: أذكار المساء'));
      await tester.pumpAndSettle();
      expect(find.textContaining('الخطوة ١ من'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('favourites', () {
    testWidgets('a starred list sits under "now" and is saved', (tester) async {
      final favorites = MemoryFavoritesRepository();
      await pumpAdhkarApp(
        tester,
        catalog: fixtureCatalogWithPrayer(),
        favorites: favorites,
      );
      expect(find.text('المفضلة'), findsNothing);
      // Open the daily group and star the sleep list.
      await tapVisible(tester, find.text('الأذكار اليومية'));
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
      expect(
        find.descendant(
          of: find.byType(CollectionCard),
          matching: find.text('أذكار النوم'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the star on a starred list takes it out again', (
      tester,
    ) async {
      final favorites = MemoryFavoritesRepository()..saved = ['sleep'];
      await pumpAdhkarApp(
        tester,
        catalog: fixtureCatalogWithPrayer(),
        favorites: favorites,
      );
      expect(
        find.descendant(
          of: find.byType(CollectionCard),
          matching: find.text('أذكار النوم'),
        ),
        findsOneWidget,
      );
      final card = find.ancestor(
        of: find
            .descendant(
              of: find.byType(CollectionCard),
              matching: find.text('أذكار النوم'),
            )
            .first,
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
      await pumpAdhkarApp(
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
      await pumpAdhkarApp(tester, catalog: fixtureCatalogWithPrayer());
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
      expect(find.byType(DhikrCard), findsOneWidget);
      expect(find.text('الخطوة ١ من ١'), findsOneWidget);
    });

    testWidgets('says so when nothing matches', (tester) async {
      await pumpAdhkarApp(tester);
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ززززز');
      await tester.pumpAndSettle();
      expect(find.text('لا توجد نتائج'), findsOneWidget);
    });

    testWidgets('a match inside a list is found by its words', (tester) async {
      await pumpAdhkarApp(tester, catalog: fixtureCatalogWithQuran());
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ذكر 2');
      await tester.pumpAndSettle();
      expect(find.text('أذكار مطابقة'), findsOneWidget);
      await tester.tap(find.textContaining('ذكر 2').last);
      await tester.pumpAndSettle();
      // The sheet opens on the dhikr the search found.
      expect(find.text('الخطوة ٢ من ٢'), findsOneWidget);
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
      final scheduler = await pumpAdhkarApp(tester, location: location);
      await tapVisible(tester, find.text('التذكيرات'));
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
      final scheduler = await pumpAdhkarApp(
        tester,
        location: FakeLocationSource(),
      );
      await tapVisible(tester, find.text('التذكيرات'));
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
      await pumpAdhkarApp(tester, catalog: fixtureCatalogWithQuran());
      await tapVisible(tester, find.text('ابدأ'));
      await tester.pumpAndSettle();
      final words = tester.widget<Text>(
        find.textContaining('أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ'),
      );
      expect(words.data, startsWith(Recitation.istiadha));
      final quran = ProviderScope.containerOf(
        tester.element(find.byType(DhikrCard)),
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
    await pumpAdhkarApp(
      tester,
      theme: AppTheme.light.copyWith(platform: TargetPlatform.iOS),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('أذكار الصباح'), findsOneWidget);
    await tapVisible(tester, find.text('ابدأ'));
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
        await pumpAdhkarApp(tester);
        await tapVisible(tester, find.text('ابدأ'));
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
      await pumpAdhkarApp(tester);
      await tapVisible(tester, find.text('ابدأ'));
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

  group('list page', () {
    testWidgets('counts a dhikr, finishes the list, and can start over', (
      tester,
    ) async {
      await pumpAdhkarApp(tester);
      await openList(tester);
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
      await pumpAdhkarApp(tester);
      await openList(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('٠ من ٣'));
      await tester.pumpAndSettle();
      expect(find.text('١ من ٣'), findsOneWidget);
      await tester.tap(find.text('تراجع عن مرة'));
      await tester.pumpAndSettle();
      expect(find.text('٠ من ٣'), findsOneWidget);
    });

    testWidgets('the evidence sheet shows the source and the virtue', (
      tester,
    ) async {
      await pumpAdhkarApp(tester);
      await openList(tester);
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
      await pumpAdhkarApp(tester);
      GoRouter.of(tester.element(find.byType(DuasPage))).push('/adhkar/nope');
      await tester.pumpAndSettle();
      expect(find.text('تعذّر تحميل الأذكار. حاول مرة أخرى.'), findsOneWidget);
    });

    testWidgets('English session has no layout error at text scale 2', (
      tester,
    ) async {
      await pumpAdhkarApp(
        tester,
        locale: 'en',
        textScale: 2,
        size: const Size(320, 640),
      );
      await openList(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Evidence'), findsWidgets);
    });
  });

  group('reminders', () {
    testWidgets('turning one on asks permission and schedules it', (
      tester,
    ) async {
      final scheduler = await pumpAdhkarApp(tester);
      await tester.tap(find.text('التذكيرات'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(scheduler.permissionRequests, 1);
      expect(scheduler.scheduled, hasLength(1));
      expect(find.text('وقت التذكير'), findsOneWidget);
    });

    testWidgets('says why when notifications are not allowed', (tester) async {
      final scheduler = await pumpAdhkarApp(tester, allowNotifications: false);
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
