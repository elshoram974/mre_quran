import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_tokens.dart';
import '../domain/qibla.dart';

/// The compass card: the four directions and a tick every 5°, turning so that
/// north on the card is north in the world, and a Kaaba marker on the rim at
/// the Qibla.
///
/// When [heading] is null (no compass sensor) the card is fixed with north at
/// the top, and the marker still shows the Qibla's angle from north. While
/// [qibla] is null too (the place is still loading) the card has no marker.
///
/// The card arrives once, growing into place with a soft overshoot. After
/// that nothing snaps: the marker fades in when the Qibla becomes known, and
/// the card swings from north-up to the first heading. With
/// `MediaQuery.disableAnimations` it all simply appears.
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

  /// Direction of the Qibla, degrees clockwise from north, or null while the
  /// place is not known yet.
  final double? qibla;

  /// Where the top of the phone points, or null without a sensor.
  final double? heading;

  /// Whether the phone faces the Qibla.
  final bool aligned;

  /// North, east, south and west letters, in that order.
  final List<String> letters;

  /// Announced by screen readers in place of the drawing, or null to keep
  /// the drawing from them while it has nothing to say.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final qibla = this.qibla;
    final heading = this.heading;
    return Semantics(
      label: semanticLabel,
      image: semanticLabel == null ? null : true,
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: 1,
          child: _Entrance(
            child: TweenAnimationBuilder<_Pose>(
              tween: _PoseTween(
                end: (
                  aligned: aligned ? 1 : 0,
                  marker: qibla == null ? 0 : 1,
                  live: heading == null ? 0 : 1,
                ),
              ),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : AppTokens.motionMedium,
              builder: (context, pose, _) => CustomPaint(
                painter: _CompassPainter(
                  qibla: qibla,
                  // The short way round from north-up to where the phone
                  // points, so the first reading turns the card into place.
                  heading: heading == null
                      ? 0
                      : angleBetween(0, heading) * pose.live,
                  aligned: pose.aligned,
                  marker: pose.marker,
                  outline: scheme.outlineVariant,
                  face: scheme.surfaceContainerHigh,
                  tick: scheme.onSurfaceVariant,
                  accent: scheme.primary,
                  onAccent: scheme.onPrimary,
                  north: scheme.error,
                  text: scheme.onSurface,
                  textStyle: theme.textTheme.titleMedium!,
                  letters: letters,
                  direction: Directionality.of(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Brings the dial in once, when it is first built: it grows into place with
/// a soft overshoot. Rebuilds and sensor readings never play it again.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const from = AppTokens.entranceScale;
    return TweenAnimationBuilder<double>(
      // Only the first tween's beginning is used, so this runs once.
      tween: Tween(
        begin: MediaQuery.disableAnimationsOf(context) ? 1 : from,
        end: 1,
      ),
      duration: AppTokens.motionEntrance,
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, scale, child) => Opacity(
        // Full by the time it first reaches its size; the overshoot follows.
        opacity: ((scale - from) / (1 - from)).clamp(0.0, 1.0),
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }
}

/// How far the dial is into each of its states, from 0 to 1, so a change of
/// state is eased rather than drawn at once: facing the Qibla, showing the
/// marker, and following the live heading.
typedef _Pose = ({double aligned, double marker, double live});

class _PoseTween extends Tween<_Pose> {
  _PoseTween({required super.end});

  @override
  _Pose lerp(double t) {
    final from = begin!;
    final to = end!;
    return (
      aligned: lerpDouble(from.aligned, to.aligned, t)!,
      marker: lerpDouble(from.marker, to.marker, t)!,
      live: lerpDouble(from.live, to.live, t)!,
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.qibla,
    required this.heading,
    required this.aligned,
    required this.marker,
    required this.outline,
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

  final double? qibla;
  final double heading;

  /// How far into facing the Qibla, 0 to 1.
  final double aligned;

  /// How much of the Kaaba marker shows, 0 to 1.
  final double marker;
  final Color outline;
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
          ..strokeWidth = 2 + 3 * aligned
          ..color = Color.lerp(outline, accent, aligned)!,
      );

    // The card: everything on it turns against the phone.
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(-_rad(heading));
    _ticks(canvas, radius);
    _letters(canvas, radius);
    final qibla = this.qibla;
    if (qibla != null && marker > 0) _marker(canvas, radius, qibla);
    canvas
      ..drawCircle(Offset.zero, 6, Paint()..color = accent)
      ..restore();

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

  void _marker(Canvas canvas, double radius, double qibla) {
    // Fading in, the marker is drawn whole and then thinned as one, so its
    // overlapping parts do not show through each other. Only the alpha of
    // the layer's paint counts.
    final fading = marker < 1;
    if (fading) {
      canvas.saveLayer(null, Paint()..color = accent.withValues(alpha: marker));
    }
    final angle = _rad(qibla);
    final dx = math.sin(angle);
    final dy = -math.cos(angle);
    final spot = Offset(dx * (radius - 62), dy * (radius - 62));
    final tip = Offset(dx * (radius - 84), dy * (radius - 84));
    final shaft = Paint()
      ..color = accent.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, tip, shaft);
    // The arrowhead makes the physical direction to the Kaaba unmistakable.
    final wing = 9.0;
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - dx * wing - dy * wing, tip.dy - dy * wing + dx * wing)
      ..lineTo(tip.dx - dx * wing + dy * wing, tip.dy - dy * wing - dx * wing)
      ..close();
    canvas.drawPath(arrow, Paint()..color = accent);
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
    if (fading) canvas.restore();
  }

  /// The fixed mark at the top of the dial showing where the phone points.
  void _lubberLine(Canvas canvas, Offset center, double radius) {
    final top = center.dy - radius;
    final path = Path()
      ..moveTo(center.dx, top + 2)
      ..lineTo(center.dx - 9, top - 10)
      ..lineTo(center.dx + 9, top - 10)
      ..close();
    canvas.drawPath(path, Paint()..color = Color.lerp(text, accent, aligned)!);
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.heading != heading ||
      old.qibla != qibla ||
      old.aligned != aligned ||
      old.marker != marker ||
      old.outline != outline ||
      old.face != face ||
      old.accent != accent ||
      old.text != text ||
      old.direction != direction ||
      old.letters != letters;
}
