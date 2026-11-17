import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router.dart';
import '../../quran_text/application/quran_text_providers.dart';
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

/// Whether the Mushaf has put its first page on screen: its artwork, the
/// text standing in for it, or a notice that it cannot be had.
final readerPaintedProvider = NotifierProvider<ReaderPainted, bool>(
  ReaderPainted.new,
);

/// Notes the Mushaf's first page on screen.
class ReaderPainted extends Notifier<bool> {
  @override
  bool build() => false;

  /// Called by a page view once it shows something other than a
  /// placeholder.
  void painted() {
    if (!state) state = true;
  }
}

/// Whether the first screen is ready to be seen, so the splash can give way
/// without any loading showing: the Quran text is read and, when the app
/// opens on the Mushaf, its page is on screen. The text and the page load at
/// the same time, both behind the splash.
final startupReadyProvider = Provider<bool>((ref) {
  final text = ref.watch(quranTextProvider);
  final read = text.hasValue || text.hasError;
  if (ref.watch(initialLocationProvider) != AppRoute.reader.path) return read;
  return read && ref.watch(readerPaintedProvider);
});
