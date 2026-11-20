import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_provider.dart';

/// The size of the words of the adhkar, relative to the default: the one kept
/// in the settings, and, while two fingers are still pinching, the one they
/// have reached. Only the words of the adhkar follow it, and nothing else in
/// the app.
final adhkarFontScaleProvider = NotifierProvider<AdhkarFontScale, double>(
  AdhkarFontScale.new,
);

/// Owns [adhkarFontScaleProvider].
class AdhkarFontScale extends Notifier<double> {
  @override
  double build() => ref.watch(
    settingsProvider.select((value) => value.value?.adhkarFontScale ?? 1),
  );

  /// Shows [scale] while the fingers are still moving, keeping nothing.
  void preview(double scale) => state = scale;

  /// Keeps [scale] in the settings, for the next time the adhkar are read.
  void keep(double scale) {
    state = scale;
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    unawaited(
      ref
          .read(settingsProvider.notifier)
          .save(settings.copyWith(adhkarFontScale: scale)),
    );
  }
}
