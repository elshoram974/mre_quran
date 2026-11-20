import 'package:material_ui/material_ui.dart';

/// A slider for how big some text is shown, from smaller to larger, with the
/// size as a percentage beside its title. It changes nothing itself: the owner
/// keeps the size and draws its text at it.
class TextSizeSlider extends StatelessWidget {
  /// Creates the slider titled [title], now at [value] of the default size.
  const TextSizeSlider({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.hint,
  });

  /// What the size is of: "Mushaf text", "Adhkar text".
  final String title;

  /// The size now, as a multiple of the default.
  final double value;

  /// The smallest size.
  final double min;

  /// The largest size.
  final double max;

  /// Called with each size the slider reaches.
  final ValueChanged<double> onChanged;

  /// A line under the slider, such as how else the size can be changed.
  final String? hint;

  /// Steps between [min] and [max], 0.1 apart in the app's ranges.
  static const int _steps = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = '${(value * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            Text(
              percent,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.text_decrease, size: 20),
            Expanded(
              child: Slider.adaptive(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: _steps,
                label: percent,
                semanticFormatterCallback: (_) => percent,
                onChanged: onChanged,
              ),
            ),
            const Icon(Icons.text_increase, size: 20),
          ],
        ),
        if (hint case final hint?)
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
