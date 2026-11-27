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
/// With a [tilt] the hub becomes a small spirit level: a ring, and a bubble
/// that leaves it toward the raised side of the phone. Level, the two sit
/// together in the accent colour.
///
/// The card arrives once, growing into place with a soft overshoot. After
/// that nothing snaps: the marker fades in when the Qibla becomes known, and
/// the card swings from north-up to the first heading. With
/// `MediaQuery.disableAnimations` it all simply appears.
///
/// A compass turns the same way in every language, and a bubble floats to
/// the same side, so this is drawn with physical angles and offsets on
/// purpose; nothing here follows the text direction.
class QiblaCompass extends StatelessWidget {
  /// Creates the compass.
  const QiblaCompass({
    super.key,
    required this.qibla,
    required this.heading,
    required this.aligned,
    required this.letters,
    required this.semanticLabel,
    this.tilt,
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

  /// How the phone is held, or null where that is not known: the hub is then
  /// a plain dot.
  final PhoneTilt? tilt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final qibla = this.qibla;
    final heading = this.heading;
    final tilt = this.tilt;
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
                  level: tilt == null ? 0 : 1,
                  flat: tilt != null && tilt.level ? 1 : 0,
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
                  bubble: tilt == null ? null : Offset(tilt.dx, tilt.dy),
                  aligned: pose.aligned,
                  marker: pose.marker,
                  level: pose.level,
                  flat: pose.flat,
                  outline: scheme.outlineVariant,
                  face: scheme.surfaceContainerHigh,
                  well: scheme.surface,
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
/// marker, following the live heading, showing the level, and being level.
typedef _Pose = ({
  double aligned,
  double marker,
  double live,
  double level,
  double flat,
});

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
      level: lerpDouble(from.level, to.level, t)!,
      flat: lerpDouble(from.flat, to.flat, t)!,
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.qibla,
    required this.heading,
    required this.bubble,
    required this.aligned,
    required this.marker,
    required this.level,
    required this.flat,
    required this.outline,
    required this.face,
    required this.well,
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

  /// Where the level's bubble is pushed, as a share of full tilt: x toward
  /// the phone's right edge, y toward its bottom edge. Null without a level.
  final Offset? bubble;

  /// How far into facing the Qibla, 0 to 1.
  final double aligned;

  /// How much of the Kaaba marker shows, 0 to 1.
  final double marker;

  /// How much of the level shows in place of the plain hub, 0 to 1.
  final double level;

  /// How far into being level, 0 to 1.
  final double flat;
  final Color outline;
  final Color face;
  final Color well;
  final Color tick;
  final Color accent;
  final Color onAccent;
  final Color north;
  final Color text;
  final TextStyle textStyle;
  final List<String> letters;
  final TextDirection direction;

  /// Radius of the plain hub.
  static const double _hub = 6;

  /// Radius of the well the level's bubble moves in.
  static const double _well = 30;

  /// Radius of the ring the bubble rests in when the phone is level.
  static const double _ring = 14;

  /// Radius of the bubble.
  static const double _bubble = 7;

  /// The furthest the bubble's centre goes from the hub: it stays in the
  /// well however far the phone leans.
  static const double _travel = 20;

  /// How far the bubble moves for a full tilt: it reaches the ring from
  /// inside just as the phone stops being level.
  static final double _reach =
      (_ring - _bubble) / math.sin(_rad(levelTolerance));

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
    canvas.restore();

    // The hub: a plain dot, or the level where the phone can tell its tilt.
    if (level < 1) {
      canvas.drawCircle(
        center,
        _hub,
        Paint()..color = accent.withValues(alpha: 1 - level),
      );
    }
    _level(canvas, center);
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
    // The shaft starts at the hub, or at the edge of the level's well: the
    // level keeps the middle of the dial to itself.
    final start = _well * level;
    if (radius - 84 > start) {
      final shaft = Paint()
        ..color = accent.withValues(alpha: 0.5)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(dx * start, dy * start), tip, shaft);
    }
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

  /// The spirit level at the hub: a well, the ring a level bubble rests in,
  /// and the bubble, pushed toward the raised side of the phone.
  ///
  /// It is drawn in the phone's own frame, outside the turning card: the
  /// bubble shows how this phone leans whichever way it faces. Like the card
  /// it is physical on purpose: the phone's right edge is on the right in
  /// every language.
  void _level(Canvas canvas, Offset center) {
    final push = bubble;
    if (push == null || level <= 0) return;
    final fading = level < 1;
    if (fading) {
      canvas.saveLayer(null, Paint()..color = accent.withValues(alpha: level));
    }
    final mark = Color.lerp(tick, accent, flat)!;
    var offset = push * _reach;
    if (offset.distance > _travel) offset *= _travel / offset.distance;
    canvas
      ..drawCircle(center, _well, Paint()..color = well)
      ..drawCircle(
        center,
        _well,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = outline,
      )
      ..drawCircle(
        center,
        _ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = mark,
      )
      ..drawCircle(center + offset, _bubble, Paint()..color = mark);
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
      old.bubble != bubble ||
      old.aligned != aligned ||
      old.marker != marker ||
      old.level != level ||
      old.flat != flat ||
      old.outline != outline ||
      old.face != face ||
      old.well != well ||
      old.accent != accent ||
      old.text != text ||
      old.direction != direction ||
      old.letters != letters;
}
