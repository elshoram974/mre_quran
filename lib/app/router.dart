import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/about/presentation/about_page.dart';
import '../features/bookmarks/presentation/bookmarks_page.dart';
import '../features/duas/presentation/duas_page.dart';
import '../features/mushaf/presentation/mushaf_page.dart';
import '../features/quran_index/presentation/quran_index_page.dart';
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
        path: AppRoute.quranIndex.path,
        builder: (context, state) => const QuranIndexPage(),
      ),
      GoRoute(
        path: AppRoute.about.path,
        builder: (context, state) => const AboutPage(),
      ),
    ],
  );
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
  quranIndex('/quran-index');

  const AppRoute(this.path);
  final String path;

  /// Top-level tabs in navigation order. Must match the shell branches.
  static const List<AppRoute> tabs = [reader, duas, bookmarks, settings];
}
