import 'dart:async';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../../../core/notifications/reminder_payload.dart';
import '../../../core/notifications/reminder_scheduler.dart';
import '../../../core/notifications/reminder_scheduler_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../adhkar/application/reminders_provider.dart';
import '../../settings/application/settings_provider.dart';
import '../data/custom_reminders_repository.dart';
import '../domain/custom_reminder.dart';

/// Provides the store of the reminders the person made. Tests override it.
final customRemindersRepositoryProvider = Provider<CustomRemindersRepository>(
  (ref) => LocalCustomRemindersRepository(SharedPreferencesAsync()),
);

/// The reminders the person made, in the order they were made.
final customRemindersProvider =
    AsyncNotifierProvider<CustomRemindersNotifier, List<CustomReminder>>(
      CustomRemindersNotifier.new,
    );

/// What saving a reminder came to.
enum ReminderSaveResult {
  /// Saved.
  saved,

  /// The person did not allow notifications, so it was saved switched off.
  permissionDenied,

  /// It cannot be saved as it is (see [CustomReminder.problem]), or the person
  /// has made as many as are allowed.
  refused,
}

/// Owns the reminders the person made, and keeps the device's schedule in step
/// with them.
class CustomRemindersNotifier extends AsyncNotifier<List<CustomReminder>> {
  CustomRemindersRepository get _repository =>
      ref.read(customRemindersRepositoryProvider);
  ReminderScheduler get _scheduler => ref.read(reminderSchedulerProvider);

  @override
  Future<List<CustomReminder>> build() async {
    // A language change rebuilds this, so the scheduled words follow it.
    final language = ref.watch(
      settingsProvider.select((value) => value.value?.localeCode ?? 'ar'),
    );
    final reminders = await _repository.load();
    for (final reminder in reminders) {
      unawaited(_sync(reminder, language));
    }
    return reminders;
  }

  /// Whether the person may make another reminder.
  bool get canAdd => (state.value?.length ?? 0) < CustomReminder.maxReminders;

  /// Saves [reminder]: a new one when no reminder has its id, else it replaces
  /// that one. One that comes asks for the notification permission first, so
  /// call it from the person's tap; without it the reminder is kept but off.
  Future<ReminderSaveResult> save(CustomReminder reminder) async {
    final current = state.value;
    if (current == null) return ReminderSaveResult.refused;
    var clean = reminder.normalized();
    final exists = current.any((item) => item.id == clean.id);
    if (clean.problem != null ||
        (!exists && current.length >= CustomReminder.maxReminders)) {
      return ReminderSaveResult.refused;
    }
    var result = ReminderSaveResult.saved;
    if (clean.enabled && !await _scheduler.requestPermission()) {
      clean = clean.copyWith(enabled: false);
      result = ReminderSaveResult.permissionDenied;
    }
    await _apply([
      if (exists)
        for (final item in current) item.id == clean.id ? clean : item
      else ...[...current, clean],
    ], changed: clean);
    return result;
  }

  /// Turns the reminder [id] on or off. Turning it on asks for the
  /// notification permission first, so call it from the person's tap.
  Future<ReminderToggleResult> setEnabled(String id, bool enabled) async {
    final current = state.value;
    final reminder = current?.where((item) => item.id == id).firstOrNull;
    if (current == null || reminder == null) {
      return ReminderToggleResult.disabled;
    }
    if (enabled && !await _scheduler.requestPermission()) {
      return ReminderToggleResult.permissionDenied;
    }
    final next = reminder.copyWith(enabled: enabled);
    await _apply([
      for (final item in current) item.id == id ? next : item,
    ], changed: next);
    return enabled
        ? ReminderToggleResult.enabled
        : ReminderToggleResult.disabled;
  }

  /// Deletes the reminder [id] and takes it off the schedule.
  Future<void> remove(String id) async {
    final current = state.value;
    final reminder = current?.where((item) => item.id == id).firstOrNull;
    if (current == null || reminder == null) return;
    await _apply([
      for (final item in current)
        if (item.id != id) item,
    ], removed: reminder);
  }

  Future<void> _apply(
    List<CustomReminder> next, {
    CustomReminder? changed,
    CustomReminder? removed,
  }) async {
    final previous = state.value;
    state = AsyncData(next);
    try {
      await _repository.save(next);
      final language = ref.read(settingsProvider).value?.localeCode ?? 'ar';
      if (removed != null) await _cancelAll(removed.id);
      if (changed != null) await _sync(changed, language);
    } on Object catch (error) {
      AppLogger.debug('Reminder update failed: ${error.runtimeType}');
      state = AsyncData(previous ?? const []);
    }
  }

  /// The notification id of moment [index] of the reminder [id].
  static int notificationId(String id, int index) =>
      ReminderPayload.notificationId('custom:$id:$index');

  Future<void> _cancelAll(String id) async {
    for (var index = 0; index < CustomReminder.maxSlots; index++) {
      await _scheduler.cancel(notificationId(id, index));
    }
  }

  /// Puts the schedule of [reminder] right: all its moments cleared, and its
  /// current ones set when it is on.
  Future<void> _sync(CustomReminder reminder, String language) async {
    try {
      await _cancelAll(reminder.id);
      if (!reminder.enabled) return;
      final l10n = lookupAppLocalizations(Locale(language));
      final slots = reminder.slots;
      for (var index = 0; index < slots.length; index++) {
        final slot = slots[index];
        await _scheduler.schedule(
          id: notificationId(reminder.id, index),
          minutes: slot.minutes,
          weekday: slot.weekday,
          dayOfMonth: slot.dayOfMonth,
          title: reminder.title,
          body: reminder.note.isEmpty ? l10n.customReminderBody : reminder.note,
          channel: ReminderChannel.custom,
          channelName: l10n.customReminderChannel,
          payload: ReminderPayload.remindersSettings,
          settingsLabel: l10n.notificationSettings,
        );
      }
    } on Object catch (error) {
      AppLogger.debug('Reminder schedule failed: ${error.runtimeType}');
    }
  }
}
