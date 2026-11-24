import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_stepper.dart';
import '../application/prayer_provider.dart' show prayerName;
import '../domain/prayer_times.dart';
import 'prayer_labels.dart';

/// A prayer's name and a time, and under them a stepper that moves a number
/// of minutes: the minutes added to the prayer, or the gap before its iqama.
///
/// With large text the time goes under the name, so neither is squeezed.
class PrayerStepRow extends StatelessWidget {
  /// Creates a row for [prayer]. [time] is the time that results, when known;
  /// [label] says the minutes in words.
  const PrayerStepRow({
    super.key,
    required this.prayer,
    required this.time,
    this.note,
    required this.label,
    required this.highlighted,
    required this.decreaseLabel,
    required this.increaseLabel,
    required this.onDecrease,
    required this.onIncrease,
  });

  /// The prayer.
  final DailyPrayer prayer;

  /// The time that results, written out; null when there is none to show.
  final String? time;

  /// A line under [time]: what it was before, when it has been moved.
  final String? note;

  /// The minutes, in words.
  final String label;

  /// Whether the minutes differ from the usual, which colours them.
  final bool highlighted;

  /// What the left button does.
  final String decreaseLabel;

  /// What the right button does.
  final String increaseLabel;

  /// Called to step down; null at the lowest value.
  final VoidCallback? onDecrease;

  /// Called to step up; null at the highest value.
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // With large text, or in little room, the time goes under the name.
      final stacked =
          MediaQuery.textScalerOf(context).scale(1) >=
              AppTokens.stackTextScale ||
          constraints.maxWidth < _narrow;
      return _build(context, stacked);
    },
  );

  /// The width below which the time goes under the name.
  static const double _narrow = 300;

  Widget _build(BuildContext context, bool stacked) {
    final theme = Theme.of(context);
    final icon = Icon(prayerIcon(prayer), color: theme.colorScheme.primary);
    final name = Text(
      prayerName(context.l10n, prayer),
      style: theme.textTheme.titleMedium,
    );
    // The time that results, in the accent when moved from the usual.
    final result = time == null
        ? null
        : Column(
            crossAxisAlignment: stacked
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Text(
                time!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: highlighted ? theme.colorScheme.primary : null,
                ),
              ),
              if (note != null)
                Text(
                  note!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
      child: Column(
        children: [
          if (stacked) ...[
            Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(child: name),
              ],
            ),
            if (result != null)
              Align(alignment: AlignmentDirectional.centerStart, child: result),
          ] else
            Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(child: name),
                ?result,
              ],
            ),
          const SizedBox(height: 4),
          AppStepper(
            label: label,
            highlighted: highlighted,
            decreaseLabel: decreaseLabel,
            increaseLabel: increaseLabel,
            onDecrease: onDecrease,
            onIncrease: onIncrease,
          ),
        ],
      ),
    );
  }
}
