/// Shared choices for every placed prayer schedule widget.
class PrayerScheduleOptions {
  /// Creates the default full schedule with its useful details.
  const PrayerScheduleOptions({
    this.upcomingOnly = false,
    this.showSunrise = true,
    this.showDate = true,
    this.showCountdown = true,
    this.largeText = false,
  });

  /// Show the next three prayers instead of the full day's schedule.
  final bool upcomingOnly;

  /// Include sunrise in the full daily schedule.
  final bool showSunrise;

  /// Show the Gregorian and Hijri dates when space permits.
  final bool showDate;

  /// Show the time remaining until the next prayer.
  final bool showCountdown;

  /// Prefer larger text, showing fewer rows when needed.
  final bool largeText;

  /// Restores options sent by the platform, with safe defaults.
  factory PrayerScheduleOptions.fromMap(Map<Object?, Object?>? map) =>
      PrayerScheduleOptions(
        upcomingOnly: map?['upcomingOnly'] == true,
        showSunrise: map?['showSunrise'] != false,
        showDate: map?['showDate'] != false,
        showCountdown: map?['showCountdown'] != false,
        largeText: map?['largeText'] == true,
      );

  /// Sends the choices to the native widget renderer.
  Map<String, bool> toMap() => {
    'upcomingOnly': upcomingOnly,
    'showSunrise': showSunrise,
    'showDate': showDate,
    'showCountdown': showCountdown,
    'largeText': largeText,
  };

  /// Returns the same choices with selected fields changed.
  PrayerScheduleOptions copyWith({
    bool? upcomingOnly,
    bool? showSunrise,
    bool? showDate,
    bool? showCountdown,
    bool? largeText,
  }) => PrayerScheduleOptions(
    upcomingOnly: upcomingOnly ?? this.upcomingOnly,
    showSunrise: showSunrise ?? this.showSunrise,
    showDate: showDate ?? this.showDate,
    showCountdown: showCountdown ?? this.showCountdown,
    largeText: largeText ?? this.largeText,
  );
}
