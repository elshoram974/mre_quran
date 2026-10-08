import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current local time. Tests override it.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The current time as screens see it, read again every 30 seconds so a window
/// that ends, a prayer that comes, or a day that turns shows without a restart.
final tickingNowProvider = NotifierProvider<TickingNow, DateTime>(
  TickingNow.new,
);

/// Holds [tickingNowProvider]'s time.
class TickingNow extends Notifier<DateTime> {
  @override
  DateTime build() {
    final timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    ref.onDispose(timer.cancel);
    return ref.read(clockProvider)();
  }

  /// Reads the clock again.
  void refresh() => state = ref.read(clockProvider)();
}
