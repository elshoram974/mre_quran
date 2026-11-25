import 'package:flutter/services.dart';

import '../../../core/diagnostics/app_logger.dart';

/// One prayer notice for Android to show at its time: the reminder a while
/// before the adhan with a countdown to it, or (with [countdown] false) a
/// plain notice such as the one at the iqama.
class PrayerSoonAlarm {
  /// Creates a reminder with a countdown. [id] is stable for a prayer and day.
  const PrayerSoonAlarm({
    required this.id,
    required this.at,
    required this.adhan,
    required this.title,
    required this.body,
    required this.channel,
    required this.channelName,
    required this.sound,
  }) : countdown = true,
       urgent = false,
       silent = null,
       payload = null,
       settingsPayload = null;

  /// Creates a plain notice, not shown once [until] has passed.
  const PrayerSoonAlarm.plain({
    required this.id,
    required this.at,
    required DateTime until,
    required this.title,
    required this.body,
    required this.channel,
    required this.channelName,
    required this.sound,
    required this.urgent,
    required bool this.silent,
    required String this.payload,
    required String this.settingsPayload,
  }) : adhan = until,
       countdown = false;

  /// Identifies the reminder.
  final int id;

  /// When the reminder appears.
  final DateTime at;

  /// When the adhan is: where the countdown ends and the reminder goes. For
  /// a plain notice, the time after which it is too late to show.
  final DateTime adhan;

  /// Whether it counts down to [adhan]; otherwise it is a plain notice.
  final bool countdown;

  /// Whether its channel is of high importance (the prayer time, the iqama).
  final bool urgent;

  /// Whether it comes without sound; null leaves it to the config.
  final bool? silent;

  /// What tapping it opens; null leaves it to the config.
  final String? payload;

  /// What its settings button opens; null leaves it to the config.
  final String? settingsPayload;

  /// The reminder's title, naming the prayer.
  final String title;

  /// The line under the title, saying when the adhan is.
  final String body;

  /// The notification channel it comes in: one for each prayer, because its
  /// voice says that prayer's name.
  final String channel;

  /// The channel's name, as the phone's settings show it.
  final String channelName;

  /// The sound of the channel: the name of a raw resource, or null for the
  /// phone's notification sound.
  final String? sound;

  /// The form the platform reads.
  Map<String, Object> toMap() => {
    'id': id,
    'at': at.millisecondsSinceEpoch,
    if (countdown)
      'adhan': adhan.millisecondsSinceEpoch
    else ...{
      'until': adhan.millisecondsSinceEpoch,
      'countdown': false,
    },
    'title': title,
    'body': body,
    'channel': channel,
    'channelName': channelName,
    'sound': ?sound,
    if (urgent) 'urgent': true,
    'silent': ?silent,
    'payload': ?payload,
    'settingsPayload': ?settingsPayload,
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

/// The prayer notices Android keeps itself: the reminder before a prayer, a
/// notification with a large countdown that the system itself redraws every
/// second, so the app does not run while it counts; and the other prayer
/// notices, handed over in one call (the notifications plugin takes them one
/// by one, rewriting its whole list each time). Elsewhere a call does nothing.
abstract interface class PrayerSoonPlatform {
  /// Replaces every scheduled notice with [alarms]. Returns whether the
  /// platform took them.
  Future<bool> schedule(List<PrayerSoonAlarm> alarms, PrayerSoonConfig config);

  /// Removes every scheduled reminder.
  Future<void> cancelAll();
}

/// The Android implementation, over a method channel. Elsewhere the channel
/// has no handler and a call does nothing.
class ChannelPrayerSoonPlatform implements PrayerSoonPlatform {
  /// Creates the platform.
  const ChannelPrayerSoonPlatform();

  static const _channel = MethodChannel('net.mrecode.mre_quran/prayer_soon');

  /// Calls the platform, saying whether it worked. A failure never reaches
  /// the caller: the prayer's own alerts must go on without the reminder.
  Future<bool> _call(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
      return true;
    } on MissingPluginException {
      return false;
    } on Object catch (error) {
      AppLogger.debug('Prayer reminder $method failed: ${error.runtimeType}');
      return false;
    }
  }

  @override
  Future<bool> schedule(
    List<PrayerSoonAlarm> alarms,
    PrayerSoonConfig config,
  ) => _call('schedule', {
    'alarms': [for (final alarm in alarms) alarm.toMap()],
    'config': config.toMap(),
  });

  @override
  Future<void> cancelAll() async {
    await _call('cancelAll');
  }
}
