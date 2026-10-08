import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../../../core/notifications/reminder_payload.dart';
import '../../../core/notifications/reminder_scheduler.dart';
import '../../../core/notifications/reminder_scheduler_provider.dart';
import '../../../core/time/ticking_clock.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/settings_provider.dart';
import '../data/location_source.dart';
import '../data/prayer_repository.dart';
import '../domain/prayer_alerts.dart';
import '../domain/prayer_times.dart';

/// Provides the prayer store.
final prayerRepositoryProvider = Provider<PrayerRepository>(
  (ref) => LocalPrayerRepository(SharedPreferencesAsync()),
);

/// Provides the location source. Tests override it.
final locationSourceProvider = Provider<LocationSource>(
  (ref) => const GeolocatorLocationSource(),
);

/// The id of the adhkar list the after-prayer reminder opens.
const String afterPrayerCollectionId = 'after_prayer';

/// The prayer choices and where the person is.
@immutable
class PrayerState {
  /// Creates the state.
  const PrayerState({required this.settings, this.place});

  /// The person's choices.
  final PrayerSettings settings;

  /// The last place worked out, if any.
  final PrayerPlace? place;

  /// The method in use: the one chosen, else the one that fits the place.
  /// Null while there is no place.
  PrayerMethod? get method {
    final here = place;
    if (here == null) return null;
    return settings.method ?? PrayerMethod.forPlace(here);
  }
}

/// Outcome of an action that needs a permission.
enum PrayerResult {
  /// Done.
  ok,

  /// The person did not allow notifications.
  notificationsDenied,

  /// The person did not allow location, so there are no prayer times.
  locationDenied,
}

/// The prayer choices, the place, and the notifications that follow them.
final prayerProvider = AsyncNotifierProvider<PrayerNotifier, PrayerState>(
  PrayerNotifier.new,
);

/// Today's times at the person's place, read again as the day moves.
final prayerDayProvider = Provider<PrayerDay?>((ref) {
  final state = ref.watch(prayerProvider).value;
  final method = state?.method;
  final place = state?.place;
  if (place == null || method == null) return null;
  final now = ref.watch(tickingNowProvider);
  return PrayerDay.compute(place, method, now);
});

/// The prayer that comes next, or null while there is no place.
final nextPrayerProvider = Provider<NextPrayer?>((ref) {
  final state = ref.watch(prayerProvider).value;
  final method = state?.method;
  final place = state?.place;
  if (place == null || method == null) return null;
  return nextPrayer(place, method, ref.watch(tickingNowProvider));
});

/// Owns the prayer choices. Times are worked out on the device for the next
/// week and scheduled again each time the app starts, so they follow the
/// calendar and a change of place. Starting never asks for a permission: it
/// only reads the location when it is already allowed.
class PrayerNotifier extends AsyncNotifier<PrayerState> {
  PrayerRepository get _repository => ref.read(prayerRepositoryProvider);
  LocationSource get _location => ref.read(locationSourceProvider);
  ReminderScheduler get _scheduler => ref.read(reminderSchedulerProvider);

  @override
  Future<PrayerState> build() async {
    // A language change rebuilds this, so the texts follow it.
    ref.watch(
      settingsProvider.select((value) => value.value?.localeCode ?? 'ar'),
    );
    final settings = await _repository.loadSettings();
    var place = await _repository.loadPlace();
    if (settings.needsSchedule) {
      final fresh = await _location.quiet();
      if (fresh != null) {
        place = fresh;
        unawaited(_repository.savePlace(fresh));
      }
      unawaited(_schedule(settings, place));
    }
    return PrayerState(settings: settings, place: place);
  }

  /// Reads the approximate location, asking for permission if needed. Call it
  /// from the person's tap.
  Future<PrayerResult> locate() async {
    final current = state.value;
    if (current == null) return PrayerResult.locationDenied;
    final place = await _location.request();
    if (place == null) return PrayerResult.locationDenied;
    unawaited(_repository.savePlace(place));
    await _apply(current.settings, place);
    return PrayerResult.ok;
  }

  /// Turns the alert at the time of [prayer] on or off.
  Future<PrayerResult> setAlert(DailyPrayer prayer, bool on) => setAlerts({
    for (final item in DailyPrayer.values)
      if (item == prayer
          ? on
          : (state.value?.settings.alerts.contains(item) ?? false))
        item,
  });

