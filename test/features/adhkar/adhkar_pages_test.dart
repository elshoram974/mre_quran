import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/adhkar/application/adhkar_providers.dart';
import 'package:mre_quran/features/adhkar/application/reminders_provider.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_collection.dart';
import 'package:mre_quran/features/adhkar/domain/quran_passage.dart';
import 'package:mre_quran/features/adhkar/presentation/adhkar_session_page.dart';
import 'package:mre_quran/features/adhkar/presentation/duas_page.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';
import '../../helpers/memory_settings_repository.dart';

Future<FakeReminderScheduler> _pump(
  WidgetTester tester, {
  String locale = 'ar',
  Size size = const Size(390, 844),
  double textScale = 1,
  ThemeData? theme,
  bool allowNotifications = true,
  AdhkarCatalog? catalog,
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
        builder: (_, state) =>
            AdhkarSessionPage(collectionId: state.pathParameters['id']!),
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
        quranMetadataSourceProvider.overrideWithValue(
          FakeQuranMetadataSource(),
        ),
        quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
        adhkarClockProvider.overrideWithValue(() => DateTime(2026, 10, 8, 9)),
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
      expect(find.text('أذكار المساء'), findsOneWidget);
      expect(find.text('ابدأ'), findsOneWidget);
      expect(find.text('لا يوجد تذكير مفعّل'), findsOneWidget);
      // The morning list is the featured one at 09:00.
      final featured = tester.getTopLeft(find.text('أذكار الصباح')).dy;
      final other = tester.getTopLeft(find.text('أذكار المساء')).dy;
      expect(featured, lessThan(other));
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
        expect(find.text('أذكار المساء'), findsOneWidget);
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
      expect(find.text('الأذكار اليومية'), findsOneWidget);
      expect(find.text('أذكار الصلاة'), findsOneWidget);
      expect(find.text('أذكار بعد الصلاة'), findsOneWidget);
      expect(find.text('أذكار النوم'), findsOneWidget);
      // The featured list is not repeated in its group.
      expect(find.text('أذكار الصباح'), findsOneWidget);
    });

    testWidgets('a list in progress leads the tab', (tester) async {
      await _pump(tester, catalog: fixtureCatalogWithPrayer());
      await tester.tap(find.text('أذكار بعد الصلاة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('٠ من ٣'));
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(AdhkarSessionPage))).pop();
      await tester.pumpAndSettle();
      expect(find.text('أكمل من حيث توقفت'), findsOneWidget);
      expect(find.text('المقترح الآن'), findsNothing);
      expect(find.text('تابع'), findsOneWidget);
    });

    testWidgets('finishing a list offers the next one', (tester) async {
      await _pump(tester, catalog: fixtureCatalogWithPrayer());
      await tester.tap(find.text('ابدأ'));
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

  group('Quran dhikr', () {
    testWidgets('shows the isti\'adha and the verified ayah, and cites it', (
      tester,
    ) async {
      await _pump(tester, catalog: fixtureCatalogWithQuran());
      await tester.tap(find.text('ابدأ'));
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
    await tester.tap(find.text('ابدأ'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('session', () {
    testWidgets('counts a dhikr, finishes the list, and can start over', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('ابدأ'));
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
      await tester.tap(find.text('ابدأ'));
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
      await tester.tap(find.text('ابدأ'));
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
      await tester.tap(find.text('Start'));
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
