import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/time/ticking_clock.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/digits_provider.dart';
import '../../settings/application/settings_provider.dart';
import '../application/prayer_provider.dart';
import '../application/prayer_widget_sync.dart';
import '../domain/hijri_date.dart';
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
  final List<ProviderSubscription<dynamic>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _subscriptions.addAll([
      ref.listenManual<NextPrayer?>(
        nextPrayerProvider,
        (_, NextPrayer? value) => unawaited(_sync(value)),
      ),
      ref.listenManual(
        settingsProvider.select((value) => value.value?.useArabicDigits),
        (_, _) => unawaited(_sync(ref.read(nextPrayerProvider))),
      ),
      ref.listenManual(
        settingsProvider.select((value) => value.value?.localeCode),
        (_, _) => unawaited(_sync(ref.read(nextPrayerProvider))),
      ),
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_sync(ref.read(nextPrayerProvider)));
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    super.dispose();
  }

  Future<void> _sync(NextPrayer? next) {
    final settings = ref.read(settingsProvider).value;
    final day = ref.read(prayerDayProvider);
    if (next == null || settings == null || day == null) {
      return PrayerWidgetSync.update(null);
    }
    final l10n = context.l10n;
    // From the settings just read: the shared formatter provider can still hold
    // the previous choice while this runs for a settings change.
    String digits(String value) =>
        formatDisplayDigits(value, arabic: settings.useArabicDigits);
    final state = ref.read(prayerProvider).value;
    final place = state?.place;
    final method = state?.method;
    return PrayerWidgetSync.update(
      PrayerWidgetData(
        prayer: next.prayer,
        label: l10n.prayerNext,
        title: prayerName(l10n, next.prayer),
        time: formatPrayerTime(context, next.at, digits),
        at: next.at,
        useArabicDigits: settings.useArabicDigits,
        rtl: Directionality.of(context) == TextDirection.rtl,
        labels: PrayerWidgetLabels(
          next: l10n.prayerNext,
          remaining: l10n.prayerIn(r'%1$s'),
          hours: l10n.prayerDuration(r'%1$s', r'%2$s'),
          minutes: l10n.prayerDurationMinutes(r'%1$s'),
          empty: l10n.prayerWidgetEmpty,
        ),
        days: place == null || method == null
            ? const []
            : _days(l10n, place, method, digits),
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

  /// A week of times, so the widgets keep up without the app.
  List<PrayerWidgetDay> _days(
    AppLocalizations l10n,
    PrayerPlace place,
    PrayerMethod method,
    String Function(String) digits,
  ) {
    final today = ref.read(clockProvider)();
    final material = MaterialLocalizations.of(context);
    return [
      for (var offset = 0; offset < _daysAhead; offset++)
        _day(
          l10n,
          material,
          place,
          method,
          digits,
          DateTime(today.year, today.month, today.day + offset),
        ),
    ];
  }

  PrayerWidgetDay _day(
    AppLocalizations l10n,
    MaterialLocalizations material,
    PrayerPlace place,
    PrayerMethod method,
    String Function(String) digits,
    DateTime date,
  ) {
    final times = PrayerDay.compute(place, method, date);
    PrayerWidgetRow row(String id, String name, DateTime at) => PrayerWidgetRow(
      id: id,
      name: name,
      time: formatPrayerTime(context, at, digits),
      at: at,
    );
    return PrayerWidgetDay(
      start: date,
      end: DateTime(date.year, date.month, date.day + 1),
      dateLabel: digits(material.formatMediumDate(date)),
      hijriLabel: hijriLabel(l10n, HijriDate.of(date), digits),
      rows: [
        row('fajr', l10n.prayerFajr, times.fajr),
        row('sunrise', l10n.prayerSunrise, times.sunrise),
        row('dhuhr', l10n.prayerDhuhr, times.dhuhr),
        row('asr', l10n.prayerAsr, times.asr),
        row('maghrib', l10n.prayerMaghrib, times.maghrib),
        row('isha', l10n.prayerIsha, times.isha),
      ],
    );
  }

  /// How many days of times are sent.
  static const int _daysAhead = 7;

  @override
  Widget build(BuildContext context) => widget.child;
}
