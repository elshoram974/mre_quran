import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;
import 'package:intl/intl.dart' show DateFormat;

import '../../../l10n/generated/app_localizations.dart';
import '../../prayer/application/prayer_provider.dart';
import '../../prayer/domain/hijri_date.dart';
import '../../prayer/domain/prayer_times.dart';
import '../../prayer/presentation/prayer_labels.dart';
import '../../settings/application/digits_provider.dart';
import '../../settings/application/settings_provider.dart';
import '../../../core/time/ticking_clock.dart';
import '../domain/widget_preview_data.dart';

/// What the previews of the home-screen widgets say, in the language the
/// widgets speak. With a place saved it is today's real times and the real
/// time left; without one, the sample day the widget picker shows.
final widgetPreviewDataProvider = FutureProvider.autoDispose<WidgetPreviewData>(
  (ref) async {
    final settings = await ref.watch(settingsProvider.future);
    final language = settings.widgetLanguage;
    await initializeDateFormatting(language);
    final l10n = lookupAppLocalizations(Locale(language));
    String digits(String value) =>
        formatDisplayDigits(value, arabic: settings.useArabicDigits);
    String clock(DateTime at) => digits(DateFormat.jm(language).format(at));

    final now = ref.read(clockProvider)();
    final day = ref.watch(prayerDayProvider);
    final next = ref.watch(nextPrayerProvider);
    final real = day != null && next != null;
    final today = real ? day : _sampleDay(now);
    final coming = real ? next.prayer : DailyPrayer.asr;
    final left = real
        ? next.at.difference(now)
        : const Duration(hours: 1, minutes: 24);

    WidgetPreviewRow row(String id, String name, DateTime at) =>
        WidgetPreviewRow(id: id, name: name, time: clock(at));
    return WidgetPreviewData(
      language: language,
      rtl: language == 'ar',
      rows: [
        row('fajr', l10n.prayerFajr, today.fajr),
        row('sunrise', l10n.prayerSunrise, today.sunrise),
        row('dhuhr', l10n.prayerDhuhr, today.dhuhr),
        row('asr', l10n.prayerAsr, today.asr),
        row('maghrib', l10n.prayerMaghrib, today.maghrib),
        row('isha', l10n.prayerIsha, today.isha),
      ],
      nextId: coming.name,
      nextLabel: l10n.prayerNext,
      date: digits(DateFormat.MMMEd(language).format(now)),
      hijri: hijriLabel(
        l10n,
        HijriDate.of(now, shift: ref.watch(hijriShiftProvider)),
        digits,
      ),
      remaining: l10n.prayerIn(
        formatUntil(l10n, left, (value) => digits('$value')),
      ),
      tasbihName: l10n.widgetTasbih,
      tasbihCount: digits('33'),
      dhikrName: l10n.widgetDhikr,
      dhikrCount: l10n.adhkarProgress(digits('3'), digits('12')),
      dhikrTitle: l10n.widgetPreviewAdhkarTitle,
    );
  },
);

/// The day the widget picker shows before there is a place: Asr coming.
PrayerDay _sampleDay(DateTime now) {
  DateTime at(int hour, int minute) =>
      DateTime(now.year, now.month, now.day, hour, minute);
  return PrayerDay(
    fajr: at(5, 27),
    sunrise: at(6, 54),
    dhuhr: at(12, 44),
    asr: at(16, 2),
    maghrib: at(18, 32),
    isha: at(19, 49),
  );
}
