import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_tile_card.dart';
import '../../settings/application/digits_provider.dart';
import '../domain/adhkar_collection.dart';
import 'adhkar_icons.dart';

/// A tappable card for one group; opens the lists inside it.
class GroupCard extends ConsumerWidget {
  /// Creates a card for [group] holding [count] lists.
  const GroupCard({super.key, required this.group, required this.count});

  /// The group it opens.
  final AdhkarGroup group;

  /// Number of lists inside.
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(digitsFormatterProvider);
    return AppTileCard(
      avatar: true,
      icon: adhkarIconData(group.icon),
      title: group.title(Localizations.localeOf(context).languageCode),
      subtitle: context.l10n.adhkarListCount(digits(count)),
      onTap: () => context.push(AppRoute.adhkarGroupPath(group.id)),
    );
  }
}
