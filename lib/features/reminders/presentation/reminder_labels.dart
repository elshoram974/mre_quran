import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/custom_reminder.dart';

/// A time of day as the device formats it.
String formatReminderTime(
  BuildContext context,
  int minutes,
  String Function(String) formatDigits,
) => formatDigits(
  MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60)),
);

/// The name of weekday [weekday] (1 Monday to 7 Sunday) in [locale].
String weekdayName(String locale, int weekday) =>
    // 1 January 2024 was a Monday.
    DateFormat.EEEE(locale).format(DateTime(2024, 1, weekday));

/// When [reminder] repeats, in words: "every day", "every Monday, Thursday",
/// "on day 15 of every month".
String reminderWhen(
  AppLocalizations l10n,
  CustomReminder reminder,
  String locale,
  String Function(String) formatDigits,
) => switch (reminder.repeat) {
  ReminderRepeat.daily => l10n.reminderEveryDay,
  ReminderRepeat.weekly when reminder.weekdays.length == 7 =>
    l10n.reminderEveryDay,
  ReminderRepeat.weekly => l10n.reminderWeeklyOn(
    [
      for (final day in (reminder.weekdays.toList()..sort()))
        weekdayName(locale, day),
    ].join(locale.startsWith('ar') ? '، ' : ', '),
  ),
  ReminderRepeat.monthly => l10n.reminderMonthlyOn(
    formatDigits('${reminder.dayOfMonth}'),
  ),
};

/// One line saying when [reminder] comes: its days, then its times.
String reminderSummaryLine(
  BuildContext context,
  CustomReminder reminder,
  String Function(String) formatDigits,
) {
  final locale = Localizations.localeOf(context).toString();
  final l10n = AppLocalizations.of(context);
  return l10n.reminderSummary(
    reminderWhen(l10n, reminder, locale, formatDigits),
    [
      for (final time in reminder.times)
        formatReminderTime(context, time, formatDigits),
    ].join(locale.startsWith('ar') ? '، ' : ', '),
  );
}
