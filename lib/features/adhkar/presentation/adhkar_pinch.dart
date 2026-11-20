import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/pinch_zoom.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../application/adhkar_font_scale_provider.dart';

/// Lets two fingers change the size of the words of the adhkar under it. The
/// words are set again at each size the fingers reach, and the size is kept
/// for next time; nothing else on the screen changes.
class AdhkarPinch extends ConsumerWidget {
  /// Creates the detector around [child], the adhkar being read.
  const AdhkarPinch({super.key, required this.child});

  /// The adhkar.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(adhkarFontScaleProvider.notifier);
    return PinchZoom(
      value: ref.watch(
        settingsProvider.select((value) => value.value?.adhkarFontScale ?? 1),
      ),
      min: AppSettings.minReaderFontScale,
      max: AppSettings.maxReaderFontScale,
      onChanging: notifier.preview,
      onChanged: notifier.keep,
      child: child,
    );
  }
}
