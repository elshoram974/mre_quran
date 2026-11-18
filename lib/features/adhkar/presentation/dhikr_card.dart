import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon_badge.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_surface_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../quran_text/application/quran_text_providers.dart';
import '../../settings/application/digits_provider.dart';
import '../application/adhkar_providers.dart';
import '../application/passage_text.dart';
import '../domain/adhkar_collection.dart';
import '../../prayer/application/prayer_provider.dart';
import '../../prayer/domain/prayer_times.dart';
import '../domain/adhkar_layout.dart';
import '../domain/dhikr.dart';
import 'dhikr_counter.dart';
import 'evidence_sheet.dart';

/// One dhikr: its words, how many times to say it, a way to read the
/// evidence, and, unless it is shown elsewhere, a big tap-to-count button.
class DhikrCard extends ConsumerWidget {
  /// Creates the card for [dhikr], the [number]th of [collection].
  const DhikrCard({
    super.key,
    required this.collection,
    required this.dhikr,
    required this.number,
    required this.onCount,
    required this.onUndo,
    required this.onReset,
    this.showCounter = true,
  });

  /// Whether the card holds its own counter. A screen that pins the counter
  /// somewhere else, clear of the scrolling words, turns this off.
  final bool showCounter;

  /// The collection it belongs to.
  final AdhkarCollection collection;

  /// The dhikr shown.
  final Dhikr dhikr;

  /// Position in the collection, starting at 1.
  final int number;

  /// Called when the person taps the counter.
  final VoidCallback onCount;

  /// Called when the person takes back one repeat.
  final VoidCallback onUndo;

  /// Called to reset this dhikr's count.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final digits = ref.watch(digitsFormatterProvider);
    final count = ref.watch(dhikrCountProvider((collection, dhikr)));
    final done = count >= dhikr.repeat;

    // Opaque on every platform: the words may be Quran text, never on glass.
    return RepaintBoundary(
      child: AppSurfaceCard(
        highlighted: done,
        padding: const EdgeInsetsDirectional.all(AppTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A Wrap so the evidence button drops to its own line when large
            // text leaves no room beside the repeat label.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIconBadge.text(digits(number), emphasized: done),
                    if (dhikr.onlyAfter.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _OnlyAfterChip(prayers: dhikr.onlyAfter),
                    ],
                    if (dhikr.repeatLabel.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            dhikr.repeatLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton.icon(
                  onPressed: () => EvidenceSheet.show(context, dhikr),
                  icon: const Icon(Icons.menu_book_outlined, size: 20),
                  label: Text(l10n.adhkarEvidence),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (dhikr.label != null) ...[
              // Arabic like the words it introduces, whatever the interface.
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  dhikr.label!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            _DhikrWords(collection: collection, dhikr: dhikr, done: done),
            if (showCounter) ...[
              const SizedBox(height: 16),
              DhikrCounter(
                collection: collection,
                dhikr: dhikr,
                onCount: onCount,
                onUndo: onUndo,
                onReset: onReset,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "After Fajr and Maghrib only": for a dhikr said after some prayers only.
class _OnlyAfterChip extends StatelessWidget {
  const _OnlyAfterChip({required this.prayers});

  final Set<String> prayers;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final names = [
      for (final prayer in DailyPrayer.values)
        if (prayers.contains(prayer.name)) prayerName(l10n, prayer),
    ];
    final joined = names.length < 2
        ? names.join()
        : l10n.adhkarAnd(
            names.sublist(0, names.length - 1).join('، '),
            names.last,
          );
    return Flexible(child: AppTag(l10n.adhkarOnlyAfter(joined)));
  }
}

/// The words of a dhikr. A Quran dhikr shows a placeholder while the verified
/// text loads, and a retry when it cannot.
class _DhikrWords extends ConsumerWidget {
  const _DhikrWords({
    required this.collection,
    required this.dhikr,
    required this.done,
  });

  final AdhkarCollection collection;
  final Dhikr dhikr;
  final bool done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ref
        .watch(dhikrTextProvider(dhikr))
        .when(
          loading: () => const AppShimmer(
            child: Column(
              children: [
                SkeletonBox(height: 22),
                SizedBox(height: 10),
                SkeletonBox(height: 22),
                SizedBox(height: 10),
                SkeletonBox(height: 22),
              ],
            ),
          ),
          error: (_, _) => TextButton.icon(
            onPressed: () => ref.invalidate(quranTextDataProvider),
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.retry),
          ),
          // The words are Arabic whatever the interface language is.
          data: (text) => Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              layoutAdhkarText(text),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTokens.quranFontFamily,
                fontSize: 24,
                height: 2,
                color: scheme.onSurface.withValues(alpha: done ? 0.7 : 1),
              ),
            ),
          ),
        );
  }
}
