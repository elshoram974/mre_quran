import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;
import 'package:intl/intl.dart' show DateFormat;

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
        (_, _) => _scheduleSync(),
      ),
      ref.listenManual(
        settingsProvider.select((value) => value.value?.useArabicDigits),
        (_, _) => _scheduleSync(),
      ),
      ref.listenManual(
        settingsProvider.select((value) => value.value?.localeCode),
        (_, _) => _scheduleSync(),
      ),
      ref.listenManual(
        settingsProvider.select((value) => value.value?.widgetSeconds),
        (_, _) => _scheduleSync(),
      ),
      ref.listenManual(
        settingsProvider.select((value) => value.value?.widgetLanguage),
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

  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      // Locale changes may temporarily remove delegates while they reload.
      // didChangeDependencies schedules another update when they are ready.
      if (Localizations.of<MaterialLocalizations>(
                context,
                MaterialLocalizations,
              ) ==
              null ||
          Localizations.of<AppLocalizations>(context, AppLocalizations) ==
              null) {
        return;
      }
      unawaited(_sync(ref.read(nextPrayerProvider)));
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    super.dispose();
  }

  Future<void> _sync(NextPrayer? next) async {
    final settings = ref.read(settingsProvider).value;
    final prayer = ref.read(prayerProvider);
    // Still loading: the widgets keep the times they have. Clearing them here
    // would blank a correct widget every time the app opens.
    if (settings == null || !prayer.hasValue) return;
    final day = ref.read(prayerDayProvider);
    if (next == null || day == null) {
      // Loaded, and there is no place to compute times for.
      return PrayerWidgetSync.update(null);
    }
    // The widgets speak their own language when one was chosen for them: the
    // words, the dates and the clock, and the way the text reads.
    final language = settings.widgetLanguage;
    await initializeDateFormatting(language);
    if (!mounted) return;
    final l10n = lookupAppLocalizations(Locale(language));
    // From the settings just read: the shared formatter provider can still hold
    // the previous choice while this runs for a settings change.
    String digits(String value) =>
        formatDisplayDigits(value, arabic: settings.useArabicDigits);
    String clock(DateTime at) => digits(DateFormat.jm(language).format(at));
    final state = prayer.value;
    final place = state?.place;
    final method = state?.method;
    return PrayerWidgetSync.update(
      PrayerWidgetData(
        prayer: next.prayer,
        label: l10n.prayerNext,
        title: prayerName(l10n, next.prayer),
        time: clock(next.at),
        at: next.at,
        useArabicDigits: settings.useArabicDigits,
        rtl: language == 'ar',
        seconds: settings.widgetSeconds,
        labels: PrayerWidgetLabels(
          next: l10n.prayerNext,
          remaining: l10n.prayerIn(r'%1$s'),
          hours: l10n.prayerDuration(r'%1$s', r'%2$s'),
          minutes: l10n.prayerDurationMinutes(r'%1$s'),
          empty: l10n.prayerWidgetEmpty,
        ),
        days: place == null || method == null
            ? const []
            : _days(l10n, language, clock, place, method, digits),
        times: [
          for (final prayer in DailyPrayer.values)
            PrayerWidgetTime(
              name: prayerName(l10n, prayer),
              time: clock(day.of(prayer)),
            ),
        ],
      ),
    );
  }

  /// A week of times, so the widgets keep up without the app.
  List<PrayerWidgetDay> _days(
    AppLocalizations l10n,
    String language,
    String Function(DateTime) clock,
    PrayerPlace place,
    PrayerMethod method,
    String Function(String) digits,
  ) {
    final today = ref.read(clockProvider)();
    final dateFormat = DateFormat.MMMEd(language);
    return [
      for (var offset = 0; offset < _daysAhead; offset++)
        _day(
          l10n,
          dateFormat,
          clock,
          place,
          method,
          digits,
          DateTime(today.year, today.month, today.day + offset),
        ),
    ];
  }

  PrayerWidgetDay _day(
    AppLocalizations l10n,
    DateFormat dateFormat,
    String Function(DateTime) clock,
    PrayerPlace place,
    PrayerMethod method,
    String Function(String) digits,
    DateTime date,
  ) {
    final times = PrayerDay.compute(place, method, date);
    PrayerWidgetRow row(String id, String name, DateTime at) =>
        PrayerWidgetRow(id: id, name: name, time: clock(at), at: at);
    return PrayerWidgetDay(
      start: date,
      end: DateTime(date.year, date.month, date.day + 1),
      dateLabel: digits(dateFormat.format(date)),
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
