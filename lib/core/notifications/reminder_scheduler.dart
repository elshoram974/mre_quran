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

  /// The reminder a while before a prayer time.
  prayerSoon('prayer_soon'),

  /// The reminder, the evening before, of a day it is sunnah to fast.
  fasting('fasting_reminders');

  const ReminderChannel(this.id);

  /// Channel id on Android.
  final String id;

  /// What the settings button of a notification of this channel opens: the
  /// prayer times, where the prayers' alerts are chosen, or the reminders.
  String get settings => switch (this) {
    prayer || prayerSoon => ReminderPayload.prayerSettings,
    adhkar || fasting => ReminderPayload.remindersSettings,
  };

  /// The iOS category of its notifications, which carries that button.
  String get iosCategory => switch (this) {
    prayer || prayerSoon => 'prayer',
    adhkar || fasting => 'reminders',
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
  /// on that day. Replaces any reminder with the same [id]. With
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
    String? settingsLabel,
  });

  /// Shows a notification once, at the local time [at]. Replaces any reminder
  /// with the same [id]. With [exact] it fires on the minute when exact alarms
  /// are allowed, and a little late otherwise. On iOS, [iosSound] names a
  /// sound in the app's `Library/Sounds` to play with it (30 seconds at
  /// most), and a prayer's alerts come through Focus ("Time Sensitive").
  ///
  /// With [countdownTo], on Android, the notification counts down to that
  /// time to the second, stays until then and goes by itself, and has a
  /// button reading [dismissLabel] that takes it away at once.
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
    DateTime? countdownTo,
    String? dismissLabel,
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
            android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
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
    String? settingsLabel,
  }) async {
    await _ensureZone();
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));
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
          ReminderChannel.adhkar.id,
          channelName,
          actions: settingsLabel == null
              ? null
              : [_settingsButton(ReminderChannel.adhkar, settingsLabel)],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: settingsLabel == null
              ? null
              : ReminderChannel.adhkar.iosCategory,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: weekday == null
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
    DateTime? countdownTo,
    String? dismissLabel,
    String? settingsLabel,
  }) async {
    await _ensureZone();
    final urgent = channel == ReminderChannel.prayer;
    final prayer = urgent || channel == ReminderChannel.prayerSoon;
    final countdown = countdownTo != null && countdownTo.isAfter(at);
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
          // A long body reads whole when the notification is opened.
          styleInformation: BigTextStyleInformation(body),
          // A countdown to the second in the notification's header, kept at
          // the top until the time comes, then gone.
          usesChronometer: countdown,
          chronometerCountDown: countdown,
          when: countdown ? countdownTo.millisecondsSinceEpoch : null,
          showWhen: countdown,
          ongoing: countdown,
          autoCancel: !countdown,
          onlyAlertOnce: countdown,
          timeoutAfter: countdown
              ? countdownTo.difference(at).inMilliseconds
              : null,
          actions: [
            if (countdown && dismissLabel != null)
              AndroidNotificationAction(
                _dismissAction,
                dismissLabel,
                cancelNotification: true,
              ),
            if (settingsLabel != null) _settingsButton(channel, settingsLabel),
          ],
        ),
        iOS: DarwinNotificationDetails(
          sound: iosSound,
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

  /// The id of the button that takes a countdown away.
  static const String _dismissAction = 'dismiss';

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
