/// The app's home-screen widgets. Each name is the one the platforms use
/// for it (the Android provider and the iOS widget kind are mapped from it
/// natively).
enum HomeWidget {
  /// The coming prayer with the time left, and the day's five prayers.
  prayerCard,

  /// The coming prayer, its time and the time left.
  nextPrayer,

  /// The day's five prayers and sunrise, with the Hijri date.
  prayerSchedule,

  /// A tasbih counter.
  tasbih,

  /// A suggested dhikr with its saved progress.
  dhikr,
}

/// Background used by all home-screen widgets in full colour.
enum WidgetAppearance { automatic, navy, green }
