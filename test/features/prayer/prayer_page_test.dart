import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/time/ticking_clock.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_times_card.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_times_page.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_settings_repository.dart';

final _cairo = PrayerPlace(30.04, 31.24);

/// Scrolls the page until [finder] is on screen, as a person would.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

class _Harness {
  _Harness({
    required this.scheduler,
    required this.location,
    required this.repository,
  });

  final FakeReminderScheduler scheduler;
  final FakeLocationSource location;
  final MemoryPrayerRepository repository;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  PrayerPlace? place,
  FakeLocationSource? location,
  FakeReminderScheduler? scheduler,
  String locale = 'ar',
  Size size = const Size(390, 844),
  double textScale = 1,
  ThemeData? theme,
  Widget? home,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final harness = _Harness(
    scheduler: scheduler ?? FakeReminderScheduler(),
    location: location ?? FakeLocationSource(requestResult: _cairo),
    repository: MemoryPrayerRepository()..place = place,
  );
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home ?? const PrayerTimesPage()),
      GoRoute(
        path: AppRoute.prayerTimes.path,
        builder: (_, _) => const PrayerTimesPage(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reminderSchedulerProvider.overrideWithValue(harness.scheduler),
        locationSourceProvider.overrideWithValue(harness.location),
        prayerRepositoryProvider.overrideWithValue(harness.repository),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 8, 9)),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
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
  return harness;
}

