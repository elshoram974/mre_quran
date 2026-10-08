import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/settings_provider.dart';
import '../data/location_source.dart';
import '../data/prayer_reminders_repository.dart';
import '../domain/prayer_reminders.dart';
import '../domain/reminder_payload.dart';
import 'reminders_provider.dart';

/// Provides the after-prayer store.
final prayerRemindersRepositoryProvider = Provider<PrayerRemindersRepository>(
  (ref) => LocalPrayerRemindersRepository(SharedPreferencesAsync()),
);

/// Provides the location source. Tests override it.
final locationSourceProvider = Provider<LocationSource>(
  (ref) => const GeolocatorLocationSource(),
);

/// The id of the list a prayer reminder opens.
const String afterPrayerCollectionId = 'after_prayer';

/// What the after-prayer reminders are set to, and where.
@immutable
class PrayerRemindersState {
  /// Creates the state.
  const PrayerRemindersState({required this.settings, this.place});

  /// The person's choices.
  final PrayerReminderSettings settings;

  /// The last place worked out, if any.
  final PrayerPlace? place;
}

/// Outcome of turning the after-prayer reminders on or off.
enum PrayerToggleResult {
  /// They are on.
  enabled,

  /// They are off.
  disabled,

  /// The person did not allow notifications.
  notificationsDenied,

  /// The person did not allow location, so there are no prayer times.
  locationDenied,
}

/// The after-prayer reminders.
final prayerRemindersProvider =
    AsyncNotifierProvider<PrayerRemindersNotifier, PrayerRemindersState>(
      PrayerRemindersNotifier.new,
    );

/// Owns the after-prayer reminders. Times are worked out on the device for the
/// next week and scheduled again each time the app starts, so they follow the
/// calendar and a change of place. Starting never asks for a permission: it
/// only reads the location when it is already allowed.
class PrayerRemindersNotifier extends AsyncNotifier<PrayerRemindersState> {
  PrayerRemindersRepository get _repository =>
      ref.read(prayerRemindersRepositoryProvider);
  LocationSource get _location => ref.read(locationSourceProvider);

  @override
  Future<PrayerRemindersState> build() async {
    // A language change rebuilds this, so the texts follow it.
    ref.watch(
      settingsProvider.select((value) => value.value?.localeCode ?? 'ar'),
    );
    final settings = await _repository.loadSettings();
    var place = await _repository.loadPlace();
    if (settings.enabled) {
      final fresh = await _location.quiet();
      if (fresh != null) {
        place = fresh;
        unawaited(_repository.savePlace(fresh));
      }
      unawaited(_schedule(settings, place));
    }
    return PrayerRemindersState(settings: settings, place: place);
  }

  /// Turns the reminders on or off. Turning them on asks for notifications and
  /// then for the approximate location, so call this from the person's tap.
  Future<PrayerToggleResult> setEnabled(bool enabled) async {
    final current = state.value;
    if (current == null) return PrayerToggleResult.disabled;
    if (!enabled) {
      await _apply(current.settings.copyWith(enabled: false), current.place);
      return PrayerToggleResult.disabled;
    }
    if (!await ref.read(reminderSchedulerProvider).requestPermission()) {
      return PrayerToggleResult.notificationsDenied;
    }
    final place = await _location.request();
    if (place == null) return PrayerToggleResult.locationDenied;
    unawaited(_repository.savePlace(place));
    await _apply(current.settings.copyWith(enabled: true), place);
    return PrayerToggleResult.enabled;
  }

  /// Changes how prayer times are worked out.
  Future<void> setMethod(PrayerMethod method) =>
      _change((settings) => settings.copyWith(method: method));

  /// Changes how long after the prayer the reminder comes.
  Future<void> setAfterMinutes(int minutes) =>
      _change((settings) => settings.copyWith(afterMinutes: minutes));

  Future<void> _change(
    PrayerReminderSettings Function(PrayerReminderSettings) change,
  ) async {
    final current = state.value;
    if (current == null) return;
    await _apply(change(current.settings), current.place);
  }

  Future<void> _apply(
    PrayerReminderSettings settings,
    PrayerPlace? place,
  ) async {
    final previous = state.value;
    state = AsyncData(PrayerRemindersState(settings: settings, place: place));
    try {
      await _repository.saveSettings(settings);
      await _schedule(settings, place);
    } on Object catch (error) {
      AppLogger.debug('Prayer reminders failed: ${error.runtimeType}');
      if (previous != null) state = AsyncData(previous);
    }
  }

  Future<void> _schedule(
    PrayerReminderSettings settings,
    PrayerPlace? place,
  ) async {
    final scheduler = ref.read(reminderSchedulerProvider);
    try {
      for (final id in PrayerReminderPlan.allIds) {
        await scheduler.cancel(id);
      }
      if (!settings.enabled || place == null) return;
      final language = ref.read(settingsProvider).value?.localeCode ?? 'ar';
      final l10n = lookupAppLocalizations(Locale(language));
      final reminders = PrayerReminderPlan.compute(
        place: place,
        settings: settings,
        now: DateTime.now(),
      );
      for (final reminder in reminders) {
        await scheduler.scheduleOnce(
          id: reminder.id,
          at: reminder.at,
          title: l10n.adhkarPrayerReminderTitle,
          body: l10n.adhkarPrayerReminderBody(_name(l10n, reminder.prayer)),
          channelName: l10n.adhkarReminderChannel,
          payload: ReminderPayload.forCollection(afterPrayerCollectionId),
        );
      }
    } on Object catch (error) {
      AppLogger.debug('Prayer schedule failed: ${error.runtimeType}');
    }
  }

  static String _name(AppLocalizations l10n, DailyPrayer prayer) =>
      switch (prayer) {
        DailyPrayer.fajr => l10n.prayerFajr,
        DailyPrayer.dhuhr => l10n.prayerDhuhr,
        DailyPrayer.asr => l10n.prayerAsr,
        DailyPrayer.maghrib => l10n.prayerMaghrib,
        DailyPrayer.isha => l10n.prayerIsha,
      };
}
