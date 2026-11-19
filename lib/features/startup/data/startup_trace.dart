import 'package:flutter/services.dart';

/// The native record of each launch's steps (StartupTrace in MainActivity
/// and AppDelegate): Dart adds its own steps, and takes the trace of an
/// earlier launch that never showed its first frame.
abstract interface class StartupTrace {
  /// Notes [step] of the launch under way.
  void mark(String step);

  /// The trace of an earlier launch that stayed on the launch screen, once;
  /// null when none did.
  Future<String?> takeStalled();
}

/// [StartupTrace] over the app's startup channel. Where nothing answers
/// (tests, desktop), it notes nothing.
class MethodChannelStartupTrace implements StartupTrace {
  /// Creates the trace.
  const MethodChannelStartupTrace();

  static const _channel = MethodChannel('net.mrecode.mre_quran/startup');

  @override
  void mark(String step) {
    _channel.invokeMethod<void>('mark', step).catchError((Object _) {});
  }

  @override
  Future<String?> takeStalled() async {
    try {
      return await _channel.invokeMethod<String>('takeStalled');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
