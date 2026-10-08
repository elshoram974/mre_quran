import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/adhkar/application/adhkar_providers.dart';
import 'package:mre_quran/features/adhkar/application/reminders_provider.dart';
import 'package:mre_quran/features/adhkar/presentation/adhkar_session_page.dart';
import 'package:mre_quran/features/adhkar/presentation/duas_page.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_settings_repository.dart';

Future<FakeReminderScheduler> _pump(
  WidgetTester tester, {
  String locale = 'ar',
  Size size = const Size(390, 844),
  double textScale = 1,
  ThemeData? theme,
  bool allowNotifications = true,
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
        adhkarSourceProvider.overrideWithValue(FakeAdhkarSource()),
        adhkarProgressRepositoryProvider.overrideWithValue(
          MemoryAdhkarProgressRepository(),
        ),
        remindersRepositoryProvider.overrideWithValue(
          MemoryRemindersRepository(),
        ),
        reminderSchedulerProvider.overrideWithValue(scheduler),
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

  group('session', () {
    testWidgets('counts a dhikr, finishes the list, and can start over', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('ابدأ'));
      await tester.pumpAndSettle();

      expect(find.text('ذكر 1'), findsOneWidget);
      expect(find.text('٠ من ٢'), findsOneWidget);
      expect(find.text('٠ / ١'), findsOneWidget);

      await tester.tap(find.text('٠ / ١'));
      await tester.pumpAndSettle();
      expect(find.text('١ من ٢'), findsOneWidget);
      expect(find.text('تمّ اليوم'), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.textContaining(' / ٣'));
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
      await tester.tap(find.text('٠ / ٣'));
      await tester.pumpAndSettle();
      expect(find.text('١ / ٣'), findsOneWidget);
      await tester.tap(find.byTooltip('تراجع عن مرة'));
      await tester.pumpAndSettle();
      expect(find.text('٠ / ٣'), findsOneWidget);
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
