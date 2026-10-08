import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler_provider.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/time/ticking_clock.dart';
import 'package:mre_quran/features/adhkar/application/adhkar_providers.dart';
import 'package:mre_quran/features/adhkar/application/favorites_provider.dart';
import 'package:mre_quran/features/adhkar/application/reminders_provider.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_collection.dart';
import 'package:mre_quran/features/adhkar/presentation/adhkar_group_page.dart';
import 'package:mre_quran/features/adhkar/presentation/adhkar_search_page.dart';
import 'package:mre_quran/features/adhkar/presentation/adhkar_session_page.dart';
import 'package:mre_quran/features/adhkar/presentation/duas_page.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import 'adhkar_fixtures.dart';
import 'fake_quran_metadata_source.dart';
import 'fake_quran_text_source.dart';
import 'memory_settings_repository.dart';

/// Pumps the Adhkar tab with fake stores, at 09:00 on a fixed day.
Future<FakeReminderScheduler> pumpAdhkarApp(
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
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
}

/// Opens the morning list as a page, the way "show as a list" does.
Future<void> openList(WidgetTester tester, {String id = 'morning'}) async {
  GoRouter.of(tester.element(find.byType(DuasPage))).push('/adhkar/$id');
  await tester.pumpAndSettle();
}
