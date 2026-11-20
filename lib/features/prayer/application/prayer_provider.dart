import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../../../core/notifications/reminder_payload.dart';
import '../../../core/notifications/reminder_scheduler.dart';
import '../../../core/notifications/reminder_scheduler_provider.dart';
import '../../../core/time/ticking_clock.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../adhan/application/adhan_providers.dart';
import '../../adhan/data/adhan_platform.dart';
import '../../adhan/data/ios_adhan_sounds.dart';
import '../../settings/application/digits_provider.dart';
import '../../settings/application/settings_provider.dart';
import '../data/location_source.dart';
import '../data/prayer_repository.dart';
import '../domain/prayer_alerts.dart';
import 'place_search_provider.dart';
import '../domain/prayer_times.dart';

/// Provides the prayer store.
final prayerRepositoryProvider = Provider<PrayerRepository>(
  (ref) => LocalPrayerRepository(SharedPreferencesAsync()),
);

/// Provides the location source. Tests override it.
final locationSourceProvider = Provider<LocationSource>(
  (ref) => const GeolocatorLocationSource(),
);

/// Why the location could not be read the last time it was asked for, so the
/// screens can say what to do. Cleared when a read works.
final locationProblemProvider =
    NotifierProvider<LocationProblemNotifier, LocationProblem>(
      LocationProblemNotifier.new,
    );

/// Owns [locationProblemProvider].
class LocationProblemNotifier extends Notifier<LocationProblem> {
  @override
  LocationProblem build() => LocationProblem.none;

