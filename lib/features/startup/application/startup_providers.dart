import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router.dart';
import '../../settings/domain/app_settings.dart';
import '../data/last_tab_repository.dart';

/// Provides the last-tab store.
final lastTabRepositoryProvider = Provider<LastTabRepository>(
  (ref) => LocalLastTabRepository(SharedPreferencesAsync()),
);

/// Route the router opens first. `main` overrides it with the resolved value.
final initialLocationProvider = Provider<String>((ref) => AppRoute.reader.path);

/// Chooses the first route from the startup setting and the saved tab.
///
/// A saved path that is not a current top-level tab falls back to the Mushaf.
String resolveInitialLocation(StartupBehavior behavior, String? lastTabPath) {
  if (behavior == StartupBehavior.reader) return AppRoute.reader.path;
  final known = AppRoute.tabs.any((tab) => tab.path == lastTabPath);
  return known ? lastTabPath! : AppRoute.reader.path;
}
