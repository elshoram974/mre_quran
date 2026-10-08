import 'package:flutter/material.dart';

import 'app_card.dart';

/// One card that holds several rows (switches, lists) with a hairline between
/// them, so related settings read as one group instead of a stack of cards.
class AppGroupCard extends StatelessWidget {
  /// Creates a card around [children].
  const AppGroupCard({super.key, required this.children});

  /// The rows, top to bottom.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final line = Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outlineVariant
          .withValues(alpha: 0.5),
    );
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) line,
            children[i],
          ],
        ],
      ),
    );
  }
}