  /// Notes [problem].
  void set(LocationProblem problem) => state = problem;
}

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
  Future<void> _scheduleQueue = Future.value();

  @override
  Future<PrayerState> build() async {
    // A language change rebuilds this, so the texts follow it.
    ref.watch(
      settingsProvider.select((value) => value.value?.localeCode ?? 'ar'),
    );
    // The adhan's voice or style changing moves the alerts without rebuilding
    // this (which would blink the page).
    ref.listen(adhanSettingsProvider, (previous, next) {
      final current = state.value;
      if (previous?.value == next.value || current == null) return;
      unawaited(_schedule(current.settings, current.place));
    });
    final settings = await _repository.loadSettings();
    var place = await _repository.loadPlace();
    if (settings.needsSchedule) {
      final fresh = settings.automaticLocation ? await _location.quiet() : null;
      if (fresh != null) {
        // The same spot keeps its name; a new one is named afresh.
        place = place == fresh ? place : fresh;
        unawaited(_repository.savePlace(place!));
      }
      unawaited(_schedule(settings, place));
    }
    if (place != null) _nameLater(place);
    return PrayerState(settings: settings, place: place);
  }

  /// Asks for the location, and notes why when it cannot be had.
  Future<PrayerPlace?> _requestPlace() async {
    final place = await _location.request();
    ref
        .read(locationProblemProvider.notifier)
        .set(place == null ? await _location.problem() : LocationProblem.none);
    return place;
  }

  /// Finds [place]'s name in the background and keeps it with the place, so
  /// the screens can say "Cairo, Egypt" rather than numbers. Nothing waits
  /// for it; without a name the numbers still show.
  void _nameLater(PrayerPlace place) {
    if (place.name != null) return;
    unawaited(_name(place));
  }

  Future<void> _name(PrayerPlace place) async {
    final code = ref.read(settingsProvider).value?.localeCode ?? 'ar';
    final name = await ref
        .read(placeNameSourceProvider)
        .nameOf(place, Locale(code));
    final current = state.value;
    // Still the place asked about, and not named meanwhile.
    if (name == null || current == null || current.place != place) return;
    if (current.place?.name != null) return;
    final named = place.withName(name);
    state = AsyncData(PrayerState(settings: current.settings, place: named));
    unawaited(_repository.savePlace(named));
  }

  /// Reads the approximate location, asking for permission if needed. Call it
  /// from the person's tap.
  Future<PrayerResult> locate() async {
    final current = state.value;
    if (current == null) return PrayerResult.locationDenied;
    final place = await _requestPlace();
    if (place == null) return PrayerResult.locationDenied;
    unawaited(_repository.savePlace(place));
    await _apply(current.settings.copyWith(automaticLocation: true), place);
    _nameLater(place);
    return PrayerResult.ok;
  }

  /// Saves a selected map location. A confirmed device fix can refresh later;
  /// a manually adjusted place remains fixed.
  Future<void> setPlace(
    PrayerPlace place, {
    bool automaticLocation = false,
  }) async {
    final current = state.value;
    if (current == null) return;
    unawaited(_repository.savePlace(place));
    await _apply(
      current.settings.copyWith(automaticLocation: automaticLocation),
      place,
    );
    _nameLater(place);
  }

  /// Reads the device location for a map preview without saving it.
  Future<PrayerPlace?> previewDeviceLocation() => _requestPlace();

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

  /// Turns the reminder before each alerting prayer on or off.
  Future<void> setBeforeReminder(bool on) => _change(
    needsPermission: false,
    change: (settings) => settings.copyWith(beforeReminder: on),
  );

  /// Changes how long before the prayer its reminder comes.
  Future<void> setBeforeMinutes(int minutes) => _change(
    needsPermission: false,
    change: (settings) => settings.copyWith(beforeMinutes: minutes),
  );

  /// Changes how long after the prayer the adhkar reminder comes.
  Future<void> setAfterMinutes(int minutes) => _change(
    needsPermission: false,
    change: (settings) => settings.copyWith(afterMinutes: minutes),
  );

  /// Opens the system page and replaces approximate alarms after approval.
  Future<bool> allowExactAlarms() async {
    final allowed = await _scheduler.requestExact();
    if (allowed) await reschedule();
    return allowed;
  }

  /// Replaces pending alarms using the current permissions and settings.
  Future<void> reschedule() async {
    final current = await future;
    if (current.settings.needsSchedule) {
      await _schedule(current.settings, current.place);
    }
  }

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
        place = await _requestPlace();
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

  /// Hands [atTime] to the adhan player. Returns whether it took them: it
  /// needs the style switched on, a platform that can play by itself, and
  /// exact alarms (a late adhan is worse than a normal notification).
  Future<bool> _scheduleAdhan(
    AppLocalizations l10n,
    Iterable<PrayerAlert> atTime,
  ) async {
    final platform = ref.read(adhanPlatformProvider);
    try {
      final settings = await ref.read(adhanSettingsProvider.future);
      final usable =
          atTime.isNotEmpty &&
          settings.playAdhan &&
          await platform.isSupported() &&
          await _scheduler.canScheduleExact();
      if (!usable) {
        await platform.cancelAll();
        return false;
      }
      final config = await buildAdhanConfig(
        settings: settings,
        voices: await ref.read(adhanCatalogProvider.future),
        store: ref.read(voiceStoreProvider),
        l10n: l10n,
      );
      await platform.schedule([
        for (final alert in atTime)
          AdhanAlarm(
            id: alert.id,
            at: alert.at,
            title: l10n.prayerAlertTitle(_alertName(l10n, alert)),
            body: l10n.prayerAlertBody,
            fajr: alert.prayer == DailyPrayer.fajr,
            announce: _isJumuah(alert) ? 'jumuah' : alert.prayer.name,
          ),
      ], config);
      return true;
    } on Object catch (error) {
      // Whatever went wrong, the alerts stay: as normal notifications.
      AppLogger.debug('Adhan schedule failed: ${error.runtimeType}');
      return false;
    }
  }

  /// How many days ahead the alerts are planned. Android arms only the next
  /// adhan at a time and takes the rest from its own list, so a month costs
  /// nothing and the adhan goes on even when the app is not opened. iOS
  /// keeps at most 64 pending notifications, so a week.
  static int get planDays =>
      defaultTargetPlatform == TargetPlatform.android ? 30 : 7;

  /// The most prayer notifications handed to the system at once: on iOS
  /// within its 64, leaving room for the adhkar reminders; on Android well
  /// below the alarms a phone allows an app.
  static int get notificationLimit =>
      defaultTargetPlatform == TargetPlatform.android ? 150 : 48;

  Future<void> _schedule(PrayerSettings settings, PrayerPlace? place) {
    // Replacing a plan cancels and recreates alarms. Serialize replacements so
    // an older startup or voice-change request cannot overwrite a newer one.
    final next = _scheduleQueue.then((_) => _replaceSchedule(settings, place));
    _scheduleQueue = next;
    return next;
  }

  Future<void> _replaceSchedule(
    PrayerSettings settings,
    PrayerPlace? place,
  ) async {
    try {
      for (final id in await _scheduler.pendingIds()) {
        if (PrayerAlertPlan.owns(id)) await _scheduler.cancel(id);
      }
      if (!settings.needsSchedule || place == null) {
        await ref.read(adhanPlatformProvider).cancelAll();
        return;
      }
      final language = ref.read(settingsProvider).value?.localeCode ?? 'ar';
      final l10n = lookupAppLocalizations(Locale(language));
      final alerts = PrayerAlertPlan.compute(
        place: place,
        settings: settings,
        now: ref.read(clockProvider)(),
        days: planDays,
      );
      // The adhan that plays by itself takes the at-time alerts when the phone
      // can; otherwise they stay normal notifications.
      final byAdhan = await _scheduleAdhan(
        l10n,
        alerts.where((alert) => alert.kind == PrayerAlertKind.atTime),
      );
      final notices = [
        for (final alert in alerts)
          if (!byAdhan || alert.kind != PrayerAlertKind.atTime) alert,
      ].take(notificationLimit);
      // iOS plays no long sound by itself: its alert at prayer time rings
      // with the adhan's opening (the Fajr adhan's at Fajr) when the adhan
      // is on.
      final iosAdhan =
          defaultTargetPlatform == TargetPlatform.iOS &&
          (ref.read(adhanSettingsProvider).value?.playAdhan ?? true) &&
          await ref.read(iosAdhanSoundsProvider).install();
      final minutes = settings.beforeMinutes;
      final number = ref.read(digitsFormatterProvider);
      for (final alert in notices) {
        final prayer = _alertName(l10n, alert);
        switch (alert.kind) {
          case PrayerAlertKind.beforePrayer:
            await _scheduler.scheduleOnce(
              id: alert.id,
              at: alert.at,
              title: l10n.prayerSoonTitle(prayer),
              body: l10n.prayerSoonBody(minutes, number(minutes)),
              channel: ReminderChannel.prayerSoon,
              channelName: l10n.prayerSoonChannelName,
              payload: ReminderPayload.prayerTimes,
              exact: true,
            );
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
              iosSound: iosAdhan
                  ? LibraryIosAdhanSounds.of(
                      fajr: alert.prayer == DailyPrayer.fajr,
                    )
                  : null,
            );
          case PrayerAlertKind.afterPrayer:
            await _scheduler.scheduleOnce(
              id: alert.id,
              at: alert.at,
              title: l10n.adhkarPrayerReminderTitle,
              body: l10n.adhkarPrayerReminderBody(
                prayerName(l10n, alert.prayer),
              ),
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

  /// Whether [alert] is Dhuhr on a Friday: the Friday prayer.
  static bool _isJumuah(PrayerAlert alert) =>
      alert.prayer == DailyPrayer.dhuhr && alert.at.weekday == DateTime.friday;

  /// The prayer's name as an alert says it: the Friday prayer by its own.
  static String _alertName(AppLocalizations l10n, PrayerAlert alert) =>
      _isJumuah(alert) ? l10n.prayerJumuah : prayerName(l10n, alert.prayer);
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
