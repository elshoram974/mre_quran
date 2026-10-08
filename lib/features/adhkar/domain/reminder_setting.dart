import 'package:meta/meta.dart';

/// A daily reminder for one collection.
@immutable
class ReminderSetting {
  /// Creates a setting that fires at [minutes] after midnight when [enabled].
  const ReminderSetting({required this.enabled, required this.minutes});

  /// Reads a setting saved by [toJson]. Returns null for anything unreadable.
  static ReminderSetting? tryFromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final enabled = json['on'];
    final minutes = json['m'];
    if (enabled is! bool || minutes is! int || !isValidMinutes(minutes)) {
      return null;
    }
    return ReminderSetting(enabled: enabled, minutes: minutes);
  }

  /// Whether the reminder is on.
  final bool enabled;

  /// Time of day as minutes after midnight, 0 to 1439.
  final int minutes;

  /// Hour part of [minutes].
  int get hour => minutes ~/ 60;

  /// Minute part of [minutes].
  int get minute => minutes % 60;

  /// Whether [minutes] is a time of day.
  static bool isValidMinutes(int minutes) => minutes >= 0 && minutes < 1440;

  /// Reads `HH:mm`. Returns null for anything else.
  static int? parseClock(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(value);
    if (match == null) return null;
    return int.parse(match[1]!) * 60 + int.parse(match[2]!);
  }

  /// A copy with the given changes.
  ReminderSetting copyWith({bool? enabled, int? minutes}) => ReminderSetting(
    enabled: enabled ?? this.enabled,
    minutes: minutes ?? this.minutes,
  );

  /// Compact form for storage.
  Map<String, Object?> toJson() => {'on': enabled, 'm': minutes};

  @override
  bool operator ==(Object other) =>
      other is ReminderSetting &&
      other.enabled == enabled &&
      other.minutes == minutes;

  @override
  int get hashCode => Object.hash(enabled, minutes);
}
