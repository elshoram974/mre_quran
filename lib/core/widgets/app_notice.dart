import 'package:flutter/material.dart';

/// A line of text with an icon, for something the person should know right
/// where they are: why a switch stayed off, or a short hint. An [error] one is
/// red and announced by screen readers when it appears.
class AppNotice extends StatelessWidget {
  /// Creates a notice reading [message].
  const AppNotice(this.message, {super.key, this.error = false, this.icon});

  /// The text.
  final String message;

  /// Whether it says something went wrong.
  final bool error;

  /// Icon at the start; a default is chosen from [error].
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = error
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      liveRegion: error,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? (error ? Icons.error_outline : Icons.info_outline),
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
