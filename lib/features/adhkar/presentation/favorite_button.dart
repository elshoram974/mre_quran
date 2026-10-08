import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../application/favorites_provider.dart';

/// A star that adds a list to the favourites or takes it out.
class FavoriteButton extends ConsumerWidget {
  /// Creates the star for the list [collectionId].
  const FavoriteButton({super.key, required this.collectionId});

  /// The list it stars.
  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starred = ref.watch(isAdhkarFavoriteProvider(collectionId));
    final l10n = context.l10n;
    return IconButton(
      tooltip: starred ? l10n.adhkarFavoriteRemove : l10n.adhkarFavoriteAdd,
      isSelected: starred,
      icon: const Icon(Icons.star_border_rounded),
      selectedIcon: Icon(
        Icons.star_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () =>
          ref.read(adhkarFavoritesProvider.notifier).toggle(collectionId),
    );
  }
}
