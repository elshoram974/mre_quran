import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../settings/application/digits_provider.dart';
import '../domain/adhkar_collection.dart';
import 'adhkar_icons.dart';

/// A compact tile for one group, so a screen shows many at once: the icon, the
/// name, and how many lists are inside. A tap opens the group.
class GroupCard extends ConsumerWidget {
  /// Creates a tile for [group] holding [count] lists.
  const GroupCard({super.key, required this.group, required this.count});

  /// The group it opens.
  final AdhkarGroup group;

  /// Number of lists inside.
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final digits = ref.watch(digitsFormatterProvider);
    final title = group.title(Localizations.localeOf(context).languageCode);
    final subtitle = context.l10n.adhkarListCount(digits(count));
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      excludeSemantics: true,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            onTap: () => context.push(AppRoute.adhkarGroupPath(group.id)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.onSecondaryContainer,
                    child: Icon(adhkarIconData(group.icon)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
