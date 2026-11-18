import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/home_widget.dart';
import '../domain/prayer_schedule_options.dart';
import '../data/home_widgets_platform.dart';

/// Provides the platform. Tests override it.
final homeWidgetsPlatformProvider = Provider<HomeWidgetsPlatform>(
  (ref) => const MethodChannelHomeWidgets(),
);

/// Whether the app can add widgets to the home screen itself.
final canPinWidgetsProvider = FutureProvider<bool>(
  (ref) => ref.watch(homeWidgetsPlatformProvider).canPin(),
);

/// The native preference is shared with widgets even when Flutter is closed.
final widgetAppearanceProvider = FutureProvider<WidgetAppearance>(
  (ref) => ref.watch(homeWidgetsPlatformProvider).appearance(),
);

/// The user's shared prayer schedule choices, applied immediately.
final prayerScheduleOptionsProvider =
    AsyncNotifierProvider<PrayerScheduleOptionsNotifier, PrayerScheduleOptions>(
      PrayerScheduleOptionsNotifier.new,
    );

/// Loads, saves and rolls back native prayer widget choices.
class PrayerScheduleOptionsNotifier
    extends AsyncNotifier<PrayerScheduleOptions> {
  int _saveGeneration = 0;

  @override
  Future<PrayerScheduleOptions> build() =>
      ref.read(homeWidgetsPlatformProvider).prayerScheduleOptions();

  /// Applies [next] immediately and restores the previous value on failure.
  Future<bool> save(PrayerScheduleOptions next) async {
    final previous = state.value;
    final generation = ++_saveGeneration;
    state = AsyncData(next);
    final saved = await ref
        .read(homeWidgetsPlatformProvider)
        .setPrayerScheduleOptions(next);
    if (!saved && previous != null && generation == _saveGeneration) {
      state = AsyncData(previous);
    }
    return saved;
  }
}
