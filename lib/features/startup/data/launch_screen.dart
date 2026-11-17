import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The platform's own launch screen, which Android keeps up (its star
/// turning) until the app says its first screen is ready.
abstract interface class LaunchScreen {
  /// Lets the launch screen go.
  Future<void> release();
}

/// Talks to `MainActivity`, which holds the launch screen.
class PlatformLaunchScreen implements LaunchScreen {
  /// Creates the bridge.
  const PlatformLaunchScreen();

  static const MethodChannel _channel = MethodChannel(
    'net.mrecode.mre_quran/startup',
  );

  @override
  Future<void> release() async {
    try {
      await _channel.invokeMethod<void>('ready');
    } on MissingPluginException {
      // A platform without a held launch screen (iOS) has nothing to let go.
    }
  }
}

/// Provides the launch screen. Tests override it.
final launchScreenProvider = Provider<LaunchScreen>(
  (ref) => const PlatformLaunchScreen(),
);
