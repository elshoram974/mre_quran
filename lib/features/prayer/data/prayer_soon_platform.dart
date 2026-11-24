import 'package:flutter/services.dart';

import '../../../core/diagnostics/app_logger.dart';

/// One reminder to show a while before the adhan, with a countdown to it.
class PrayerSoonAlarm {
  /// Creates a reminder. [id] is stable for a prayer and day.
  const PrayerSoonAlarm({
    required this.id,
    required this.at,
    required this.adhan,
    required this.title,
    required this.body,
    required this.channel,
    required this.channelName,
    required this.sound,
  });

  /// Identifies the reminder.
  final int id;

  /// When the reminder appears.
  final DateTime at;

  /// When the adhan is: where the countdown ends and the reminder goes.
  final DateTime adhan;

  /// The reminder's title, naming the prayer.
  final String title;

  /// The line under the title, saying when the adhan is.
  final String body;

  /// The notification channel it comes in: one for each prayer, because its
  /// voice says that prayer's name.
  final String channel;

  /// The channel's name, as the phone's settings show it.
  final String channelName;

  /// The sound of the channel: the name of a raw resource.
  final String sound;

  /// The form the platform reads.
  Map<String, Object> toMap() => {
    'id': id,
    'at': at.millisecondsSinceEpoch,
    'adhan': adhan.millisecondsSinceEpoch,
    'title': title,
    'body': body,
    'channel': channel,
    'channelName': channelName,
    'sound': sound,
  };
}

/// What is the same for every reminder.
class PrayerSoonConfig {
  /// Creates the config.
  const PrayerSoonConfig({
    required this.dismissLabel,
    required this.settingsLabel,
    required this.payload,
    required this.settingsPayload,
    required this.rtl,
    this.sound = true,
  });

  /// The text of the button that takes the reminder away.
  final String dismissLabel;

  /// The text of the button that opens the reminder's settings.
  final String settingsLabel;

  /// What tapping the reminder opens (see the reminder payloads).
  final String payload;

  /// What the settings button opens.
  final String settingsPayload;

  /// Whether the app's language reads right to left, which the reminder
  /// follows rather than the phone's.
  final bool rtl;

  /// Whether the reminder makes its sound.
  final bool sound;

  /// The form the platform reads.
  Map<String, Object> toMap() => {
    'dismissLabel': dismissLabel,
    'settingsLabel': settingsLabel,
    'payload': payload,
    'settingsPayload': settingsPayload,
    'rtl': rtl,
    'sound': sound,
  };
}

/// The reminder before a prayer that only Android can show: a notification
/// with a large countdown that the system itself redraws every second, so the
/// app does not run while it counts. Elsewhere a call does nothing.
abstract interface class PrayerSoonPlatform {
  /// Replaces every scheduled reminder with [alarms].
  Future<void> schedule(List<PrayerSoonAlarm> alarms, PrayerSoonConfig config);

  /// Removes every scheduled reminder.
  Future<void> cancelAll();
}

/// The Android implementation, over a method channel. Elsewhere the channel
/// has no handler and a call does nothing.
class ChannelPrayerSoonPlatform implements PrayerSoonPlatform {
  /// Creates the platform.
  const ChannelPrayerSoonPlatform();

  static const _channel = MethodChannel('net.mrecode.mre_quran/prayer_soon');

  /// Calls the platform. A failure never reaches the caller: the prayer's own
  /// alerts must go on without the reminder.
  Future<void> _call(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      return;
    } on Object catch (error) {
      AppLogger.debug('Prayer reminder $method failed: ${error.runtimeType}');
    }
  }

  @override
  Future<void> schedule(
    List<PrayerSoonAlarm> alarms,
    PrayerSoonConfig config,
  ) => _call('schedule', {
    'alarms': [for (final alarm in alarms) alarm.toMap()],
    'config': config.toMap(),
  });

  @override
  Future<void> cancelAll() => _call('cancelAll');
}
