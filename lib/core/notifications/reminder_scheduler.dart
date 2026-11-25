import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../diagnostics/app_logger.dart';
import 'reminder_payload.dart';

/// Where a notification is grouped in the system settings. Each channel has its
/// own sound and importance, which the person can change there.
enum ReminderChannel {
  /// Adhkar reminders.
  adhkar('adhkar_reminders'),

  /// The alert at a prayer time.
  prayer('prayer_time'),

  /// The reminder a while before a prayer time, in a channel for each prayer
  /// (and the Friday prayer), because its voice says that prayer's name:
  /// «اقتربت صلاة الظهر». A channel keeps the sound it was made with, so each
  /// has its own, and none has the old id `prayer_soon`.
  prayerSoonFajr('prayer_soon_fajr', 'prayer_near_fajr'),

  /// The reminder before Dhuhr.
  prayerSoonDhuhr('prayer_soon_dhuhr', 'prayer_near_dhuhr'),

  /// The reminder before the Friday prayer.
  prayerSoonJumuah('prayer_soon_jumuah', 'prayer_near_jumuah'),

  /// The reminder before Asr.
  prayerSoonAsr('prayer_soon_asr', 'prayer_near_asr'),

  /// The reminder before Maghrib.
  prayerSoonMaghrib('prayer_soon_maghrib', 'prayer_near_maghrib'),

  /// The reminder before Isha.
  prayerSoonIsha('prayer_soon_isha', 'prayer_near_isha'),

  /// The reminder, the evening before, of a day it is sunnah to fast.
  fasting('fasting_reminders'),

  /// The reminders the person made for themselves.
  custom('custom_reminders'),

  /// The notice at the iqama, a set time after the adhan, with its phrase.
  iqama('prayer_iqama', 'iqama_phrase');

  const ReminderChannel(this.id, [this.sound]);

  /// Channel id on Android.
  final String id;

  /// The name of the sound the channel plays, or null for the phone's own
  /// notification sound: the raw resource of that name on Android, the file
  /// `<name>.caf` in `Library/Sounds` on iOS.
  final String? sound;

  /// The id of the channel the reminder before a prayer used before it had a
  /// voice. It is removed, so the settings show a channel for each prayer
  /// only.
  static const String legacyPrayerSoonId = 'prayer_soon';

  /// Whether this is one of the reminders before a prayer.
  bool get isPrayerSoon => name.startsWith('prayerSoon');

  /// What the settings button of a notification of this channel opens: the
  /// prayer times, where the prayers' alerts are chosen, or the reminders.
  String get settings => switch (this) {
    adhkar || fasting || custom => ReminderPayload.remindersSettings,
    _ => ReminderPayload.prayerSettings,
  };

  /// The iOS category of its notifications, which carries that button.
  String get iosCategory => switch (this) {
    adhkar || fasting || custom => 'reminders',
    _ => 'prayer',
  };
}

/// Schedules local notifications on the device.
abstract interface class ReminderScheduler {
  /// Payload of the notification that launched the app, or null.
  String? get launchPayload;

  /// Payloads of notifications tapped while the app runs.
  Stream<String> get taps;

  /// Asks the person to allow notifications. Returns whether they are allowed.
  /// Call it only from an action the person took.
  Future<bool> requestPermission();

  /// Whether alarms may fire at the exact minute. Always true off Android.
  Future<bool> canScheduleExact();

  /// Opens the system page where the person may allow exact alarms. Returns
  /// whether they are allowed afterwards. Call it only from an action the
  /// person took.
  Future<bool> requestExact();

  /// Fires a notification every day at [minutes] after midnight, local time;
  /// with [weekday] (1 Monday to 7 Sunday, as `DateTime.weekday`), once a week
  /// on that day; with [dayOfMonth] (1 to 28, so every month has it), once a
  /// month on that day. It comes in [channel]. Replaces any reminder with the
  /// same [id]. With
  /// [settingsLabel], it has a button of that name that opens the reminders'
  /// settings.
  Future<void> schedule({
    required int id,
    required int minutes,
    required String title,
    required String body,
    required String channelName,
    required String payload,
    int? weekday,
    int? dayOfMonth,
    ReminderChannel channel = ReminderChannel.adhkar,
    String? settingsLabel,
  });

