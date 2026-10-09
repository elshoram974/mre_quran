import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/notifications/reminder_payload.dart';
import '../../../core/time/ticking_clock.dart';
import '../../settings/application/settings_provider.dart';
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
  @override
  void initState() {
    super.initState();
    ref.listenManual(adhkarCatalogProvider, (_, _) => _scheduleSync());
    ref.listenManual(adhkarProgressProvider, (_, _) => _scheduleSync());
    ref.listenManual(tickingNowProvider, (_, _) => _scheduleSync());
    ref.listenManual(
      settingsProvider.select((value) => value.value?.localeCode),
      (_, _) => _scheduleSync(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleSync());
  }

  void _scheduleSync() => unawaited(_sync());

  Future<void> _sync() {
    final catalog = ref.read(adhkarCatalogProvider).value;
    final progress = ref.read(adhkarProgressProvider).value;
    final now = ref.read(tickingNowProvider);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
