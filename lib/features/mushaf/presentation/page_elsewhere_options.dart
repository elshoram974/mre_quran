import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../settings/application/digits_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../application/page_elsewhere.dart';
import '../application/printed_fallback.dart';
import '../application/reading_position_provider.dart';

/// Under a printed page that cannot be had offline: the other readings that
/// have this page on the phone, each a button that opens it; or, when none
/// has it, the nearest page of this reading that is on the phone. Nothing
/// while that is worked out, or when there is nowhere to go.
class PageElsewhereOptions extends ConsumerWidget {
  /// Creates the options for [page] of [edition].
  const PageElsewhereOptions({
    super.key,
    required this.edition,
    required this.page,
  });

  /// The reading whose page could not be had.
  final MushafEdition edition;

  /// The page, 1–604.
  final int page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elsewhere = ref
        .watch(pageElsewhereProvider((edition: edition, page: page)))
        .value;
    if (elsewhere == null || elsewhere.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final digits = ref.watch(digitsFormatterProvider);
    final nearest = elsewhere.nearest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final reading in elsewhere.readings)
          TextButton.icon(
            onPressed: () =>
                ref.read(printedFallbackProvider.notifier).openReading(reading),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(l10n.printedSavedIn(reading.name(language))),
          ),
        if (elsewhere.readings.isEmpty && nearest != null)
          TextButton.icon(
            onPressed: () =>
                ref.read(readingPositionProvider.notifier).setPage(nearest),
            icon: const Icon(Icons.near_me_outlined),
            label: Text(l10n.printedNearestSaved(digits(nearest))),
          ),
      ],
    );
  }
}