  /// Shows a notification once, at the local time [at]. Replaces any reminder
  /// with the same [id]. With [exact] it fires on the minute when exact alarms
  /// are allowed, and a little late otherwise. On iOS, [iosSound] names a
  /// sound in the app's `Library/Sounds` to play with it (30 seconds at
  /// most), and a prayer's alerts come through Focus ("Time Sensitive").
  ///
  /// With [silent], it makes no sound or vibration.
  ///
  /// With [settingsLabel], it has a button of that name that opens the
  /// settings of what it reminds of (see [ReminderChannel.settings]).
  Future<void> scheduleOnce({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required ReminderChannel channel,
    required String channelName,
    required String payload,
    bool exact = false,
    String? iosSound,
    bool silent = false,
    String? settingsLabel,
  });

  /// Removes the reminder [id], if any.
  Future<void> cancel(int id);

  /// The ids of the reminders still to come.
  Future<Set<int>> pendingIds();
}

/// [ReminderScheduler] over `flutter_local_notifications`.
///
/// Reminders use inexact alarms: a daily reminder does not need to the second,
/// and exact alarms need a permission Google Play restricts. The system may
/// shift one by a few minutes.
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler._(
    this._plugin,
    this._tapController,
    this.launchPayload,
  );

  /// Starts the plugin. Asks for no permission. [settingsLabel] gives the
  /// name of the notifications' settings button, which iOS takes once, at
  /// start-up, in the app's language then.
  static Future<LocalReminderScheduler> create({
    Future<String?> Function()? settingsLabel,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();
    String? pendingTap;
    late final StreamController<String> taps;
    taps = StreamController<String>.broadcast(
      onListen: () {
        final payload = pendingTap;
        pendingTap = null;
        if (payload != null) taps.add(payload);
      },
    );
    void deliver(String payload) {
      if (taps.hasListener) {
        taps.add(payload);
      } else {
        pendingTap = payload;
      }
    }

    var opened = false;
    String? launchPayload;
    try {
      Future<String?> initialize() async {
        final label = await settingsLabel?.call();
        await plugin.initialize(
          settings: InitializationSettings(
            android: const AndroidInitializationSettings(
              '@drawable/ic_stat_mre',
            ),
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
              notificationCategories: [
                if (label != null)
                  // One category for each place a settings button opens.
                  for (final MapEntry(key: category, value: settings) in {
                    for (final channel in ReminderChannel.values)
                      channel.iosCategory: channel.settings,
                  }.entries)
                    DarwinNotificationCategory(
                      category,
                      actions: [
                        DarwinNotificationAction.plain(
                          settings,
                          label,
                          options: {DarwinNotificationActionOption.foreground},
                        ),
                      ],
                    ),
              ],
            ),
          ),
          onDidReceiveNotificationResponse: (response) {
            final payload = _payloadOf(response);
            if (payload != null && payload.isNotEmpty) deliver(payload);
          },
        );
        // Not waited for: the first frame must not wait for a clean-up.
        unawaited(_removeOldChannel(plugin));
        final launch = await plugin.getNotificationAppLaunchDetails();
        if (launch != null && launch.didNotificationLaunchApp) {
          final response = launch.notificationResponse;
          final payload = response == null ? null : _payloadOf(response);
          if (opened && payload != null) deliver(payload);
          return payload;
        }
        return null;
      }

      launchPayload = await initialize().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          opened = true;
          return null;
        },
      );
    } on Object catch (error) {
      AppLogger.debug('Notifications unavailable: ${error.runtimeType}');
    }
    return LocalReminderScheduler._(plugin, taps, launchPayload);
  }

  /// The old channel of the reminder before a prayer has no voice and cannot
  /// be given one; each prayer's own has. It is removed so the phone's
  /// settings show the new ones only.
  static Future<void> _removeOldChannel(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    try {
      await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.deleteNotificationChannel(
            channelId: ReminderChannel.legacyPrayerSoonId,
          );
    } on Object catch (error) {
      AppLogger.debug('Old channel not removed: ${error.runtimeType}');
    }
  }

  /// What a tap opens: the settings, for the settings button; else what
  /// the notification points at.
  static String? _payloadOf(NotificationResponse response) {
    final action = response.actionId;
    return action != null && ReminderPayload.isSettings(action)
        ? action
        : response.payload;
  }

  /// The settings button of a notification of [channel], named [label].
  static AndroidNotificationAction _settingsButton(
    ReminderChannel channel,
    String label,
  ) => AndroidNotificationAction(
    channel.settings,
    label,
    showsUserInterface: true,
  );

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String> _tapController;
  bool _zoneReady = false;

  @override
  final String? launchPayload;

  @override
  Stream<String> get taps => _tapController.stream;

  @override
  Future<bool> requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    } on Object catch (error) {
      AppLogger.debug('Notification permission failed: ${error.runtimeType}');
      return false;
    }
  }

  @override
  Future<void> schedule({
    required int id,
    required int minutes,
    required String title,
    required String body,
    required String channelName,
    required String payload,
    int? weekday,
    int? dayOfMonth,
    ReminderChannel channel = ReminderChannel.adhkar,
    String? settingsLabel,
  }) async {
    await _ensureZone();
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      dayOfMonth ?? now.day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (!first.isAfter(now)) {
      first = dayOfMonth == null
          ? first.add(const Duration(days: 1))
          : tz.TZDateTime(
              tz.local,
              now.year,
              now.month + 1,
              dayOfMonth,
              minutes ~/ 60,
              minutes % 60,
            );
    }
    if (weekday != null) {
      // The next day that falls on [weekday], on or after the first time.
      while (first.weekday != weekday) {
        first = first.add(const Duration(days: 1));
      }
    }
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: first,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channelName,
          actions: settingsLabel == null
              ? null
              : [_settingsButton(channel, settingsLabel)],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: settingsLabel == null
              ? null
              : channel.iosCategory,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: dayOfMonth != null
          ? DateTimeComponents.dayOfMonthAndTime
          : weekday == null
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  @override
  Future<bool> canScheduleExact() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    try {
      return await android.canScheduleExactNotifications() ?? false;
    } on Object catch (error) {
      AppLogger.debug('Exact alarm check failed: ${error.runtimeType}');
      return false;
    }
  }

  @override
  Future<bool> requestExact() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    try {
      return await android.requestExactAlarmsPermission() ?? false;
    } on Object catch (error) {
      AppLogger.debug('Exact alarm request failed: ${error.runtimeType}');
      return false;
    }
  }

  @override
  Future<void> scheduleOnce({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required ReminderChannel channel,
    required String channelName,
    required String payload,
    bool exact = false,
    String? iosSound,
    bool silent = false,
    String? settingsLabel,
  }) async {
    await _ensureZone();
    final urgent =
        channel == ReminderChannel.prayer || channel == ReminderChannel.iqama;
    final prayer = urgent || channel.isPrayerSoon;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channelName,
          importance: urgent ? Importance.high : Importance.defaultImportance,
          priority: urgent ? Priority.high : Priority.defaultPriority,
          silent: silent,
          sound: channel.sound == null
              ? null
              : RawResourceAndroidNotificationSound(channel.sound),
          // A long body reads whole when the notification is opened.
          styleInformation: BigTextStyleInformation(body),
          actions: [
            if (settingsLabel != null) _settingsButton(channel, settingsLabel),
          ],
        ),
        iOS: DarwinNotificationDetails(
          sound: iosSound,
          presentSound: !silent,
          interruptionLevel: prayer ? InterruptionLevel.timeSensitive : null,
          categoryIdentifier: settingsLabel == null
              ? null
              : channel.iosCategory,
        ),
      ),
      androidScheduleMode: exact && await canScheduleExact()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<Set<int>> pendingIds() async => {
    for (final request in await _plugin.pendingNotificationRequests())
      request.id,
  };

  Future<void> _ensureZone() async {
    if (_zoneReady) return;
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object catch (error) {
      // Falls back to UTC, which the timezone package starts with.
      AppLogger.debug('Timezone lookup failed: ${error.runtimeType}');
    }
    _zoneReady = true;
  }
}
