import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';

/// The app's mark: two squares, one turned on the other, with a dot at their
/// middle, the eight-pointed star of the launch screen. It is drawn from the
/// colour it is given, so it sits on any surface, and it is decoration only:
/// hidden from screen readers.
class AppMark extends StatelessWidget {
  /// Creates the mark, [size] logical pixels across, in [color].
  const AppMark({super.key, this.size = 20, this.color});

  /// Width and height of the mark.
  final double size;

  /// The colour of its lines. The theme's primary colour when null.
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(color ?? Theme.of(context).colorScheme.primary),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    // The turned square's corners reach the edge of the box.
    final side = size.width / math.sqrt2;
    final line = size.width * 0.07;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = line
      ..strokeJoin = StrokeJoin.round;
    for (final turn in [0.0, math.pi / 4]) {
      canvas
        ..save()
        ..translate(centre.dx, centre.dy)
        ..rotate(turn);
      final square = Rect.fromCenter(
        center: Offset.zero,
        width: side - line,
        height: side - line,
      );
      canvas
        ..drawRect(square, fill)
        ..drawRect(square, stroke)
        ..restore();
    }
    canvas.drawCircle(centre, size.width * 0.085, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.color != color;
}

/// The app's mark and its name, small: the signature of a sheet or a dialog,
/// so what speaks is known to be the app.
class AppBrand extends StatelessWidget {
  /// Creates the signature.
  const AppBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppMark(size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            context.l10n.appTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
