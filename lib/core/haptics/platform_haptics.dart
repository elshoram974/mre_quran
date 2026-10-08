import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../diagnostics/app_logger.dart';
import 'haptics.dart';

/// Feedback on the real device.
///
/// Android goes straight to the vibrator with a short, strong pulse. The
/// system's own touch feedback is often switched off in the phone's settings,
/// which silences `HapticFeedback` completely, so it is only the fallback
/// there. iOS and macOS use the system haptics.
class PlatformHaptics implements HapticsBackend {
  /// Creates the backend.
  PlatformHaptics();

  Future<bool>? _hasVibrator;

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  Future<bool> get _canVibrate => _hasVibrator ??= _check();

  Future<bool> _check() async {
    try {
      return await Vibration.hasVibrator();
    } on Object catch (error) {
      AppLogger.debug('Vibrator check failed: ${error.runtimeType}');
      return false;
    }
  }

  Future<void> _pulse(
    List<int> pattern,
    List<int> intensities,
    Future<void> Function() fallback,
  ) async {
    if (_android && await _canVibrate) {
      try {
        await Vibration.vibrate(pattern: pattern, intensities: intensities);
        return;
      } on Object catch (error) {
        AppLogger.debug('Vibration failed: ${error.runtimeType}');
      }
    }
    try {
      await fallback();
    } on Object catch (error) {
      AppLogger.debug('Haptic feedback failed: ${error.runtimeType}');
    }
  }

  @override
  Future<void> select() =>
      _pulse(const [0, 8], const [0, 70], HapticFeedback.selectionClick);

  @override
  Future<void> tick() =>
      _pulse(const [0, 14], const [0, 110], HapticFeedback.selectionClick);

  @override
  Future<void> step() =>
      _pulse(const [0, 45], const [0, 220], HapticFeedback.heavyImpact);

  @override
  Future<void> celebrate() =>
      _pulse(const [0, 55, 90, 80], const [0, 230, 0, 255], () async {
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 140));
        await HapticFeedback.heavyImpact();
      });
}
