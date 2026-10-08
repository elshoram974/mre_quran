import 'platform_haptics.dart';

/// What a device does for each kind of feedback. Tests replace it to record
/// calls.
abstract interface class HapticsBackend {
  /// A very light tap for a selection, such as a tab.
  Future<void> select();

  /// A light tick for one count.
  Future<void> tick();

  /// A firmer pulse when a step is done and the next one comes.
  Future<void> step();

  /// A double pulse when a whole list is done.
  Future<void> celebrate();
}

/// The one place the app asks for vibration.
///
/// Call the static functions; never `HapticFeedback` or a vibration plugin
/// directly. The Settings switch sets [enabled], so every call site obeys it.
abstract final class Haptics {
  /// Whether the person wants vibration. Set from the Settings switch.
  static bool enabled = true;

  /// How feedback is produced. Replaced in tests.
  static HapticsBackend backend = PlatformHaptics();

  /// A very light tap for a selection.
  static Future<void> select() => enabled ? backend.select() : _done;

  /// A light tick for one count.
  static Future<void> tick() => enabled ? backend.tick() : _done;

  /// A firmer pulse when a step is done.
  static Future<void> step() => enabled ? backend.step() : _done;

  /// A double pulse when a whole list is done.
  static Future<void> celebrate() => enabled ? backend.celebrate() : _done;

  static final Future<void> _done = Future<void>.value();
}
