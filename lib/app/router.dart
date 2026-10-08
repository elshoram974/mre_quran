import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/widgets.dart';

import '../features/about/presentation/about_page.dart';
import '../features/adhkar/application/reminders_provider.dart';
import '../features/adhkar/domain/reminder_payload.dart';
import '../features/adhkar/presentation/adhkar_group_page.dart';
import '../features/adhkar/presentation/adhkar_search_page.dart';
import '../features/adhkar/presentation/adhkar_session_page.dart';
import '../features/adhkar/presentation/duas_page.dart';
import '../features/bookmarks/presentation/bookmarks_page.dart';
import '../features/mushaf/presentation/mushaf_page.dart';
import '../features/quran_index/presentation/quran_index_page.dart';
import '../features/quran_text/presentation/quran_search_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/startup/application/startup_providers.dart';
import 'app_shell.dart';

/// App-wide declarative routes and persistent navigation branches.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: ref.read(initialLocationProvider),
    routes: [
      StatefulShellRoute.indexedStack(
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
        builder: (context, state) => const QuranSearchPage(),
      ),
      GoRoute(
        path: AppRoute.quranIndex.path,
        builder: (context, state) => const QuranIndexPage(),
      ),
      GoRoute(
        path: AppRoute.adhkarSession.path,
        builder: (context, state) => AdhkarSessionPage(
          collectionId: state.pathParameters['id']!,
          focusOrder: int.tryParse(state.uri.queryParameters['focus'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoute.adhkarGroup.path,
        builder: (context, state) =>
            AdhkarGroupPage(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoute.adhkarSearch.path,
        builder: (context, state) => const AdhkarSearchPage(),
      ),
      GoRoute(
        path: AppRoute.about.path,
        builder: (context, state) => const AboutPage(),
      ),
    ],
  );
  // A reminder that launched the app opens its list on top of the first tab.
  final launch = ref.read(reminderSchedulerProvider).launchPayload;
  final launchPath = launch == null
      ? null
      : AppRoute.fromReminderPayload(launch);
  if (launchPath != null) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => router.push(launchPath),
    );
  }
  ref.onDispose(router.dispose);
  return router;
});

/// Stable paths used by navigation and tests.
enum AppRoute {
  reader('/reader'),
  duas('/duas'),
  bookmarks('/bookmarks'),
  settings('/settings'),
  about('/about'),
  quranIndex('/quran-index'),
  quranSearch('/quran-search'),
  adhkarSession('/adhkar/:id'),
  adhkarGroup('/adhkar-group/:id'),
  adhkarSearch('/adhkar-search');

  const AppRoute(this.path);
  final String path;

  /// Path that opens the adhkar collection [id], scrolled to the dhikr whose
  /// order is [focusOrder] when given.
  static String adhkarSessionPath(String id, {int? focusOrder}) =>
      focusOrder == null ? '/adhkar/$id' : '/adhkar/$id?focus=$focusOrder';

  /// Path that opens the adhkar group [id].
  static String adhkarGroupPath(String id) => '/adhkar-group/$id';

  /// Path a reminder notification opens, or null for a payload that is not ours.
  static String? fromReminderPayload(String payload) {
    final id = ReminderPayload.collectionId(payload);
    return id == null ? null : adhkarSessionPath(id);
  }

  /// Top-level tabs in navigation order. Must match the shell branches.
  static const List<AppRoute> tabs = [reader, duas, bookmarks, settings];
}
