// Draws the app icon, Mushafi's own design: an open Mushaf in cream inside a
// gold eight-pointed star, on deep navy. It is the star of the launch screen
// with the book the app is for.
//
// Writes every size the platforms ask for, from this one drawing:
//   Android  res/mipmap-*/ic_launcher.png (rounded square, before Android 8),
//            res/mipmap-*/ic_launcher_foreground.png and
//            ic_launcher_monochrome.png (adaptive and themed icons; the
//            background is @color/ic_launcher_background),
//   iOS      Assets.xcassets/AppIcon.appiconset (full square, no alpha),
//   stores   docs/store/icon-512.png,
// and the star of iOS's launch screen (LaunchImage.imageset, 96 points), as
// StartupSplash draws it still, so the hand-over to it is seamless. Android's
// launch star is a vector: res/drawable/splash_star.xml.
//
// Run: flutter test tool/app_icon/render_app_icon_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const Color _navy = Color(0xFF161B26);
const Color _navyDeep = Color(0xFF0E121A);
const Color _gold = Color(0xFFE3C27A);
const Color _cream = Color(0xFFF4EBD8);

const String _res = 'android/app/src/main/res';
const String _ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

/// What is drawn: the whole icon, the adaptive foreground, or its one-colour
/// (themed) form.
enum _Layer { full, foreground, monochrome }

void main() {
  testWidgets('renders the app icon', (tester) async {
    await tester.runAsync(() async {
      const densities = {
        'mdpi': 1.0,
        'hdpi': 1.5,
        'xhdpi': 2.0,
        'xxhdpi': 3.0,
        'xxxhdpi': 4.0,
      };
      for (final MapEntry(key: name, value: scale) in densities.entries) {
        await _write(
          '$_res/mipmap-$name/ic_launcher.png',
          48 * scale,
          _Layer.full,
          round: true,
        );
        await _write(
          '$_res/mipmap-$name/ic_launcher_foreground.png',
          108 * scale,
          _Layer.foreground,
        );
        await _write(
          '$_res/mipmap-$name/ic_launcher_monochrome.png',
          108 * scale,
          _Layer.monochrome,
        );
      }
      const ios = {
        'Icon-App-20x20@1x.png': 20.0,
        'Icon-App-20x20@2x.png': 40.0,
        'Icon-App-20x20@3x.png': 60.0,
        'Icon-App-29x29@1x.png': 29.0,
        'Icon-App-29x29@2x.png': 58.0,
        'Icon-App-29x29@3x.png': 87.0,
        'Icon-App-40x40@1x.png': 40.0,
        'Icon-App-40x40@2x.png': 80.0,
        'Icon-App-40x40@3x.png': 120.0,
        'Icon-App-60x60@2x.png': 120.0,
        'Icon-App-60x60@3x.png': 180.0,
        'Icon-App-76x76@1x.png': 76.0,
        'Icon-App-76x76@2x.png': 152.0,
        'Icon-App-83.5x83.5@2x.png': 167.0,
        'Icon-App-1024x1024@1x.png': 1024.0,
      };
      for (final MapEntry(key: file, value: size) in ios.entries) {
        await _write('$_ios/$file', size, _Layer.full);
      }
      await _write('docs/store/icon-512.png', 512, _Layer.full);
      const launch = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
      for (final (file, scale) in [
        ('LaunchImage.png', 1),
        ('LaunchImage@2x.png', 2),
        ('LaunchImage@3x.png', 3),
      ]) {
        await _writeWith('$launch/$file', 96.0 * scale, _launchStar);
      }
    });
  });
}

Future<void> _write(
  String path,
  double size,
  _Layer layer, {
  bool round = false,
}) => _writeWith(
  path,
  size,
  (canvas, side) => _paint(canvas, side, layer, round: round),
);

