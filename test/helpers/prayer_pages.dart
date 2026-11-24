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
import 'package:mre_quran/features/prayer/presentation/iqama_page.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_tuning_page.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import 'adhkar_fixtures.dart';
import 'memory_settings_repository.dart';
import 'no_hints_repository.dart';
import 'prayer_soon_fixtures.dart';

/// What a prayer page test can look at after [pumpPrayerPage].
class PrayerPageHarness {
  /// Creates the harness.
  PrayerPageHarness({
    required this.repository,
    required this.scheduler,
    required this.soon,
  });

  /// The saved prayer choices and place.
  final MemoryPrayerRepository repository;

  /// What was scheduled.
  final FakeReminderScheduler scheduler;

  /// The countdown reminders handed to the platform.
  final FakePrayerSoonPlatform soon;
}

/// Pumps [home] (the tuning page unless given) over fake stores at nine in the
/// morning on a fixed day, with the pages that lead from the prayer times
/// routed too.
Future<PrayerPageHarness> pumpPrayerPage(
  WidgetTester tester, {
  Widget? home,
  PrayerPlace? place,
  PrayerSettings settings = const PrayerSettings(),
  bool allowNotifications = true,
  String locale = 'ar',
  Size size = const Size(390, 844),
  double textScale = 1,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final harness = PrayerPageHarness(
    repository: MemoryPrayerRepository()
      ..place = place ?? PrayerPlace(30.04, 31.24)
      ..settings = settings,
    scheduler: FakeReminderScheduler(allow: allowNotifications),
    soon: FakePrayerSoonPlatform(),
  );
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home ?? const PrayerTuningPage()),
      GoRoute(
        path: AppRoute.prayerTuning.path,
        builder: (_, _) => const PrayerTuningPage(),
      ),
      GoRoute(path: AppRoute.iqama.path, builder: (_, _) => const IqamaPage()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hintsRepositoryProvider.overrideWithValue(NoHintsRepository()),
        reminderSchedulerProvider.overrideWithValue(harness.scheduler),
        prayerSoonPlatformProvider.overrideWithValue(harness.soon),
        locationSourceProvider.overrideWithValue(FakeLocationSource()),
        prayerRepositoryProvider.overrideWithValue(harness.repository),
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
  return harness;
}

/// Scrolls the page until [finder] is built and on screen.
Future<void> revealOnPage(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}
