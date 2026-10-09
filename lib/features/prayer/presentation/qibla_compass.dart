import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The compass card: the four directions and a tick every 5°, turning so that
/// north on the card is north in the world, and a Kaaba marker on the rim at
/// the Qibla.
///
/// When [heading] is null (no compass sensor) the card is fixed with north at
/// the top, and the marker still shows the Qibla's angle from north.
///
/// A compass turns the same way in every language, so this is drawn with
/// physical angles on purpose; nothing here follows the text direction.
class QiblaCompass extends StatelessWidget {
  /// Creates the compass.
  const QiblaCompass({
    super.key,
    required this.qibla,
    required this.heading,
    required this.aligned,
    required this.letters,
    required this.semanticLabel,
  });

  /// Direction of the Qibla, degrees clockwise from north.
  final double qibla;

  /// Where the top of the phone points, or null without a sensor.
  final double? heading;

  /// Whether the phone faces the Qibla.
  final bool aligned;

  /// North, east, south and west letters, in that order.
  final List<String> letters;

  /// Announced by screen readers in place of the drawing.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: 1,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              end: aligned ? scheme.primary : scheme.outlineVariant,
            ),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            builder: (context, ring, _) => CustomPaint(
              painter: _CompassPainter(
                qibla: qibla,
                heading: heading ?? 0,
                ring: ring ?? scheme.outlineVariant,
                aligned: aligned,
                face: scheme.surfaceContainerHigh,
                tick: scheme.onSurfaceVariant,
                accent: scheme.primary,
                onAccent: scheme.onPrimary,
                north: scheme.error,
                text: scheme.onSurface,
                textStyle: Theme.of(context).textTheme.titleMedium!,
                letters: letters,
                direction: Directionality.of(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.qibla,
    required this.heading,
    required this.ring,
    required this.aligned,
    required this.face,
    required this.tick,
    required this.accent,
    required this.onAccent,
    required this.north,
    required this.text,
    required this.textStyle,
    required this.letters,
    required this.direction,
  });

  final double qibla;
  final double heading;
  final Color ring;
  final bool aligned;
  final Color face;
  final Color tick;
  final Color accent;
  final Color onAccent;
  final Color north;
  final Color text;
  final TextStyle textStyle;
  final List<String> letters;
  final TextDirection direction;

  static double _rad(double degrees) => degrees * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 14;

    canvas
      ..drawCircle(center, radius, Paint()..color = face)
      ..drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = aligned ? 5 : 2
          ..color = ring,
      );

    // The card: everything on it turns against the phone.
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(-_rad(heading));
    _ticks(canvas, radius);
    _letters(canvas, radius);
    _marker(canvas, radius);
    canvas.restore();

    _lubberLine(canvas, center, radius);
  }

  void _ticks(Canvas canvas, double radius) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..color = tick;
    for (var degrees = 0; degrees < 360; degrees += 5) {
      final major = degrees % 45 == 0;
      if (degrees % 90 == 0) continue; // the letters sit here
      paint.strokeWidth = major ? 2.5 : 1.2;
      final outer = radius - 8;
      final inner = outer - (major ? 14 : 7);
      final dx = math.sin(_rad(degrees.toDouble()));
      final dy = -math.cos(_rad(degrees.toDouble()));
      canvas.drawLine(
        Offset(dx * inner, dy * inner),
        Offset(dx * outer, dy * outer),
        paint,
      );
    }
  }

  void _letters(Canvas canvas, double radius) {
    for (var i = 0; i < 4; i++) {
      final angle = _rad(i * 90.0);
      final at = Offset(
        math.sin(angle) * (radius - 30),
        -math.cos(angle) * (radius - 30),
      );
      final painter = TextPainter(
        text: TextSpan(
          text: letters[i],
          style: textStyle.copyWith(
            color: i == 0 ? north : text,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: direction,
      )..layout();
      // Keep each letter upright as the card turns.
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..rotate(_rad(heading));
      painter.paint(canvas, -painter.size.center(Offset.zero));
      canvas.restore();
      painter.dispose();
    }
  }

  void _marker(Canvas canvas, double radius) {
    final angle = _rad(qibla);
    final dx = math.sin(angle);
    final dy = -math.cos(angle);
    final spot = Offset(dx * (radius - 62), dy * (radius - 62));
    canvas.drawLine(
      Offset.zero,
      Offset(dx * (radius - 84), dy * (radius - 84)),
      Paint()
        ..color = accent.withValues(alpha: 0.5)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(spot, 22, Paint()..color = accent);
    // The Kaaba: a small dark cube with a gold band.
    final cube = Rect.fromCenter(center: spot, width: 18, height: 18);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(cube, const Radius.circular(2)),
        Paint()..color = onAccent,
      )
      ..drawRect(
        Rect.fromLTWH(cube.left, cube.top + 4, cube.width, 3),
        Paint()..color = accent,
      );
    canvas.drawCircle(Offset.zero, 6, Paint()..color = accent);
  }

  /// The fixed mark at the top of the dial showing where the phone points.
  void _lubberLine(Canvas canvas, Offset center, double radius) {
    final top = center.dy - radius;
    final path = Path()
      ..moveTo(center.dx, top + 2)
      ..lineTo(center.dx - 9, top - 10)
      ..lineTo(center.dx + 9, top - 10)
      ..close();
    canvas.drawPath(path, Paint()..color = aligned ? accent : text);
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.heading != heading ||
      old.qibla != qibla ||
      old.aligned != aligned ||
      old.ring != ring ||
      old.face != face ||
      old.accent != accent ||
      old.text != text ||
      old.direction != direction ||
      old.letters != letters;
}
