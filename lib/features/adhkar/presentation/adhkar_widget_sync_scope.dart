import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/notifications/reminder_payload.dart';
import '../../../core/time/ticking_clock.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/application/digits_provider.dart';
import '../application/adhkar_providers.dart';
import '../application/adhkar_widget_sync.dart';
import '../domain/adhkar_collection.dart';

/// Keeps the native suggested-dhikr widget in step with saved adhkar progress.
class AdhkarWidgetSyncScope extends ConsumerStatefulWidget {
  const AdhkarWidgetSyncScope({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AdhkarWidgetSyncScope> createState() =>
      _AdhkarWidgetSyncScopeState();
}

class _AdhkarWidgetSyncScopeState extends ConsumerState<AdhkarWidgetSyncScope> {
  final List<ProviderSubscription<dynamic>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _subscriptions.addAll([
      ref.listenManual(adhkarCatalogProvider, (_, _) => _scheduleSync()),
      ref.listenManual(adhkarProgressProvider, (_, _) => _scheduleSync()),
      ref.listenManual(
        settingsProvider.select((value) => value.value?.localeCode),
        (_, _) => _scheduleSync(),
      ),
      ref.listenManual(
        settingsProvider.select((value) => value.value?.useArabicDigits),
        (_, _) => _scheduleSync(),
      ),
    ]);
  }

  bool _syncScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Localizations.maybeLocaleOf(context);
    _scheduleSync();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    super.dispose();
  }

  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted ||
          Localizations.of<AppLocalizations>(context, AppLocalizations) ==
              null) {
        return;
      }
      unawaited(_sync());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _sync() {
    final catalog = ref.read(adhkarCatalogProvider).value;
    final progress = ref.read(adhkarProgressProvider).value;
    final now = ref.read(clockProvider)();
    final settings = ref.read(settingsProvider).value;
    if (catalog == null || progress == null || settings == null) {
      return AdhkarWidgetSync.update(null);
    }
    final settled = progress.settle(catalog.collections, now);
    final active = ref.read(activeSessionProvider);
    final collection =
        active ?? catalog.suggestedAt(now.hour * 60 + now.minute);
    if (collection == null) return AdhkarWidgetSync.update(null);
    final l10n = context.l10n;
    return AdhkarWidgetSync.update(
      AdhkarWidgetData(
        label: active == null ? l10n.adhkarSuggested : l10n.adhkarResume,
        title: collection.title(settings.localeCode),
        done: settled.doneRepeats(collection),
        total: collection.totalRepeats,
        payload: ReminderPayload.forCollection(collection.id),
        rtl: Directionality.of(context) == TextDirection.rtl,
        progressLabel: l10n.adhkarProgress(
          formatDigits(
            settled.doneRepeats(collection),
            arabic: settings.useArabicDigits,
          ),
          formatDigits(
            collection.totalRepeats,
            arabic: settings.useArabicDigits,
          ),
        ),
        useArabicDigits: settings.useArabicDigits,
        tasbihLabel: l10n.widgetTasbih,
        tasbihResetLabel: l10n.widgetTasbihReset,
        tasbihCountLabel: l10n.widgetTasbihCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
