import 'package:mre_quran/features/home_widgets/data/home_widgets_platform.dart';
import 'package:mre_quran/features/home_widgets/domain/home_widget.dart';

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

  @override
  Future<bool> placed() async => isPlaced;
}
