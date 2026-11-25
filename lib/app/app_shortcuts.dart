import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_actions/quick_actions.dart';

import '../core/l10n/l10n.dart';
import '../features/startup/application/startup_providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'reminder_opener.dart';
import 'router.dart';

/// The shortcuts a long press on the app's icon offers.
enum AppShortcut {
  /// The prayer times, with the adhan.
  prayerTimes('ic_shortcut_prayer'),

  /// The Qibla compass.
  qibla('ic_shortcut_qibla'),

  /// The adhkar and duas.
  adhkar('ic_shortcut_adhkar'),

  /// The Mushaf, at the page last read.
  reader('ic_shortcut_reader');

  const AppShortcut(this.icon);

  /// The icon's name: an Android drawable and an iOS image set, drawn by
  /// `tool/app_icon/render_shortcut_icons_test.dart`.
  final String icon;

  /// The shortcut's name in [l10n].
  String title(AppLocalizations l10n) => switch (this) {
    AppShortcut.prayerTimes => l10n.shortcutPrayer,
    AppShortcut.qibla => l10n.qiblaTitle,
    AppShortcut.adhkar => l10n.shortcutAdhkar,
    AppShortcut.reader => l10n.shortcutReader,
  };

  /// Opens the shortcut's screen with [router], over no sheet left open.
  Future<void> open(GoRouter router) async {
    closeOpenSheets(router);
    switch (this) {
      case AppShortcut.prayerTimes:
        router.go(AppRoute.prayerTimes.path);
      case AppShortcut.qibla:
        await router.push<void>(AppRoute.qibla.path);
      case AppShortcut.adhkar:
        router.go(AppRoute.duas.path);
      case AppShortcut.reader:
        router.go(AppRoute.reader.path);
    }
  }
}

/// The system's quick actions. Tests replace it.
final quickActionsProvider = Provider<QuickActions>(
  (ref) => const QuickActions(),
);

/// Offers the [AppShortcut]s on the app's icon, named in the app's language,
/// and opens the one tapped, also when it is what started the app.
class AppShortcutsScope extends ConsumerStatefulWidget {
  /// Creates the scope over [child].
  const AppShortcutsScope({super.key, required this.child});

  /// The app.
  final Widget child;

  @override
  ConsumerState<AppShortcutsScope> createState() => _AppShortcutsScopeState();
}

class _AppShortcutsScopeState extends ConsumerState<AppShortcutsScope> {
  String? _language;

  @override
  void initState() {
    super.initState();
    unawaited(
      ref.read(quickActionsProvider).initialize((type) {
        for (final shortcut in AppShortcut.values) {
          if (shortcut.name == type) {
            if (shortcut != AppShortcut.reader) {
              ref.read(opensOnReaderProvider.notifier).openedElsewhere();
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) unawaited(shortcut.open(ref.read(routerProvider)));
            });
            WidgetsBinding.instance.ensureVisualUpdate();
          }
        }
      }),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = context.l10n;
    // Named again only when the language changes.
    if (l10n.localeName == _language) return;
    _language = l10n.localeName;
    unawaited(
      ref.read(quickActionsProvider).setShortcutItems([
        for (final shortcut in AppShortcut.values)
          ShortcutItem(
            type: shortcut.name,
            localizedTitle: shortcut.title(l10n),
            icon: shortcut.icon,
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
