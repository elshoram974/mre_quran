import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/time/ticking_clock.dart';
import 'package:mre_quran/features/adhan/application/adhan_providers.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/data/location_source.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_times_card.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_times_page.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';
import 'package:mre_quran/core/hints/hints.dart';

import '../../helpers/no_hints_repository.dart';
import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_settings_repository.dart';
import '../../helpers/prayer_pages.dart';
import '../../helpers/prayer_soon_fixtures.dart';
import '../../helpers/adhan_fixtures.dart';

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
    required this.soon,
    required this.location,
    required this.repository,
  });

  final FakeReminderScheduler scheduler;
  final FakePrayerSoonPlatform soon;
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
  HintsRepository? hints,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final harness = _Harness(
    scheduler: scheduler ?? FakeReminderScheduler(),
    soon: FakePrayerSoonPlatform(),
    location: location ?? FakeLocationSource(requestResult: _cairo),
    repository: MemoryPrayerRepository()..place = place,
  );
  final router = GoRouter(
    routes: [
      // A tab: the shell's scaffold is what it sits in.
      GoRoute(
        path: '/',
        builder: (_, _) => home ?? const Scaffold(body: PrayerTimesPage()),
      ),
      GoRoute(
        path: AppRoute.prayerTimes.path,
        builder: (_, _) => const Scaffold(body: PrayerTimesPage()),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hintsRepositoryProvider.overrideWithValue(hints ?? NoHintsRepository()),
        reminderSchedulerProvider.overrideWithValue(harness.scheduler),
        prayerSoonPlatformProvider.overrideWithValue(harness.soon),
        // A phone that cannot play the adhan by itself: the alerts at the
        // prayer time stay notices, and no call reaches a real channel.
        adhanPlatformProvider.overrideWithValue(
          FakeAdhanPlatform(supported: false),
        ),
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
        localizationsDelegates: appLocalizationsDelegates,
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
  testWidgets('the next prayer counts down large, and at night the middle of '
      'the night and its last third count down under it', (tester) async {
    await pumpPrayerPage(
      tester,
      home: const Scaffold(body: PrayerTimesPage()),
      place: _cairo,
      now: DateTime(2026, 10, 8, 22, 10),
    );
    expect(find.text('متبقٍ'), findsOneWidget);
    expect(find.textContaining('منتصف الليل بعد'), findsOneWidget);
    expect(find.textContaining('الثلث الأخير من الليل بعد'), findsOneWidget);
    expect(find.textContaining('الشروق بعد'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('after Fajr, sunrise counts down: Fajr\'s time ends then', (
    tester,
  ) async {
    await pumpPrayerPage(
      tester,
      home: const Scaffold(body: PrayerTimesPage()),
      place: _cairo,
      now: DateTime(2026, 10, 8, 5, 40),
    );
    expect(find.textContaining('الشروق بعد'), findsOneWidget);
    expect(find.textContaining('منتصف الليل بعد'), findsNothing);
  });

  group('the place and what stops it', () {
    testWidgets('a named place shows its name, not its numbers', (
      tester,
    ) async {
      final named = PrayerPlace(30.04, 31.24, name: 'القاهرة، مصر');
      await _pump(tester, place: named);
      await _reveal(tester, find.text('الموقع: القاهرة، مصر'));
      expect(find.textContaining('الإحداثيات'), findsNothing);
    });

    testWidgets('a place with no name yet shows its numbers', (tester) async {
      await _pump(tester, place: _cairo);
      await _reveal(tester, find.textContaining('الإحداثيات'));
    });

    testWidgets(
      'location switched off says so, with a button to the settings',
      (tester) async {
        final location = FakeLocationSource()
          ..blocking = LocationProblem.serviceOff;
        await _pump(tester, location: location);
        await tester.tap(find.text('استخدم موقعي'));
        await tester.pumpAndSettle();
        expect(find.textContaining('الموقع مقفول على هاتفك'), findsOneWidget);
        await tester.tap(find.text('تشغيل الموقع'));
        await tester.pumpAndSettle();
        expect(location.openedSettings, [LocationProblem.serviceOff]);
      },
    );

    testWidgets('an allowance blocked for good has a button too', (
      tester,
    ) async {
      final location = FakeLocationSource()..blocking = LocationProblem.blocked;
      await _pump(tester, location: location);
      await tester.tap(find.text('استخدم موقعي'));
      await tester.pumpAndSettle();
      expect(find.textContaining('إذن الموقع مقفول'), findsOneWidget);
      await tester.tap(find.text('فتح الإعدادات'));
      await tester.pumpAndSettle();
      expect(location.openedSettings, [LocationProblem.blocked]);
    });

    testWidgets(
      'a plain refusal says to press again, with no settings button',
      (tester) async {
        final location = FakeLocationSource()
          ..blocking = LocationProblem.denied;
        await _pump(tester, location: location);
        await tester.tap(find.text('استخدم موقعي'));
        await tester.pumpAndSettle();
        expect(find.textContaining('اضغط الزر مرة أخرى'), findsOneWidget);
        expect(find.text('فتح الإعدادات'), findsNothing);
        expect(find.text('تشغيل الموقع'), findsNothing);
      },
    );
  });

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
      // 09:00 on the fixed day: today's Fajr has passed, the rest of the
      // planned days follow, each with its reminder before it.
      final days = PrayerNotifier.planDays - 1;
      final items = handedOver(harness.scheduler, harness.soon).values;
      expect(
        items.where((i) => i.channel == ReminderChannel.prayer),
        hasLength(days),
      );
      // Each with its reminder before it, which the platform keeps.
      expect(harness.soon.countdowns, hasLength(days));
      expect(items.where((i) => i.channel.isPrayerSoon), isEmpty);
      expect(items.every((item) => item.exact), isTrue);

      await tester.tap(find.byTooltip('التنبيه مفعّل'));
      await tester.pumpAndSettle();
      expect(handedOver(harness.scheduler, harness.soon), isEmpty);
    });

    testWidgets('the first alert says what it asks for first, then offers '
        'to try the adhan', (tester) async {
      final harness = await _pump(tester, place: _cairo, hints: _AllHints());
      await _reveal(tester, find.text('تنبيه للصلوات الخمس'));
      await tester.tap(find.text('تنبيه للصلوات الخمس'));
      await tester.pumpAndSettle();
      // Before anything is asked for.
      expect(find.text('سنطلب إذنين'), findsOneWidget);
      expect(harness.scheduler.permissionRequests, 0);
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      expect(harness.scheduler.permissionRequests, 1);
      expect(handedOver(harness.scheduler, harness.soon), isNotEmpty);
      expect(find.text('جرّب الأذان الآن'), findsOneWidget);
      await tester.tap(find.text('لاحقًا'));
      await tester.pumpAndSettle();
      expect(find.text('جرّب الأذان الآن'), findsNothing);
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
      // Every prayer of the planned days, today's Fajr (gone by nine) aside,
      // each with its reminder before it (which the platform keeps): within
      // what the system is given at once.
      expect(
        handedOver(harness.scheduler, harness.soon).length +
            harness.soon.countdowns.length,
        PrayerNotifier.planDays * DailyPrayer.values.length * 2 - 2,
      );
      expect(
        handedOver(harness.scheduler, harness.soon).length +
            harness.soon.countdowns.length,
        lessThanOrEqualTo(PrayerNotifier.notificationLimit),
      );
      // The reminder before them can be moved.
      await _reveal(tester, find.text('تذكير قبل الصلاة'));
      expect(find.text('١٥ دقيقة'), findsOneWidget);
      // It counts down to the adhan, until the person turns that off.
      await _reveal(tester, find.text('عدّ تنازلي حتى الأذان'));
      // The reminders are the platform's, with their countdown.
      expect(harness.soon.countdowns, isNotEmpty);
      final reminder = harness.soon.countdowns.first.id;
      expect(
        handedOver(harness.scheduler, harness.soon),
        isNot(contains(reminder)),
      );
      await tester.tap(find.text('عدّ تنازلي حتى الأذان'));
      await tester.pumpAndSettle();
      // Off, the first of them is a notification that says how long is left.
      expect(harness.soon.countdowns, isEmpty);
      expect(
        handedOver(harness.scheduler, harness.soon)[reminder]!.body,
        startsWith('باقي '),
      );
      // Back up to the day's times, which the page scrolled past.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 1500));
      await tester.pumpAndSettle();
      expect(find.byTooltip('التنبيه مفعّل'), findsNWidgets(5));
      await _reveal(tester, find.textContaining('قد يؤخّر أندرويد'));
      expect(find.textContaining('قد يؤخّر أندرويد'), findsOneWidget);

      // The note is red and boxed: the alerts depend on it.
      final note = find.textContaining('قد يؤخّر أندرويد التنبيه');
      expect(
        tester.widget<Text>(note).style?.color,
        AppTheme.light.colorScheme.error,
      );
      expect(
        find.ancestor(of: note, matching: find.byType(DecoratedBox)),
        findsWidgets,
      );
      await tester.tap(find.text('السماح بالتوقيت الدقيق'));
      await tester.pumpAndSettle();
      expect(scheduler.exactRequests, 1);
    });

    testWidgets('explains exact timing when the first alert is enabled', (
      tester,
    ) async {
      final scheduler = FakeReminderScheduler()..exactAllowed = false;
      await _pump(
        tester,
        place: _cairo,
        scheduler: scheduler,
        hints: _AllHints(),
      );
      await _reveal(tester, find.text('تنبيه للصلوات الخمس'));
      await tester.tap(find.text('تنبيه للصلوات الخمس'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      expect(find.text('السماح بالتوقيت الدقيق'), findsWidgets);
      expect(scheduler.exactRequests, 0);
      await tester.tap(find.text('لاحقًا'));
      await tester.pumpAndSettle();
      expect(find.text('جرّب الأذان الآن'), findsOneWidget);
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
      // Today's Fajr reminder has passed; every other prayer of the planned
      // days has one.
      expect(
        handedOver(harness.scheduler, harness.soon),
        hasLength(PrayerNotifier.planDays * 5 - 1),
      );
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

/// No hint turned off.
class _AllHints implements HintsRepository {
  @override
  Future<Set<AppHint>> dismissed() async => const {};

  @override
  Future<void> dismiss(AppHint hint) async {}
}
