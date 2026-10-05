import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_platform.dart';

/// Shared two-or-more way switch. Cupertino sliding control on iOS, Material 3
/// segmented button elsewhere.
class AppSegmentedControl<T extends Object> extends StatelessWidget {
  /// Creates a control for [segments] with [value] selected.
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  /// Value to label, in display order.
  final Map<T, String> segments;

  /// Selected value.
  final T value;

  /// Called with the chosen value.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    if (context.isCupertino) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<T>(
          groupValue: value,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          thumbColor: Theme.of(context).colorScheme.surface,
          onValueChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
          children: {
            for (final entry in segments.entries)
              entry.key: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(entry.value),
              ),
          },
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        segments: [
          for (final entry in segments.entries)
            ButtonSegment<T>(value: entry.key, label: Text(entry.value)),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
