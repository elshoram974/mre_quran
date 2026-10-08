import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/prayer_times.dart';

/// The name of a calculation method.
String prayerMethodLabel(AppLocalizations l10n, PrayerMethod method) =>
    switch (method) {
      PrayerMethod.egyptian => l10n.methodEgyptian,
      PrayerMethod.muslimWorldLeague => l10n.methodMuslimWorldLeague,
      PrayerMethod.ummAlQura => l10n.methodUmmAlQura,
      PrayerMethod.karachi => l10n.methodKarachi,
      PrayerMethod.northAmerica => l10n.methodNorthAmerica,
      PrayerMethod.dubai => l10n.methodDubai,
      PrayerMethod.kuwait => l10n.methodKuwait,
      PrayerMethod.qatar => l10n.methodQatar,
      PrayerMethod.turkey => l10n.methodTurkey,
      PrayerMethod.singapore => l10n.methodSingapore,
    };

/// A time of day as the device formats it.
String formatPrayerTime(
  BuildContext context,
  DateTime time,
  String Function(String) formatDigits,
) => formatDigits(
  MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay(hour: time.hour, minute: time.minute)),
);

/// How long until [at], like "2 h 15 min" or "40 min".
String formatUntil(
  AppLocalizations l10n,
  Duration until,
  String Function(int) digits,
) {
  final minutes = until.inMinutes < 1 ? 1 : until.inMinutes;
  return minutes < 60
      ? l10n.prayerDurationMinutes(digits(minutes))
      : l10n.prayerDuration(digits(minutes ~/ 60), digits(minutes % 60));
}
