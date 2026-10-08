import 'package:flutter/material.dart';

/// The heading of a group of rows, with an optional line of help under it.
///
/// Every screen uses this one, so headings keep one size, one gap, and are
/// announced as headings by screen readers.
class AppSectionHeader extends StatelessWidget {
  /// Creates a heading with [title] and an optional [subtitle].
  const AppSectionHeader({super.key, required this.title, this.subtitle});

  /// The heading.
  final String title;

  /// Help shown under the heading.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
