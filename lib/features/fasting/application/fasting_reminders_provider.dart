import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../../../core/notifications/reminder_payload.dart';
import '../../../core/notifications/reminder_scheduler.dart';
import '../../../core/notifications/reminder_scheduler_provider.dart';
import '../../../core/time/ticking_clock.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../adhkar/application/reminders_provider.dart';
import '../../settings/application/digits_provider.dart';
import '../../settings/application/settings_provider.dart';
import '../data/fasting_repository.dart';
import '../domain/sunnah_fasts.dart';

/// Provides the store of the fasting reminders' choices. Tests override it.
final fastingRepositoryProvider = Provider<FastingRepository>(
  (ref) => LocalFastingRepository(SharedPreferencesAsync()),
);

/// The fasting reminders' choices; keeps the device's schedule in step with
/// them from the app's start.
final fastingRemindersProvider =
    AsyncNotifierProvider<FastingRemindersNotifier, FastingSettings>(
      FastingRemindersNotifier.new,
    );

/// Owns the fasting reminders: which sunnah fasts are reminded of, and when.
///
/// Each run plans the coming weeks afresh, as one notification the evening
/// before each fast. Android plans [androidDays] days; iOS, which keeps 64
/// pending notifications shared with the prayer alerts, [iosDays] days and
/// at most [iosLimit] reminders.
class FastingRemindersNotifier extends AsyncNotifier<FastingSettings> {
  FastingRepository get _repository => ref.read(fastingRepositoryProvider);
  ReminderScheduler get _scheduler => ref.read(reminderSchedulerProvider);
  Future<void> _queue = Future.value();

  /// How many days ahead Android plans.
  static const int androidDays = 60;

  /// How many days ahead iOS plans.
  static const int iosDays = 21;

  /// The most fasting reminders iOS is given.
  static const int iosLimit = 8;

  @override
  Future<FastingSettings> build() async {
    // A language change rebuilds this, so the scheduled words follow it.
    ref.watch(
      settingsProvider.select((value) => value.value?.localeCode ?? 'ar'),
    );
    final settings = await _repository.load();
    unawaited(_schedule(settings));
    return settings;
  }

  /// Turns the reminder of [fast] on or off. Turning it on asks for the
  /// notification permission first, so call it from the person's tap.
  Future<ReminderToggleResult> setFast(SunnahFast fast, bool on) async {
    if (on && !await _scheduler.requestPermission()) {
      return ReminderToggleResult.permissionDenied;
    }
    await _update(
      (settings) => settings.copyWith(
        fasts: on
            ? {...settings.fasts, fast}
            : ({...settings.fasts}..remove(fast)),
      ),
    );
    return on ? ReminderToggleResult.enabled : ReminderToggleResult.disabled;
  }

  /// Moves the reminders to [minutes] after midnight, the evening before.
  Future<void> setTime(int minutes) =>
      _update((settings) => settings.copyWith(minutes: minutes));

  Future<void> _update(FastingSettings Function(FastingSettings) change) async {
    final previous = state.value;
    if (previous == null) return;
    final next = change(previous);
    state = AsyncData(next);
    try {
      await _repository.save(next);
      await _schedule(next);
    } on Object catch (error) {
      AppLogger.debug('Fasting reminders failed: ${error.runtimeType}');
      state = AsyncData(previous);
    }
  }

  /// Replaces the planned reminders with those of [settings], one at a time
  /// so an older plan never lands after a newer one.
  Future<void> _schedule(FastingSettings settings) {
    final next = _queue.then((_) => _replace(settings));
    _queue = next;
    return next;
  }

  Future<void> _replace(FastingSettings settings) async {
    try {
      for (final id in await _scheduler.pendingIds()) {
        if (FastingPlan.owns(id)) await _scheduler.cancel(id);
      }
      final ios = defaultTargetPlatform == TargetPlatform.iOS;
      final reminders = FastingPlan.compute(
        now: ref.read(clockProvider)(),
        settings: settings,
        days: ios ? iosDays : androidDays,
      ).take(ios ? iosLimit : FastingPlan.maxDays);
      final language = ref.read(settingsProvider).value?.localeCode ?? 'ar';
      final l10n = lookupAppLocalizations(Locale(language));
      final digits = ref.read(digitsFormatterProvider);
      for (final reminder in reminders) {
        await _scheduler.scheduleOnce(
          id: reminder.id,
          at: reminder.at,
          title: l10n.fastingReminderTitle,
          body: fastingReminderBody(l10n, reminder, digits),
          channel: ReminderChannel.fasting,
          channelName: l10n.fastingChannelName,
          // The times of Fajr and Maghrib: when the fast begins and ends.
          payload: ReminderPayload.prayerTimes,
          settingsLabel: l10n.notificationSettings,
        );
      }
    } on Object catch (error) {
      AppLogger.debug('Fasting schedule failed: ${error.runtimeType}');
    }
  }
}

/// What the reminder of [reminder] says: a sentence for each reason the day
/// is a fast.
String fastingReminderBody(
  AppLocalizations l10n,
  FastReminder reminder,
  String Function(int) digits,
) => [
  for (final reason in reminder.reasons)
    switch (reason) {
      FastReason.arafah => l10n.fastingArafah,
      FastReason.tasua => l10n.fastingTasua,
      FastReason.ashura => l10n.fastingAshura,
      FastReason.shawwal => l10n.fastingShawwal,
      FastReason.whiteDay => l10n.fastingWhiteDay(digits(reminder.hijri.day)),
      FastReason.monday => l10n.fastingMonday,
      FastReason.thursday => l10n.fastingThursday,
    },
].join(' ');

/// The next day of each sunnah fast, from today, for the switches to show.
final fastingNextDaysProvider = Provider<Map<SunnahFast, DateTime?>>((ref) {
  final now = ref.watch(clockProvider)();
  return {
    for (final fast in SunnahFast.values)
      fast: FastingPlan.next(fast, now: now),
  };
});