void main() {
  group('without a place', () {
    testWidgets('asks to use the location, then shows the day', (tester) async {
      final harness = await _pump(tester);
      expect(find.text('اعرف مواقيت الصلاة'), findsOneWidget);
      expect(find.text('الصلاة القادمة'), findsNothing);

      await tester.tap(find.text('استخدم موقعي'));
      await tester.pumpAndSettle();

      expect(harness.location.requests, 1);
      expect(harness.repository.place, _cairo);
      expect(find.text('الصلاة القادمة'), findsOneWidget);
      for (final name in [
        'الفجر',
        'الشروق',
        'الظهر',
        'العصر',
        'المغرب',
        'العشاء',
      ]) {
        expect(find.text(name), findsWidgets, reason: name);
      }
    });

    testWidgets('says why when the location is refused', (tester) async {
      await _pump(tester, location: FakeLocationSource());
      await tester.tap(find.text('استخدم موقعي'));
      await tester.pumpAndSettle();
      expect(find.textContaining('الموقع متوقف'), findsOneWidget);
      expect(find.text('الصلاة القادمة'), findsNothing);
    });
  });

  group('with a place', () {
    testWidgets('the method follows the place until one is chosen', (
      tester,
    ) async {
      final harness = await _pump(tester, place: PrayerPlace(24.71, 46.68));
      await _reveal(tester, find.text('تلقائي: أم القرى، مكة المكرمة'));
      expect(find.text('تلقائي: أم القرى، مكة المكرمة'), findsOneWidget);

      await _reveal(tester, find.text('طريقة الحساب'));
      await tester.tap(find.text('طريقة الحساب'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('الكويت'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('الكويت'));
      await tester.pumpAndSettle();
      expect(harness.repository.settings.method, PrayerMethod.kuwait);

      await _reveal(tester, find.text('طريقة الحساب'));
      await tester.tap(find.text('طريقة الحساب'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تلقائي حسب مكانك'));
      await tester.pumpAndSettle();
      expect(harness.repository.settings.method, isNull);
    });

    testWidgets('a bell turns the alert for one prayer on and off', (
      tester,
    ) async {
      final harness = await _pump(tester, place: _cairo);
      expect(find.byTooltip('التنبيه متوقف'), findsNWidgets(5));

      await tester.tap(find.byTooltip('التنبيه متوقف').first);
      await tester.pumpAndSettle();
      expect(find.byTooltip('التنبيه مفعّل'), findsOneWidget);
      // 09:00 on the fixed day: today's Fajr has passed, six more follow.
      expect(harness.scheduler.once, hasLength(6));
      expect(
        harness.scheduler.once.values.every(
          (item) => item.channel == ReminderChannel.prayer && item.exact,
        ),
        isTrue,
      );

      await tester.tap(find.byTooltip('التنبيه مفعّل'));
      await tester.pumpAndSettle();
      expect(harness.scheduler.once, isEmpty);
    });

    testWidgets('all five at once, with a way to allow exact timing', (
      tester,
    ) async {
      final scheduler = FakeReminderScheduler()..exactAllowed = false;
      final harness = await _pump(tester, place: _cairo, scheduler: scheduler);
      expect(find.text('السماح بالتوقيت الدقيق'), findsNothing);

      await _reveal(tester, find.text('تنبيه للصلوات الخمس'));
      await tester.tap(find.text('تنبيه للصلوات الخمس'));
      await tester.pumpAndSettle();
      // Four prayers are left today, then five a day for six days.
      expect(harness.scheduler.once, hasLength(34));
      expect(find.byTooltip('التنبيه مفعّل'), findsNWidgets(5));
      expect(find.textContaining('قد يؤخّر أندرويد'), findsOneWidget);

      await tester.tap(find.text('السماح بالتوقيت الدقيق'));
      await tester.pumpAndSettle();
      expect(scheduler.exactRequests, 1);
    });

    testWidgets('no exact-alarm note when exact alarms are already allowed', (
      tester,
    ) async {
      await _pump(tester, place: _cairo);
      await _reveal(tester, find.text('تنبيه للصلوات الخمس'));
      await tester.tap(find.text('تنبيه للصلوات الخمس'));
      await tester.pumpAndSettle();
      expect(find.text('السماح بالتوقيت الدقيق'), findsNothing);
    });

    testWidgets('the adhkar reminder switch lives here too', (tester) async {
      final harness = await _pump(tester, place: _cairo);
      await _reveal(tester, find.text('ذكّرني بعد كل صلاة'));
      await tester.tap(find.text('ذكّرني بعد كل صلاة'));
      await tester.pumpAndSettle();
      expect(harness.repository.settings.adhkarReminder, isTrue);
      expect(harness.scheduler.once, hasLength(34));
    });

    testWidgets('updating the location asks again', (tester) async {
      final harness = await _pump(tester, place: _cairo);
      await _reveal(tester, find.text('حدّث موقعي'));
      await tester.tap(find.text('حدّث موقعي'));
      await tester.pumpAndSettle();
      expect(harness.location.requests, 1);
    });
  });

  group('layout', () {
    for (final (name, size) in [
      ('compact', const Size(320, 640)),
      ('medium', const Size(700, 900)),
      ('expanded', const Size(1100, 800)),
    ]) {
      testWidgets('Arabic fits when $name', (tester) async {
        await _pump(tester, place: _cairo, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text('الصلاة القادمة'), findsOneWidget);
      });
    }

    testWidgets('English LTR in dark mode at text scale 2', (tester) async {
      await _pump(
        tester,
        place: _cairo,
        locale: 'en',
        textScale: 2,
        size: const Size(320, 640),
        theme: AppTheme.dark,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Next prayer'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(PrayerTimesPage))),
        TextDirection.ltr,
      );
    });
  });

  group('the card on the adhkar tab', () {
    testWidgets('invites before there is a place, then shows the next prayer', (
      tester,
    ) async {
      await _pump(tester, home: const Scaffold(body: PrayerTimesCard()));
      expect(find.text('مواقيت الصلاة'), findsOneWidget);
      expect(find.text('اعرف مواقيت الصلاة'), findsOneWidget);
    });

    testWidgets('shows the next prayer and opens the page', (tester) async {
      await _pump(
        tester,
        place: _cairo,
        home: const Scaffold(body: PrayerTimesCard()),
      );
      expect(find.textContaining('بعد '), findsOneWidget);
      await tester.tap(find.text('مواقيت الصلاة'));
      await tester.pumpAndSettle();
      expect(find.byType(PrayerTimesPage), findsOneWidget);
    });
  });
}
