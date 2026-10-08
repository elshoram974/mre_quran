import 'package:flutter/material.dart';

/// A ring that fills as [fraction] grows, with [icon] in the middle.
class ProgressRing extends StatelessWidget {
  /// Creates a ring of [size] logical pixels.
  const ProgressRing({
    super.key,
    required this.fraction,
    required this.icon,
    this.size = 56,
  });

  /// Filled share, 0 to 1.
  final double fraction;

  /// Glyph in the middle.
  final IconData icon;

  /// Width and height.
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final still = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: fraction),
            duration: still ? Duration.zero : const Duration(milliseconds: 300),
            builder: (context, value, _) => SizedBox.square(
              dimension: size,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ),
          Icon(icon, size: size * 0.45, color: scheme.primary),
        ],
      ),
    );
  }
}
