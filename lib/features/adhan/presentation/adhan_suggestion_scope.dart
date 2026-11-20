import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/hints/hints.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/time/ticking_clock.dart';
import '../../../core/widgets/app_hint_sheet.dart';
import '../../prayer/application/prayer_provider.dart';
import '../../startup/application/startup_providers.dart';
import '../application/adhan_providers.dart';
import '../application/adhan_suggestion.dart';

/// Offers setup after startup, only when prayer alerts or adhan are off.
class AdhanSuggestionScope extends ConsumerStatefulWidget {
  const AdhanSuggestionScope({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AdhanSuggestionScope> createState() =>
      _AdhanSuggestionScopeState();
}

class _AdhanSuggestionScopeState extends ConsumerState<AdhanSuggestionScope> {
  Timer? _timer;
  int _attempts = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_offer()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _offer() async {
    if (_checking || !mounted) return;
    if (++_attempts > 12) {
      _timer?.cancel();
      return;
    }
    if (!ref.read(startupReadyProvider)) {
      return;
    }
    final router = ref.read(routerProvider);
    final initialPath = ref.read(initialLocationProvider);
    if (initialPath == AppRoute.reader.path &&
        !ref.read(opensOnReaderProvider)) {
      return;
    }
    final navigator = router.routerDelegate.navigatorKey.currentState;
    if (router.routeInformationProvider.value.uri.path != initialPath ||
        navigator == null ||
        navigator.canPop()) {
      return;
    }
    _checking = true;
    try {
      final prayer = await ref.read(prayerProvider.future);
      final adhan = await ref.read(adhanSettingsProvider.future);
      final hints = await ref.read(hintsProvider.future);
      final store = ref.read(adhanSuggestionStoreProvider);
      final last = await store.lastShown();
      final now = ref.read(clockProvider)();
      if (!mounted ||
          !hints.allows(AppHint.configureAdhan) ||
          !shouldSuggestAdhan(
            alertsEnabled: prayer.settings.alerts.isNotEmpty,
            adhanEnabled: adhan.playAdhan,
            now: now,
            lastShown: last,
          )) {
        _timer?.cancel();
        return;
      }
      if (router.routeInformationProvider.value.uri.path != initialPath ||
          navigator.canPop()) {
        return;
      }
      final context = navigator.context;
      if (!context.mounted) return;
      final l10n = context.l10n;
      await store.markShown(now);
      if (!mounted ||
          !context.mounted ||
          navigator.canPop() ||
          router.routeInformationProvider.value.uri.path != initialPath) {
        return;
      }
      _timer?.cancel();
      final accepted = await showAppHint(
        context,
        ref,
        hint: AppHint.configureAdhan,
        icon: Icons.notifications_active_outlined,
        title: l10n.adhanSuggestionTitle,
        body: l10n.adhanSuggestionBody,
        action: l10n.adhanSuggestionAction,
      );
      if (accepted && mounted) router.go(AppRoute.prayerTimes.path);
    } on Object {
      // A failed settings read should never interrupt startup.
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
