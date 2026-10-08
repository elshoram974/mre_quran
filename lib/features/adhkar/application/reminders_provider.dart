import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/settings_provider.dart';
import '../data/reminder_scheduler.dart';
import '../data/reminders_repository.dart';
import '../domain/adhkar_collection.dart';
import '../domain/reminder_payload.dart';
import '../domain/reminder_setting.dart';
import 'adhkar_providers.dart';

/// Provides the reminder store.
final remindersRepositoryProvider = Provider<RemindersRepository>(
  (ref) => LocalRemindersRepository(SharedPreferencesAsync()),
);

/// Provides the device scheduler. `main` overrides it with the started plugin;
/// the default does nothing, which keeps tests off the platform.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => const _NoopReminderScheduler(),
);

/// Notification payloads tapped while the app runs.
final reminderTapsProvider = StreamProvider<String>(
  (ref) => ref.watch(reminderSchedulerProvider).taps,
);

/// Outcome of turning a reminder on.
enum ReminderToggleResult {
  /// The reminder is on.
  enabled,

  /// The reminder is off.
  disabled,

  /// The person did not allow notifications, so the reminder stayed off.
  permissionDenied,
}

/// The reminder of every collection, by collection id. Holds the default for a
/// collection the person has not touched.
final remindersProvider =
    AsyncNotifierProvider<RemindersNotifier, Map<String, ReminderSetting>>(
      RemindersNotifier.new,
    );

/// Owns the reminders and keeps the device schedule in step with them.
class RemindersNotifier extends AsyncNotifier<Map<String, ReminderSetting>> {
  RemindersRepository get _repository => ref.read(remindersRepositoryProvider);
  ReminderScheduler get _scheduler => ref.read(reminderSchedulerProvider);

  @override
  Future<Map<String, ReminderSetting>> build() async {
    // A language change rebuilds this, so the scheduled texts follow it.
    final language = ref.watch(
      settingsProvider.select((value) => value.value?.localeCode ?? 'ar'),
    );
    final catalog = await ref.watch(adhkarCatalogProvider.future);
    final saved = await _repository.load();
    final settings = {
      for (final collection in catalog.collections)
        if (collection.reminderMinutes != null)
          collection.id:
              saved[collection.id] ??
              ReminderSetting(
                enabled: false,
                minutes: collection.reminderMinutes!,
              ),
    };
    for (final collection in catalog.collections) {
      final setting = settings[collection.id];
      if (setting != null && setting.enabled) {
        unawaited(_sync(collection, setting, language));
      }
    }
    return settings;
  }

  /// Turns the reminder of [collection] on or off. Turning it on asks for the
  /// notification permission first, so call this from the person's tap.
  Future<ReminderToggleResult> setEnabled(
    AdhkarCollection collection,
    bool enabled,
  ) async {
    if (enabled && !await _scheduler.requestPermission()) {
      return ReminderToggleResult.permissionDenied;
    }
    await _update(collection, (setting) => setting.copyWith(enabled: enabled));
    return enabled
        ? ReminderToggleResult.enabled
        : ReminderToggleResult.disabled;
  }

  /// Moves the reminder of [collection] to [minutes] after midnight.
  Future<void> setTime(AdhkarCollection collection, int minutes) =>
      _update(collection, (setting) => setting.copyWith(minutes: minutes));

  Future<void> _update(
    AdhkarCollection collection,
    ReminderSetting Function(ReminderSetting) change,
  ) async {
    final previous = state.value;
    final current = previous?[collection.id];
    if (previous == null || current == null) return;
    final next = {...previous, collection.id: change(current)};
    state = AsyncData(next);
    try {
      await _repository.save(next);
      await _sync(collection, next[collection.id]!, _language);
    } on Object catch (error) {
      AppLogger.debug('Reminder update failed: ${error.runtimeType}');
      state = AsyncData(previous);
    }
  }

  String get _language => ref.read(settingsProvider).value?.localeCode ?? 'ar';

  Future<void> _sync(
    AdhkarCollection collection,
    ReminderSetting setting,
    String language,
  ) async {
    final id = ReminderPayload.notificationId(collection.id);
    try {
      if (!setting.enabled) {
        await _scheduler.cancel(id);
        return;
      }
      final l10n = lookupAppLocalizations(Locale(language));
      await _scheduler.schedule(
        id: id,
        minutes: setting.minutes,
        title: collection.title(language),
        body: l10n.adhkarReminderBody,
        channelName: l10n.adhkarReminderChannel,
        payload: ReminderPayload.forCollection(collection.id),
      );
    } on Object catch (error) {
      AppLogger.debug('Reminder schedule failed: ${error.runtimeType}');
    }
  }
}

class _NoopReminderScheduler implements ReminderScheduler {
  const _NoopReminderScheduler();

  @override
  String? get launchPayload => null;

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule({
    required int id,
    required int minutes,
    required String title,
    required String body,
    required String channelName,
    required String payload,
  }) async {}

  @override
  Future<void> scheduleOnce({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String channelName,
    required String payload,
  }) async {}

  @override
  Future<void> cancel(int id) async {}
}