Future<void> _writeWith(
  String path,
  double size,
  void Function(Canvas canvas, double side) draw,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final side = size.roundToDouble();
  draw(canvas, side);
  final image = await recorder.endRecording().toImage(
    side.toInt(),
    side.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void _paint(Canvas canvas, double s, _Layer layer, {bool round = false}) {
  final centre = Offset(s / 2, s / 2);
  final mono = layer == _Layer.monochrome;
  final gold = mono ? Colors.white : _gold;
  final cream = mono ? Colors.white : _cream;

  if (layer == _Layer.full) {
    final rect = Offset.zero & Size.square(s);
    final shape = round
        ? RRect.fromRectAndRadius(
            rect.deflate(s * 0.04),
            Radius.circular(s * 0.22),
          )
        : RRect.fromRectAndRadius(rect, Radius.zero);
    canvas.drawRRect(
      shape,
      Paint()..shader = ui.Gradient.radial(centre, s * 0.7, [_navy, _navyDeep]),
    );
  }

  // The adaptive foreground keeps its drawing in the middle 66 of 108, the
  // part every launcher shape shows.
  final scale = layer == _Layer.full ? 1.0 : 66 / 108 * 1.12;
  final radius = s * 0.37 * scale;

  // The star: two squares, outlined, lightly filled.
  final star = Path();
  for (final start in [0.0, math.pi / 4]) {
    final square = Path();
    for (var i = 0; i < 4; i++) {
      final a = start + i * math.pi / 2 - math.pi / 2;
      final p = centre + Offset(math.cos(a), math.sin(a)) * radius;
      i == 0 ? square.moveTo(p.dx, p.dy) : square.lineTo(p.dx, p.dy);
    }
    star.addPath(square..close(), Offset.zero);
  }
  if (!mono) {
    canvas.drawPath(star, Paint()..color = _gold.withValues(alpha: 0.12));
  }
  canvas.drawPath(
    star,
    Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.075
      ..strokeJoin = StrokeJoin.round,
  );

  // The open Mushaf: two pages rising from the spine, their top and bottom
  // edges bowed like a book's, on a darker leaf that gives them thickness.
  final half = radius * 0.54;
  final top = centre.dy - radius * 0.28;
  final bottom = centre.dy + radius * 0.26;
  final bow = radius * 0.07;
  Path pageOf(double side, double drop) => Path()
    ..moveTo(centre.dx, top + bow + drop)
    ..quadraticBezierTo(
      centre.dx + side * half * 0.45,
      top - bow + drop,
      centre.dx + side * half,
      top + drop,
    )
    ..lineTo(centre.dx + side * half, bottom + drop)
    ..quadraticBezierTo(
      centre.dx + side * half * 0.45,
      bottom - bow + drop,
      centre.dx,
      bottom + bow + drop,
    )
    ..close();
  for (final side in [-1.0, 1.0]) {
    if (!mono) {
      canvas.drawPath(
        pageOf(side, radius * 0.05),
        Paint()..color = const Color(0xFFC9B48A),
      );
    }
    canvas.drawPath(pageOf(side, 0), Paint()..color = cream);
    // Lines of text on the page.
    if (!mono) {
      final ink = Paint()
        ..color = _navy.withValues(alpha: 0.5)
        ..strokeWidth = radius * 0.028
        ..strokeCap = StrokeCap.round;
      for (var line = 1; line <= 4; line++) {
        final y = top + bow * 0.6 + (bottom - top) * line / 5.2;
        canvas.drawLine(
          Offset(centre.dx + side * half * 0.2, y),
          Offset(centre.dx + side * half * 0.82, y - bow * 0.35),
          ink,
        );
      }
    }
  }
  // The spine.
  canvas.drawLine(
    Offset(centre.dx, top + bow),
    Offset(centre.dx, bottom + bow),
    Paint()
      ..color = mono ? Colors.transparent : _gold
      ..strokeWidth = radius * 0.04,
  );
}

/// The launch star in the gold accent, as StartupSplash draws it at rest:
/// two squares of radius 0.43 of the side, lightly filled, and a disc.
void _launchStar(Canvas canvas, double s) {
  const gold = Color(0xFF8A6416);
  final centre = Offset(s / 2, s / 2);
  final radius = s / 2 * 0.86;
  final star = Path();
  for (final start in [0.0, math.pi / 4]) {
    final square = Path();
    for (var i = 0; i < 4; i++) {
      final a = start + i * math.pi / 2 - math.pi / 2;
      final p = centre + Offset(math.cos(a), math.sin(a)) * radius;
      i == 0 ? square.moveTo(p.dx, p.dy) : square.lineTo(p.dx, p.dy);
    }
    star.addPath(square..close(), Offset.zero);
  }
  canvas
    ..drawPath(star, Paint()..color = gold.withValues(alpha: 0.14))
    ..drawPath(
      star,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035
        ..strokeJoin = StrokeJoin.round,
    )
    ..drawCircle(centre, radius * 0.16, Paint()..color = gold);
}
