import 'package:mre_quran/features/home_widgets/data/home_widgets_platform.dart';
import 'package:mre_quran/features/home_widgets/domain/home_widget.dart';
import 'package:mre_quran/features/home_widgets/domain/prayer_schedule_options.dart';

/// A home screen in a test: whether the launcher takes requests, which
/// widgets were asked for, and whether one is placed.
class FakeHomeWidgets implements HomeWidgetsPlatform {
  /// Creates the fake.
  FakeHomeWidgets({this.pinnable = true, this.isPlaced = false});

  /// Whether the launcher takes requests.
  final bool pinnable;

  /// Whether one of the app's widgets is on the home screen.
  bool isPlaced;

  /// The widgets asked for, in order.
  final List<HomeWidget> pinned = [];

  @override
  Future<bool> canPin() async => pinnable;

  @override
  Future<bool> pin(HomeWidget widget) async {
    if (!pinnable) return false;
    pinned.add(widget);
    return true;
  }

  WidgetAppearance style = WidgetAppearance.automatic;
  @override
  Future<WidgetAppearance> appearance() async => style;
  @override
  Future<bool> setAppearance(WidgetAppearance value) async {
    style = value;
    return true;
  }

  PrayerScheduleOptions scheduleOptions = const PrayerScheduleOptions();
  bool failScheduleSave = false;

  @override
  Future<PrayerScheduleOptions> prayerScheduleOptions() async =>
      scheduleOptions;

  @override
  Future<bool> setPrayerScheduleOptions(PrayerScheduleOptions options) async {
    if (failScheduleSave) return false;
    scheduleOptions = options;
    return true;
  }

  @override
  Future<bool> placed() async => isPlaced;
}
