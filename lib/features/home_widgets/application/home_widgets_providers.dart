import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/home_widget.dart';
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
