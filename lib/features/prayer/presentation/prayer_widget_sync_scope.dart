import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../settings/application/digits_provider.dart';
import '../../settings/application/settings_provider.dart';
import '../application/prayer_provider.dart';
import '../application/prayer_widget_sync.dart';
import '../domain/prayer_times.dart';
import 'prayer_labels.dart';

/// Keeps the native widget's cached next-prayer payload in sync with Flutter.
class PrayerWidgetSyncScope extends ConsumerStatefulWidget {
  const PrayerWidgetSyncScope({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PrayerWidgetSyncScope> createState() =>
      _PrayerWidgetSyncScopeState();
}

class _PrayerWidgetSyncScopeState extends ConsumerState<PrayerWidgetSyncScope> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(nextPrayerProvider, (_, value) => unawaited(_sync(value)));
    ref.listenManual(
      settingsProvider.select((value) => value.value?.useArabicDigits),
      (_, _) => unawaited(_sync(ref.read(nextPrayerProvider))),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_sync(ref.read(nextPrayerProvider)));
    });
  }

  Future<void> _sync(NextPrayer? next) {
    final settings = ref.read(settingsProvider).value;
    final day = ref.read(prayerDayProvider);
    if (next == null || settings == null || day == null) {
      return PrayerWidgetSync.update(null);
    }
    final l10n = context.l10n;
    final digits = ref.read(displayDigitsFormatterProvider);
    return PrayerWidgetSync.update(
      PrayerWidgetData(
        prayer: next.prayer,
        label: l10n.prayerNext,
        title: prayerName(l10n, next.prayer),
        time: formatPrayerTime(context, next.at, digits),
        at: next.at,
        useArabicDigits: settings.useArabicDigits,
        times: [
          for (final prayer in DailyPrayer.values)
            PrayerWidgetTime(
              name: prayerName(l10n, prayer),
              time: formatPrayerTime(context, day.of(prayer), digits),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
