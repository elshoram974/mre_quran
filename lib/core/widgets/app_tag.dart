import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A small label on a rounded background, for a note about an item such as
/// "after Maghrib only".
class AppTag extends StatelessWidget {
  /// Creates a tag reading [label].
  const AppTag(this.label, {super.key});

  /// The text.
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusField),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: scheme.onTertiaryContainer),
      ),
    );
  }
}
