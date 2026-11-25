import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// The colour family of an [AppTag].
enum AppTagTone {
  /// The tertiary accent: a note that stands out.
  accent,

  /// The primary colour: one of two kinds told apart at a glance.
  primary,

  /// The secondary colour: the other of two kinds.
  secondary,

  /// A quiet fact, such as a count.
  neutral,
}

/// A small label on a rounded background, for a note about an item such as
/// "after Maghrib only", or a fact about it such as "Meccan" or "7 ayahs".
class AppTag extends StatelessWidget {
  /// Creates a tag reading [label], with an optional leading [icon].
  const AppTag(
    this.label, {
    super.key,
    this.icon,
    this.tone = AppTagTone.accent,
  });

  /// The text.
  final String label;

  /// A small icon before the text.
  final IconData? icon;

  /// Its colours.
  final AppTagTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      AppTagTone.accent => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      AppTagTone.primary => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      AppTagTone.secondary => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      AppTagTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    final text = Text(
      label,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: foreground),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.radiusField),
      ),
      child: icon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppTokens.iconSmall, color: foreground),
                const SizedBox(width: AppTokens.spaceTiny),
                Flexible(child: text),
              ],
            ),
    );
  }
}
