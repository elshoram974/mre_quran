import 'dart:async';

import 'package:flutter/services.dart';

import '../../../core/diagnostics/app_logger.dart';

/// One adhan to start by itself at [at].
class AdhanAlarm {
  /// Creates an alarm. [id] is stable for a prayer and day.
  const AdhanAlarm({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
  });

  /// Identifies the alarm.
  final int id;

  /// When the adhan starts.
  final DateTime at;

  /// The notice's title.
  final String title;

  /// The notice's text.
  final String body;

  Map<String, Object> toMap() => {
    'id': id,
    'at': at.millisecondsSinceEpoch,
    'title': title,
    'body': body,
  };
}

/// What is the same for every alarm.
class AdhanAlertConfig {
  /// Creates the config.
  const AdhanAlertConfig({
    required this.voicePath,
    required this.stopWhenFlipped,
    required this.stopLabel,
    required this.channelName,
    required this.payload,
  });

  /// The saved recording to play, or null for the bundled one.
  final String? voicePath;

  /// Whether turning the phone face down stops the adhan.
  final bool stopWhenFlipped;

  /// The text of the notice's stop button.
  final String stopLabel;

  /// The name of the notification channel.
  final String channelName;

  /// What tapping the notice opens (see the reminder payloads).
  final String payload;

  Map<String, Object?> toMap() => {
    'voicePath': voicePath,
    'stopWhenFlipped': stopWhenFlipped,
    'stopLabel': stopLabel,
    'channelName': channelName,
    'payload': payload,
  };
}

/// The result of asking the person for an audio file.
class AudioPick {
  /// A file that was copied into the app.
  const AudioPick.file({required String this.path, required String this.name})
    : tooLarge = false;

  /// A file that was refused for its size.
  const AudioPick.tooLarge() : path = null, name = null, tooLarge = true;

  /// Where the copy is.
  final String? path;

  /// The file's name.
  final String? name;

  /// Whether the file was bigger than the app keeps.
  final bool tooLarge;
}

/// Where a preview comes from.
sealed class AdhanPreviewSource {
  const AdhanPreviewSource();

  Map<String, Object?> toMap();
}

/// The recording that ships with the app.
class BundledPreview extends AdhanPreviewSource {
  /// Creates the source.
  const BundledPreview();

  @override
  Map<String, Object?> toMap() => {'kind': 'bundled'};
}

/// A saved file.
class FilePreview extends AdhanPreviewSource {
  /// Creates the source.
  const FilePreview(this.path);

  /// The file's path.
  final String path;

  @override
  Map<String, Object?> toMap() => {'kind': 'file', 'path': path};
}

/// A recording streamed from the network, not yet downloaded.
class StreamPreview extends AdhanPreviewSource {
  /// Creates the source.
  const StreamPreview(this.url, this.userAgent);

  /// The address.
  final String url;

  /// Sent with the request.
  final String userAgent;

  @override
  Map<String, Object?> toMap() => {
    'kind': 'stream',
    'url': url,
    'userAgent': userAgent,
  };
}

/// The part of the adhan that only the platform can do: start by itself at
/// prayer time, stay on screen until stopped, stop when the phone is turned
/// over, and play a preview. Only Android has it; elsewhere [isSupported] is
/// false and the alert is a normal notification.
abstract interface class AdhanPlatform {
  /// Whether this platform can play the adhan by itself.
  Future<bool> isSupported();

  /// Replaces every scheduled adhan with [alarms].
  Future<void> schedule(List<AdhanAlarm> alarms, AdhanAlertConfig config);

  /// Removes every scheduled adhan.
  Future<void> cancelAll();

  /// Starts the alert now, as at prayer time, so the person can see and hear
  /// it.
  Future<void> test(AdhanAlarm alarm, AdhanAlertConfig config);

  /// Plays [source] for the person to hear. Replaces a preview in progress.
  Future<void> preview(AdhanPreviewSource source);

  /// Stops the preview.
  Future<void> stopPreview();

  /// Fires when a preview ends on its own, or fails.
  Stream<void> get previewEnded;

  /// Lets the person pick an audio file from their phone. It is copied into
  /// the app, so it keeps working if the original moves. Null when they back
  /// out.
  Future<AudioPick?> pickAudioFile();

  /// What the adhan's notice pointed at when it opened the app, if it did.
  /// Call once, at start-up; after that taps arrive on [taps].
  Future<String?> takeLaunchPayload();

  /// Payloads of taps on the adhan's notice while the app is running.
  Stream<String> get taps;
}

/// The Android implementation, over a method channel.
class ChannelAdhanPlatform implements AdhanPlatform {
  /// Creates the platform.
  ChannelAdhanPlatform();

  static const _channel = MethodChannel('net.mrecode.mre_quran/adhan');
  final StreamController<void> _ended = StreamController<void>.broadcast();
  final StreamController<String> _taps = StreamController<String>.broadcast();
  bool _listening = false;

  /// Starts hearing the platform's events, once, when first needed (so
  /// creating the platform never touches the engine).
  void _listen() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'previewEnded':
          _ended.add(null);
        case 'tapped':
          _taps.add(call.arguments! as String);
      }
    });
  }

  /// Calls the platform. A failure never reaches the caller: the adhan is an
  /// extra, and the alerts must go on without it.
  Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      _listen();
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on Object catch (error) {
      AppLogger.debug('Adhan $method failed: ${error.runtimeType}');
      return null;
    }
  }

  @override
  Future<bool> isSupported() async => await _call<bool>('isSupported') ?? false;

  @override
  Future<void> schedule(List<AdhanAlarm> alarms, AdhanAlertConfig config) =>
      _call<void>('schedule', {
        'alarms': [for (final alarm in alarms) alarm.toMap()],
        'config': config.toMap(),
      });

  @override
  Future<void> cancelAll() => _call<void>('cancelAll');

  @override
  Future<void> test(AdhanAlarm alarm, AdhanAlertConfig config) =>
      _call<void>('test', {'alarm': alarm.toMap(), 'config': config.toMap()});

  @override
  Future<void> preview(AdhanPreviewSource source) =>
      _call<void>('preview', source.toMap());

  @override
  Future<void> stopPreview() => _call<void>('stopPreview');

  @override
  Future<AudioPick?> pickAudioFile() async {
    final result = await _call<Map<Object?, Object?>>('pickAudioFile');
    if (result == null) return null;
    if (result['error'] == 'too_large') return const AudioPick.tooLarge();
    final path = result['path'];
    final name = result['name'];
    if (path is! String || name is! String) return null;
    return AudioPick.file(path: path, name: name);
  }

  @override
  Future<String?> takeLaunchPayload() => _call<String>('takeLaunchPayload');

  @override
  Stream<String> get taps {
    _listen();
    return _taps.stream;
  }

  @override
  Stream<void> get previewEnded {
    _listen();
    return _ended.stream;
  }
}
