import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/startup_providers.dart';

/// Wraps what a Mushaf page shows once it shows more than a placeholder,
/// and notes, on its first frame, that the reader has its page on screen, so
/// the start-up splash can give way. At start-up the page appears at once,
/// without fading in (see `SvgPageView`), so that frame shows it whole.
class ReaderPaintedMark extends ConsumerStatefulWidget {
  /// Creates the mark around [child].
  const ReaderPaintedMark({super.key, required this.child});

  /// What the page shows.
  final Widget child;

  @override
  ConsumerState<ReaderPaintedMark> createState() => _ReaderPaintedMarkState();
}

class _ReaderPaintedMarkState extends ConsumerState<ReaderPaintedMark> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(readerPaintedProvider.notifier).painted();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