  /// Turns the alert on for every prayer, or off for all.
  Future<PrayerResult> setAllAlerts(bool on) =>
      setAlerts(on ? DailyPrayer.values.toSet() : const {});

  /// Sets which prayers alert at their time. Turning one on asks for what is
  /// missing, so call it from the person's tap.
  Future<PrayerResult> setAlerts(Set<DailyPrayer> alerts) => _change(
    needsPermission: alerts.isNotEmpty,
    change: (settings) => settings.copyWith(alerts: alerts),
  );

  /// Turns the after-prayer adhkar reminder on or off.
  Future<PrayerResult> setAdhkarReminder(bool on) => _change(
    needsPermission: on,
    change: (settings) => settings.copyWith(adhkarReminder: on),
  );

  /// Chooses how the times are worked out; null follows the place.
  Future<void> setMethod(PrayerMethod? method) => _change(
    needsPermission: false,
    change: (settings) => method == null
        ? settings.copyWith(automaticMethod: true)
        : settings.copyWith(method: method),
  );

  /// Changes how long after the prayer the adhkar reminder comes.
  Future<void> setAfterMinutes(int minutes) => _change(
    needsPermission: false,
    change: (settings) => settings.copyWith(afterMinutes: minutes),
  );

  /// Opens the system page where exact alarms may be allowed.
  Future<bool> allowExactAlarms() => _scheduler.requestExact();

  Future<PrayerResult> _change({
    required bool needsPermission,
    required PrayerSettings Function(PrayerSettings) change,
  }) async {
    final current = state.value;
    if (current == null) return PrayerResult.locationDenied;
    var place = current.place;
    if (needsPermission) {
      if (!await _scheduler.requestPermission()) {
        return PrayerResult.notificationsDenied;
      }
      if (place == null) {
        place = await _location.request();
        if (place == null) return PrayerResult.locationDenied;
        unawaited(_repository.savePlace(place));
      }
    }
    await _apply(change(current.settings), place);
    return PrayerResult.ok;
  }

  Future<void> _apply(PrayerSettings settings, PrayerPlace? place) async {
    final previous = state.value;
    state = AsyncData(PrayerState(settings: settings, place: place));
    try {
      await _repository.saveSettings(settings);
      await _schedule(settings, place);
    } on Object catch (error) {
      AppLogger.debug('Prayer settings failed: ${error.runtimeType}');
      if (previous != null) state = AsyncData(previous);
    }
  }

  Future<void> _schedule(PrayerSettings settings, PrayerPlace? place) async {
    try {
      for (final id in PrayerAlertPlan.allIds) {
        await _scheduler.cancel(id);
      }
      if (!settings.needsSchedule || place == null) return;
      final language = ref.read(settingsProvider).value?.localeCode ?? 'ar';
      final l10n = lookupAppLocalizations(Locale(language));
      final alerts = PrayerAlertPlan.compute(
        place: place,
        settings: settings,
        now: ref.read(clockProvider)(),
      );
      for (final alert in alerts) {
        final prayer = prayerName(l10n, alert.prayer);
        switch (alert.kind) {
          case PrayerAlertKind.atTime:
            await _scheduler.scheduleOnce(
              id: alert.id,
              at: alert.at,
              title: l10n.prayerAlertTitle(prayer),
              body: l10n.prayerAlertBody,
              channel: ReminderChannel.prayer,
              channelName: l10n.prayerChannelName,
              payload: ReminderPayload.prayerTimes,
              exact: true,
            );
          case PrayerAlertKind.afterPrayer:
            await _scheduler.scheduleOnce(
              id: alert.id,
              at: alert.at,
              title: l10n.adhkarPrayerReminderTitle,
              body: l10n.adhkarPrayerReminderBody(prayer),
              channel: ReminderChannel.adhkar,
              channelName: l10n.adhkarReminderChannel,
              payload: ReminderPayload.forCollection(afterPrayerCollectionId),
            );
        }
      }
    } on Object catch (error) {
      AppLogger.debug('Prayer schedule failed: ${error.runtimeType}');
    }
  }
}

/// The localized name of [prayer].
String prayerName(AppLocalizations l10n, DailyPrayer prayer) =>
    switch (prayer) {
      DailyPrayer.fajr => l10n.prayerFajr,
      DailyPrayer.dhuhr => l10n.prayerDhuhr,
      DailyPrayer.asr => l10n.prayerAsr,
      DailyPrayer.maghrib => l10n.prayerMaghrib,
      DailyPrayer.isha => l10n.prayerIsha,
    };
