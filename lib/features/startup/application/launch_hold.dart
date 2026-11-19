import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps the platform's own launch screen up while the first screen loads.
///
/// Android and iOS show their launch screen until Flutter sends its first
/// frame. [LaunchHold.hold] holds that frame back (the framework still builds,
/// lays out and paints every frame, so the first screen loads underneath, but
/// none reaches the screen) until [release], and never longer than its
/// longest wait. No splash is drawn in Flutter: the launch screen the person
/// sees is the native one only.
class LaunchHold {
  LaunchHold._(this._held);

  /// Holds the first frame back for at most [most]. Call once, before
  /// `runApp`. The limit is kept here, not in a widget, so nothing that goes
  /// wrong while the app builds can keep the launch screen up. [onRelease]
  /// hears why the frame went: `ready`, or `limit` when the first screen was
  /// not ready in time.
  factory LaunchHold.hold({
    required Duration most,
    void Function(String reason)? onRelease,
  }) {
    WidgetsBinding.instance.deferFirstFrame();
    final hold = LaunchHold._(true).._onRelease = onRelease;
    hold._limit = Timer(most, () => hold.release(reason: 'limit'));
    return hold;
  }

  /// Holds nothing (tests, and anywhere `main` did not hold).
  factory LaunchHold.none() => LaunchHold._(false);

  bool _held;
  Timer? _limit;
  void Function(String reason)? _onRelease;

  /// Whether the first frame is still held back.
  bool get held => _held;

  /// Lets the first frame through, so the launch screen goes. Only the first
  /// call does anything. Call it outside a frame (the first frame is
  /// scheduled only while the scheduler is idle).
  void release({String reason = 'ready'}) {
    if (!_held) return;
    _held = false;
    _limit?.cancel();
    _onRelease?.call(reason);
    WidgetsBinding.instance.allowFirstFrame();
  }
}

/// The hold `main` placed on the first frame. Holds nothing unless
/// overridden.
final launchHoldProvider = Provider<LaunchHold>((ref) => LaunchHold.none());
