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

/// The bar that floats over the reader while ayahs are being chosen: how
/// many and from where to where, a hint to tap the last one, and copy,
/// share, and cancel. Nothing shows while no ayahs are chosen.
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
      messenger?.showSnackBar(SnackBar(content: Text(l10n.ayahsCopied)));
    }

    Future<void> share() async {
      final root = Navigator.of(context, rootNavigator: true).context;
      ref.read(ayahSelectionProvider.notifier).clear();
      await showAyahShare(root, texts, range);
    }

    return Semantics(
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
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectionCount(count, digits(count)),
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          rangePlace(context, texts, range, digits),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.cancelSelection,
                    onPressed: () =>
                        ref.read(ayahSelectionProvider.notifier).clear(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                l10n.selectionHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTokens.spaceSmall),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: copy,
                        icon: const Icon(Icons.copy_outlined),
                        label: Text(l10n.copyText),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceSmall),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: share,
                        icon: const Icon(Icons.share_outlined),
                        label: Text(l10n.shareAyah),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
