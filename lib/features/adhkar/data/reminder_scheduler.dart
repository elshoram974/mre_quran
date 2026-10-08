import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/diagnostics/app_logger.dart';

/// Schedules the daily adhkar reminders on the device.
abstract interface class ReminderScheduler {
  /// Payload of the notification that launched the app, or null.
  String? get launchPayload;

  /// Payloads of notifications tapped while the app runs.
  Stream<String> get taps;

  /// Asks the person to allow notifications. Returns whether they are allowed.
  /// Call it only from an action the person took.
  Future<bool> requestPermission();

  /// Fires a notification every day at [minutes] after midnight, local time.
  /// Replaces any reminder with the same [id].
  Future<void> schedule({
    required int id,
    required int minutes,
    required String title,
    required String body,
    required String channelName,
    required String payload,
  });

  /// Removes the reminder [id], if any.
  Future<void> cancel(int id);
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

  /// Starts the plugin. Asks for no permission.
  static Future<LocalReminderScheduler> create() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final taps = StreamController<String>.broadcast();
    String? launchPayload;
    try {
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) taps.add(payload);
        },
      );
      final launch = await plugin.getNotificationAppLaunchDetails();
      if (launch != null && launch.didNotificationLaunchApp) {
        launchPayload = launch.notificationResponse?.payload;
      }
    } on Object catch (error) {
      AppLogger.debug('Notifications unavailable: ${error.runtimeType}');
    }
    return LocalReminderScheduler._(plugin, taps, launchPayload);
  }

  static const _channelId = 'adhkar_reminders';

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
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: first,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(_channelId, channelName),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

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
