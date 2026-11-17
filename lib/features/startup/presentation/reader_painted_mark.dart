import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../application/startup_providers.dart';

/// Wraps what a Mushaf page shows once it shows more than a placeholder,
/// and notes, once it has faded in, that the reader has its page on
/// screen, so the start-up splash can give way.
class ReaderPaintedMark extends ConsumerStatefulWidget {
  /// Creates the mark around [child].
  const ReaderPaintedMark({super.key, required this.child});

  /// What the page shows.
  final Widget child;

  @override
  ConsumerState<ReaderPaintedMark> createState() => _ReaderPaintedMarkState();
}

class _ReaderPaintedMarkState extends ConsumerState<ReaderPaintedMark> {
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    // The page fades in over its placeholder; the splash waits until it
    // has, so the placeholder is never seen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _settle = Timer(
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppTokens.motionMedium,
        () {
          if (mounted) ref.read(readerPaintedProvider.notifier).painted();
        },
      );
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
