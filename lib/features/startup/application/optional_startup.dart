import 'dart:async';

import '../../../core/diagnostics/app_logger.dart';

/// Runs a start-up step the app can open without, and gives up on it rather
/// than let it hold the launch screen.
///
/// [task] is a function, not a future, so a step that throws before it ever
/// returns a future (a plugin that is not ready) fails here, where it is
/// caught, and not in the caller, where it would end `main` before `runApp`
/// and leave the launch screen up for good. Returns the step's result, or
/// null when it threw or took longer than [limit]; [onUnavailable] hears
/// which step.
Future<T?> optionalStartup<T>(
  String service,
  FutureOr<T> Function() task, {
  Duration limit = const Duration(seconds: 2),
  void Function(String service)? onUnavailable,
}) async {
  try {
    return await Future<T>.sync(task).timeout(limit);
  } on Object catch (error) {
    AppLogger.debug('Startup $service unavailable: ${error.runtimeType}');
    onUnavailable?.call(service);
    return null;
  }
}
