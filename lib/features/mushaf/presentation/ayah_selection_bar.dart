import '../../../core/widgets/app_snack_bar.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../quran_text/domain/ayah_range.dart';
import '../../settings/application/digits_provider.dart';
import '../application/ayah_selection_provider.dart';
import 'ayah_share_format.dart';
import 'ayah_share_sheet.dart';

/// Lays the [AyahSelectionBar] over the reader where it hides nothing the
/// person is choosing: at the bottom, and at the top once they tap in the
/// lower half of the screen, so an ayah near the bottom can be reached. It
/// watches taps without taking them.
class AyahSelectionLayer extends ConsumerStatefulWidget {
  /// Creates the layer; the bar keeps [top] and [bottom] clear of the
  /// screen's edges.
  const AyahSelectionLayer({
    super.key,
    required this.top,
    required this.bottom,
  });

  /// Room left above the bar when it sits at the top.
  final double top;

  /// Room left under the bar when it sits at the bottom.
  final double bottom;

  @override
  ConsumerState<AyahSelectionLayer> createState() => _AyahSelectionLayerState();
}

class _AyahSelectionLayerState extends ConsumerState<AyahSelectionLayer> {
  bool _atTop = false;

  @override
  Widget build(BuildContext context) {
    final choosing = ref.watch(ayahSelectionProvider) != null;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppTokens.motionMedium;
    return LayoutBuilder(
      builder: (context, constraints) => Listener(
        // Sees every tap on the page, and lets it through.
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if (!choosing) return;
          final atTop = event.localPosition.dy > constraints.maxHeight / 2;
          if (atTop != _atTop) setState(() => _atTop = atTop);
        },
        child: IgnorePointer(
          ignoring: !choosing,
          child: AnimatedOpacity(
            opacity: choosing ? 1 : 0,
            duration: duration,
            child: AnimatedAlign(
              duration: duration,
              curve: Curves.easeOutCubic,
              alignment: _atTop
                  ? AlignmentDirectional.topCenter
                  : AlignmentDirectional.bottomCenter,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  top: widget.top,
                  bottom: widget.bottom,
                  start: 12,
                  end: 12,
                ),
                child: const AyahSelectionBar(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bar of the ayahs being chosen, on one row: how many and from where to
/// where, a hint to tap the last one, and copy, share and cancel. Nothing
/// shows while no ayahs are chosen.
class AyahSelectionBar extends ConsumerWidget {
  /// Creates the bar.
  const AyahSelectionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(ayahSelectionProvider);
    if (selection == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final digits = ref.watch(digitsFormatterProvider);
    final texts = selection.texts;
    final range = selection.range;
    final count = AyahOrder.of(texts).length(range);
    final messenger = ScaffoldMessenger.maybeOf(context);

    Future<void> copy() async {
      await Clipboard.setData(
        ClipboardData(text: ayahShareText(context, texts, range, digits)),
      );
      ref.read(ayahSelectionProvider.notifier).clear();
      messenger?.showSnackBar(AppSnackBar(l10n.ayahsCopied));
    }

    Future<void> share() async {
      final root = Navigator.of(context, rootNavigator: true).context;
      ref.read(ayahSelectionProvider.notifier).clear();
      await showAyahShare(root, texts, range);
    }

    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Material(
          color: theme.colorScheme.surfaceContainerLowest,
          elevation: 3,
          shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.35),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.selectionCount(count, digits(count))} · '
                        '${rangePlace(context, texts, range, digits)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        l10n.selectionHint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: muted,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.copyText,
                  onPressed: copy,
                  icon: const Icon(Icons.copy_outlined),
                ),
                IconButton.filled(
                  tooltip: l10n.shareAyah,
                  onPressed: share,
                  icon: const Icon(Icons.share_outlined),
                ),
                IconButton(
                  tooltip: l10n.cancelSelection,
                  onPressed: () =>
                      ref.read(ayahSelectionProvider.notifier).clear(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
