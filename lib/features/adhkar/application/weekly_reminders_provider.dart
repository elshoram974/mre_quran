import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../../../core/notifications/reminder_payload.dart';
import '../../../core/notifications/reminder_scheduler.dart';
import '../../../core/notifications/reminder_scheduler_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/settings_provider.dart';
import '../data/reminders_repository.dart';
import '../domain/reminder_setting.dart';
import '../domain/weekly_reminder.dart';
import 'reminders_provider.dart';

/// Where the weekly reminders are defined.
const String weeklyRemindersAsset = 'assets/reminders/weekly.json';

/// The weekly reminders the app offers, read from [weeklyRemindersAsset].
final weeklyReminderCatalogProvider = FutureProvider<List<WeeklyReminder>>((
  ref,
) async {
  try {
    final text = await rootBundle.loadString(weeklyRemindersAsset);
    return parseWeeklyReminders(jsonDecode(text));
  } on Object catch (error) {
    AppLogger.debug('Weekly reminders unreadable: ${error.runtimeType}');
    return const [];
  }
});

/// Provides the store of the weekly reminders' choices.
final weeklyRemindersRepositoryProvider = Provider<RemindersRepository>(
  (ref) => LocalRemindersRepository(
    SharedPreferencesAsync(),
    key: 'adhkar.weekly_reminders',
  ),
);

/// The choice for every weekly reminder, by id: what the file says until the
/// person chooses, at its default time.
final weeklyRemindersProvider =
    AsyncNotifierProvider<
      WeeklyRemindersNotifier,
      Map<String, ReminderSetting>
    >(WeeklyRemindersNotifier.new);

/// Owns the weekly reminders and keeps the device schedule in step with them.
class WeeklyRemindersNotifier
    extends AsyncNotifier<Map<String, ReminderSetting>> {
  RemindersRepository get _repository =>
      ref.read(weeklyRemindersRepositoryProvider);
  ReminderScheduler get _scheduler => ref.read(reminderSchedulerProvider);

  @override
  Future<Map<String, ReminderSetting>> build() async {
    // A language change rebuilds this, so the scheduled words follow it.
    final language = ref.watch(
      settingsProvider.select((value) => value.value?.localeCode ?? 'ar'),
    );
    final catalog = await ref.watch(weeklyReminderCatalogProvider.future);
    final saved = await _repository.load();
    final settings = {
      for (final reminder in catalog)
        reminder.id:
            saved[reminder.id] ??
            ReminderSetting(
              enabled: reminder.enabledByDefault,
              minutes: reminder.minutes,
            ),
    };
    for (final reminder in catalog) {
      if (settings[reminder.id]!.enabled) {
        unawaited(_sync(reminder, settings[reminder.id]!, language));
      }
    }
    return settings;
  }

  /// Turns [reminder] on or off. Turning it on asks for the notification
  /// permission first, so call it from the person's tap.
  Future<ReminderToggleResult> setEnabled(
    WeeklyReminder reminder,
    bool enabled,
  ) async {
    if (enabled && !await _scheduler.requestPermission()) {
      return ReminderToggleResult.permissionDenied;
    }
    await _update(reminder, (setting) => setting.copyWith(enabled: enabled));
    return enabled
        ? ReminderToggleResult.enabled
        : ReminderToggleResult.disabled;
  }

  /// Moves [reminder] to [minutes] after midnight.
  Future<void> setTime(WeeklyReminder reminder, int minutes) =>
      _update(reminder, (setting) => setting.copyWith(minutes: minutes));

  Future<void> _update(
    WeeklyReminder reminder,
    ReminderSetting Function(ReminderSetting) change,
  ) async {
    final previous = state.value;
    final current = previous?[reminder.id];
    if (previous == null || current == null) return;
    final next = {...previous, reminder.id: change(current)};
    state = AsyncData(next);
    try {
      await _repository.save(next);
      await _sync(
        reminder,
        next[reminder.id]!,
        ref.read(settingsProvider).value?.localeCode ?? 'ar',
      );
    } on Object catch (error) {
      AppLogger.debug('Weekly reminder update failed: ${error.runtimeType}');
      state = AsyncData(previous);
    }
  }

  Future<void> _sync(
    WeeklyReminder reminder,
    ReminderSetting setting,
    String language,
  ) async {
    final id = ReminderPayload.notificationId('weekly:${reminder.id}');
    try {
      if (!setting.enabled) {
        await _scheduler.cancel(id);
        return;
      }
      final l10n = lookupAppLocalizations(Locale(language));
      await _scheduler.schedule(
        id: id,
        minutes: setting.minutes,
        weekday: reminder.weekday,
        title: reminder.title(language),
        body: reminder.body(language),
        channelName: l10n.adhkarReminderChannel,
        payload: reminder.surah == null
            ? ReminderPayload.adhkarHome
            : ReminderPayload.forSurah(reminder.surah!),
      );
    } on Object catch (error) {
      AppLogger.debug('Weekly reminder schedule failed: ${error.runtimeType}');
    }
  }
}
