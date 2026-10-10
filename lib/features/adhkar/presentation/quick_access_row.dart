import 'package:flutter/material.dart';

import '../../../core/haptics/haptics.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/adhkar_collection.dart';
import 'adhkar_icons.dart';
import 'adhkar_steps_sheet.dart';

/// The lists people reach for most, one tap from the top of the page: the
/// daily adhkar, the dua of istikhara, the duas of the Quran, ruqyah.
///
/// A list that is not in the catalog is left out, so a trimmed data file never
/// leaves a dead chip.
class QuickAccessRow extends StatelessWidget {
  /// Creates the row from [catalog].
  const QuickAccessRow({super.key, required this.catalog, this.except});

  /// Where the lists are looked up.
  final AdhkarCatalog catalog;

  /// A list not to repeat here because the page already shows it large.
  final String? except;

  /// Collection ids in the order they show.
  static const List<String> ids = [
    'morning',
    'evening',
    'sleep',
    'after_prayer',
    'hisn_28',
    'quran_duas',
    'ruqya',
    'prophetic_duas',
  ];

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final items = [
      for (final id in ids)
        if (id != except) ?catalog.byId(id),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: AppTokens.minTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final collection = items[index];
          return ActionChip(
            avatar: Icon(adhkarIconData(collection.icon), size: 18),
            label: Text(collection.title(language)),
            onPressed: () {
              Haptics.select();
              AdhkarSteps.show(context, collectionId: collection.id);
            },
          );
        },
      ),
    );
  }
}
