import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/hints/hints.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/time/ticking_clock.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/domain/prayer_alerts.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/prayer/domain/prayer_tuning.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_times_page.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_tuning_page.dart';
import 'package:mre_quran/features/settings/application/digits_provider.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/adhkar_fixtures.dart';
import '../../helpers/memory_settings_repository.dart';
import '../../helpers/no_hints_repository.dart';
import '../../helpers/prayer_soon_fixtures.dart';

final _cairo = PrayerPlace(30.04, 31.24);

Future<MemoryPrayerRepository> _pump(
  WidgetTester tester, {
  PrayerPlace? place,
  PrayerSettings settings = const PrayerSettings(),
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
  final repository = MemoryPrayerRepository()
    ..place = place ?? _cairo
    ..settings = settings;
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home ?? const PrayerTuningPage()),
      GoRoute(
        path: AppRoute.prayerTuning.path,
        builder: (_, _) => const PrayerTuningPage(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hintsRepositoryProvider.overrideWithValue(NoHintsRepository()),
        reminderSchedulerProvider.overrideWithValue(FakeReminderScheduler()),
        prayerSoonPlatformProvider.overrideWithValue(FakePrayerSoonPlatform()),
        locationSourceProvider.overrideWithValue(FakeLocationSource()),
        prayerRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 8, 9)),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository()
            ..settings = AppSettings(localeCode: locale),
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
  return repository;
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('minutes for each prayer', () {
    testWidgets('a step later or earlier moves that prayer and its words', (
      tester,
    ) async {
      final repository = await _pump(tester);
      expect(find.text('كما هو محسوب'), findsNWidgets(5));

      final later = find.byTooltip('تأخير دقيقة').first;
      await tester.tap(later);
      await tester.pumpAndSettle();
      expect(repository.settings.offsets, {DailyPrayer.fajr: 1});
      expect(find.text('تأخير دقيقة'), findsOneWidget);
      await tester.tap(later);
      await tester.pumpAndSettle();
      expect(repository.settings.offsets, {DailyPrayer.fajr: 2});
      expect(find.text('تأخير دقيقتين'), findsOneWidget);

      await tester.tap(find.byTooltip('تقديم دقيقة').at(2));
      await tester.pumpAndSettle();
      expect(repository.settings.offsets[DailyPrayer.asr], -1);
      expect(find.text('تقديم دقيقة'), findsOneWidget);
    });

    testWidgets('the time shown is the moved one, and all can be put back', (
      tester,
    ) async {
      final repository = await _pump(tester);
      final plain = PrayerDay.compute(
        _cairo,
        PrayerMethod.egyptian,
        DateTime(2026, 10, 8, 9),
      );
      // The digits are Arabic-Indic, as the app shows them by default.
      String clock(DateTime at) {
        final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
        return formatDisplayDigits(
          '$hour:${at.minute.toString().padLeft(2, '0')}',
          arabic: true,
        );
      }

      expect(find.textContaining(clock(plain.fajr)), findsWidgets);
      await tester.tap(find.byTooltip('تأخير دقيقة').first);
      await tester.pumpAndSettle();
      final moved = plain.fajr.add(const Duration(minutes: 1));
      expect(find.textContaining(clock(moved)), findsWidgets);

      await tester.tap(find.text('إعادة كل الصلوات للوقت المحسوب'));
      await tester.pumpAndSettle();
      expect(repository.settings.offsets, isEmpty);
      expect(find.text('إعادة كل الصلوات للوقت المحسوب'), findsNothing);
    });

    testWidgets('stops at half an hour either way', (tester) async {
      await _pump(
        tester,
        settings: const PrayerSettings(offsets: {DailyPrayer.fajr: 30}),
      );
      final button = tester.widget<IconButton>(
        find
            .ancestor(
              of: find.byTooltip('تأخير دقيقة').first,
              matching: find.byType(IconButton),
            )
            .first,
      );
      expect(button.onPressed, isNull);
    });
  });

  group('summer time', () {
    testWidgets('follows the phone until the person says otherwise', (
      tester,
    ) async {
      final repository = await _pump(tester);
      await _reveal(tester, find.text('التوقيت الصيفي'));
      expect(repository.settings.daylight, DaylightSaving.automatic);
      expect(find.textContaining('ساعة هاتفك الآن على التوقيت'), findsOne);
      await tester.tap(find.text('صيفي'));
      await tester.pumpAndSettle();
      expect(repository.settings.daylight, DaylightSaving.summer);
      await tester.tap(find.text('حسب الهاتف'));
      await tester.pumpAndSettle();
      expect(repository.settings.daylight, DaylightSaving.automatic);
    });
  });

  group('height above sea level', () {
    testWidgets('the phone\'s reading is shown, and a typed one replaces it', (
      tester,
    ) async {
      final repository = await _pump(
        tester,
        place: PrayerPlace(30.04, 31.24, altitude: 40),
      );
      await _reveal(tester, find.text('الارتفاع عن سطح البحر'));
      await _reveal(tester, find.textContaining('من GPS الهاتف'));
      expect(find.textContaining('من GPS الهاتف: ٤٠ م'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '٣٠٠');
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(repository.settings.elevation, 300);
      await _reveal(tester, find.textContaining('ارتفاع كتبته أنت'));
      expect(find.textContaining('ارتفاع كتبته أنت: ٣٠٠ م'), findsOneWidget);
      // What it does to the day.
      expect(find.textContaining('الشروق أبكر والمغرب أبعد بنحو'), findsOne);

      await tester.tap(find.text('استخدم قراءة الهاتف'));
      await tester.pumpAndSettle();
      expect(repository.settings.elevation, isNull);
      expect(find.textContaining('من GPS الهاتف: ٤٠ م'), findsOneWidget);
    });

    testWidgets('a number out of range is refused with the range', (
      tester,
    ) async {
      final repository = await _pump(tester);
      await _reveal(tester, find.text('الارتفاع عن سطح البحر'));
      await _reveal(tester, find.text('حفظ'));
      await tester.enterText(find.byType(EditableText), '99999');
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(find.text('اكتب رقمًا من ٠ إلى ٩٠٠٠'), findsOneWidget);
      expect(repository.settings.elevation, isNull);
    });

    testWidgets('with no reading from the phone, it says so', (tester) async {
      await _pump(tester);
      await _reveal(tester, find.textContaining('لم يعطِ الهاتف ارتفاعًا'));
      expect(find.textContaining('مستوى سطح البحر'), findsOneWidget);
    });
  });

  group('the Hijri date', () {
    testWidgets('moves a day at a time, two at most', (tester) async {
      final repository = await _pump(tester);
      await _reveal(tester, find.text('تعديل التاريخ الهجري'));
      expect(find.text('كما في التقويم'), findsOneWidget);
      final forward = find.byTooltip('يوم للأمام');
      await tester.tap(forward);
      await tester.pumpAndSettle();
      expect(repository.settings.hijriShift, 1);
      expect(find.text('يوم للأمام'), findsOneWidget);
      await tester.tap(forward);
      await tester.pumpAndSettle();
      expect(find.text('يومان للأمام'), findsOneWidget);
      final button = tester.widget<IconButton>(
        find.ancestor(of: forward, matching: find.byType(IconButton)).first,
      );
      expect(button.onPressed, isNull);
      expect(find.textContaining('اليوم: '), findsOneWidget);
    });
  });

  testWidgets('without a place, it asks for one first', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderSchedulerProvider.overrideWithValue(FakeReminderScheduler()),
          prayerSoonPlatformProvider.overrideWithValue(
            FakePrayerSoonPlatform(),
          ),
          locationSourceProvider.overrideWithValue(FakeLocationSource()),
          prayerRepositoryProvider.overrideWithValue(MemoryPrayerRepository()),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          home: const PrayerTuningPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('اختر مكانك أولًا'), findsOneWidget);
    expect(find.byTooltip('تأخير دقيقة'), findsNothing);
  });

  testWidgets('the prayer times page leads here', (tester) async {
    await _pump(tester, home: const Scaffold(body: PrayerTimesPage()));
    await _reveal(tester, find.text('ضبط المواقيت'));
    await tester.tap(find.text('ضبط المواقيت'));
    await tester.pumpAndSettle();
    expect(find.text('تقديم وتأخير الصلوات'), findsOneWidget);
  });

  group('layout', () {
    for (final (name, size) in [
      ('compact', const Size(320, 640)),
      ('medium', const Size(700, 900)),
      ('expanded', const Size(1100, 800)),
    ]) {
      testWidgets('Arabic fits when $name', (tester) async {
        await _pump(tester, size: size);
        for (final title in [
          'تقديم وتأخير الصلوات',
          'التوقيت الصيفي',
          'الارتفاع عن سطح البحر',
          'تعديل التاريخ الهجري',
        ]) {
          await _reveal(tester, find.text(title));
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('English LTR in dark mode at text scale 2', (tester) async {
      await _pump(
        tester,
        locale: 'en',
        theme: AppTheme.dark,
        size: const Size(320, 640),
        textScale: 2,
      );
      expect(find.text('As calculated'), findsWidgets);
      for (final title in [
        'Move the prayers',
        'Summer time',
        'Height above sea level',
        'Adjust the Hijri date',
      ]) {
        await _reveal(tester, find.text(title));
      }
      expect(tester.takeException(), isNull);
    });
  });
}
