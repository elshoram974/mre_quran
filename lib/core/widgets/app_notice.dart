import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// A line of text with an icon, for something the person should know right
/// where they are: why a switch stayed off, or a short hint. An [error] one is
/// red and announced by screen readers when it appears.
///
/// An [important] one is for what the person must not miss, such as a setting
/// the alerts depend on: red, on a tinted box of its own, with its [action]
/// inside the box, so it is seen as soon as the page opens.
///
/// A [confirmed] one says that what was asked for is now so: in the accent
/// colour, with a tick.
class AppNotice extends StatelessWidget {
  /// Creates a notice reading [message].
  const AppNotice(
    this.message, {
    super.key,
    this.error = false,
    this.icon,
    this.important = false,
    this.confirmed = false,
    this.action,
  });

  /// The text.
  final String message;

  /// Whether it says something went wrong.
  final bool error;

  /// Icon at the start; a default is chosen from [error], [important] and
  /// [confirmed].
  final IconData? icon;

  /// Whether it says something the person must act on or not miss.
  final bool important;

  /// Whether it confirms that something is as it should be. An [error] or
  /// [important] notice stays red.
  final bool confirmed;

  /// What the person can do about it, under the text: only an [important]
  /// notice shows it.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final red = error || important;
    final color = red
        ? scheme.error
        : confirmed
        ? scheme.primary
        : scheme.onSurfaceVariant;
    final line = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon ??
              (important
                  ? Icons.warning_amber_rounded
                  : error
                  ? Icons.error_outline
                  : confirmed
                  ? Icons.check_circle_outline
                  : Icons.info_outline),
          size: important ? 22 : 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: important ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
    if (!important) {
      return Semantics(liveRegion: error, child: line);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        border: Border.all(color: scheme.error.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(AppTokens.radiusField),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppTokens.spaceSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            line,
            if (action != null) ...[
              const SizedBox(height: AppTokens.spaceSmall),
              Align(alignment: AlignmentDirectional.centerStart, child: action),
            ],
          ],
        ),
      ),
    );
  }
}
