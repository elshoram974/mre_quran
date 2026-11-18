import 'package:flutter/services.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../domain/home_widget.dart';

/// What the platform can do with the app's home-screen widgets.
abstract interface class HomeWidgetsPlatform {
  /// Whether the app can ask the launcher to add a widget (Android 8 and
  /// later, on a launcher that takes such requests). iOS never lets an app
  /// add one.
  Future<bool> canPin();

  /// Asks the launcher to add [widget]; false when it could not ask.
  Future<bool> pin(HomeWidget widget);

  /// Whether any of the app's widgets is on the home screen now.
  Future<bool> placed();
}

/// [HomeWidgetsPlatform] over the app's own channel (MainActivity on
/// Android, AppDelegate on iOS). Elsewhere it can do nothing.
class MethodChannelHomeWidgets implements HomeWidgetsPlatform {
  /// Creates the platform.
  const MethodChannelHomeWidgets();

  static const _channel = MethodChannel('net.mrecode.mre_quran/home_widgets');

  Future<bool> _ask(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<bool>(method, arguments) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      AppLogger.debug('Home widgets $method failed: ${error.code}');
      return false;
    }
  }

  @override
  Future<bool> canPin() => _ask('canPin');

  @override
  Future<bool> pin(HomeWidget widget) => _ask('pin', widget.name);

  @override
  Future<bool> placed() => _ask('placed');
}
