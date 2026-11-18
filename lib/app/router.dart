import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/theme/app_tokens.dart';
import '../features/about/presentation/about_page.dart';
import '../features/home_widgets/presentation/home_widgets_page.dart';
import '../features/adhkar/presentation/adhkar_group_page.dart';
import '../features/adhkar/presentation/adhkar_search_page.dart';
import '../features/adhkar/presentation/adhkar_session_page.dart';
import '../features/adhkar/presentation/duas_page.dart';
import '../features/bookmarks/presentation/bookmarks_page.dart';
import '../features/mushaf/presentation/mushaf_page.dart';
import '../features/adhan/presentation/adhan_page.dart';
import '../features/prayer/presentation/prayer_times_page.dart';
import '../features/prayer/presentation/prayer_location_picker_page.dart';
import '../features/prayer/presentation/qibla_page.dart';
import '../features/quran_index/presentation/quran_index_page.dart';
import '../features/quran_text/presentation/quran_search_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/startup/application/startup_providers.dart';
import 'app_shell.dart';
import 'reminder_opener.dart';
import '../core/notifications/reminder_scheduler_provider.dart';

/// App-wide declarative routes and persistent navigation branches.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: ref.read(initialLocationProvider),
    routes: [
      StatefulShellRoute(
        navigatorContainerBuilder: (context, shell, children) => Stack(
          children: [
            for (var i = 0; i < children.length; i++)
              Offstage(
                offstage: i != shell.currentIndex,
                child: AnimatedOpacity(
                  opacity: i == shell.currentIndex ? 1 : 0,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppTokens.motionMedium,
                  child: TickerMode(
                    enabled: i == shell.currentIndex,
                    child: children[i],
                  ),
                ),
              ),
          ],
        ),
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.reader.path,
                builder: (context, state) => const MushafPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.duas.path,
                builder: (context, state) => const DuasPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.bookmarks.path,
                builder: (context, state) => const BookmarksPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.settings.path,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.quranSearch.path,
        pageBuilder: (context, state) =>
            _page(context, state, const QuranSearchPage()),
      ),
      GoRoute(
        path: AppRoute.quranIndex.path,
        pageBuilder: (context, state) =>
            _page(context, state, const QuranIndexPage()),
      ),
      GoRoute(
        path: AppRoute.adhkarSession.path,
        pageBuilder: (context, state) => _page(
          context,
          state,
          AdhkarSessionPage(
            collectionId: state.pathParameters['id']!,
            focusOrder: int.tryParse(state.uri.queryParameters['focus'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.adhkarGroup.path,
        pageBuilder: (context, state) => _page(
          context,
          state,
          AdhkarGroupPage(groupId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoute.prayerTimes.path,
        pageBuilder: (context, state) =>
            _page(context, state, const PrayerTimesPage()),
      ),
      GoRoute(
        path: AppRoute.prayerLocationPicker.path,
        pageBuilder: (context, state) =>
            _page(context, state, const PrayerLocationPickerPage()),
      ),
      GoRoute(
        path: AppRoute.adhan.path,
        pageBuilder: (context, state) =>
            _page(context, state, const AdhanPage()),
      ),
      GoRoute(
        path: AppRoute.qibla.path,
        pageBuilder: (context, state) =>
            _page(context, state, const QiblaPage()),
      ),
      GoRoute(
        path: AppRoute.adhkarSearch.path,
        pageBuilder: (context, state) =>
            _page(context, state, const AdhkarSearchPage()),
      ),
      GoRoute(
        path: AppRoute.about.path,
        pageBuilder: (context, state) =>
            _page(context, state, const AboutPage()),
      ),
      GoRoute(
        path: AppRoute.widgets.path,
        pageBuilder: (context, state) =>
            _page(context, state, const HomeWidgetsPage()),
      ),
    ],
  );
  // WidgetKit supplies an absolute deep link through Flutter's router.
  void trackWidgetLink() {
    if (router.routeInformationProvider.value.uri.scheme == 'mrequran') {
      ref.read(opensOnReaderProvider.notifier).openedElsewhere();
    }
  }

  router.routeInformationProvider.addListener(trackWidgetLink);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (ref.mounted) trackWidgetLink();
  });
  // A reminder that launched the app opens what it points at, once the first
  // frame is up.
  final launch = ref.read(reminderSchedulerProvider).launchPayload;
  if (launch != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.mounted) return;
      ref.read(opensOnReaderProvider.notifier).openedElsewhere();
      unawaited(openReminder(router, launch));
    });
  }
  ref.onDispose(() {
    router.routeInformationProvider.removeListener(trackWidgetLink);
    router.dispose();
  });
  return router;
});

Page<void> _page(BuildContext context, GoRouterState state, Widget child) {
  final duration = MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : AppTokens.motionMedium;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Stable paths used by navigation and tests.
enum AppRoute {
  reader('/reader'),
  duas('/duas'),
  bookmarks('/bookmarks'),
  settings('/settings'),
  about('/about'),
  widgets('/widgets'),
  quranIndex('/quran-index'),
  quranSearch('/quran-search'),
  adhkarSession('/adhkar/:id'),
  adhkarGroup('/adhkar-group/:id'),
  adhkarSearch('/adhkar-search'),
  prayerTimes('/prayer-times'),
  prayerLocationPicker('/prayer-location'),
  qibla('/qibla'),
  adhan('/adhan');

  const AppRoute(this.path);
  final String path;

  /// Path that opens the adhkar collection [id], scrolled to the dhikr whose
  /// order is [focusOrder] when given.
  static String adhkarSessionPath(String id, {int? focusOrder}) =>
      focusOrder == null ? '/adhkar/$id' : '/adhkar/$id?focus=$focusOrder';

  /// Path that opens the adhkar group [id].
  static String adhkarGroupPath(String id) => '/adhkar-group/$id';

  /// Top-level tabs in navigation order. Must match the shell branches.
  static const List<AppRoute> tabs = [reader, duas, bookmarks, settings];
}
