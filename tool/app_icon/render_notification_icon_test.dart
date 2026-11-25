// Draws the small icon of the app's notifications on Android: the app's
// eight-pointed star (AppMark: two squares, one turned on the other), solid,
// with its middle dot cut out, white on transparent. Android draws a
// notification's small icon from its shape alone, so the launcher icon
// showed as a blank disc; this reads as the app's mark at 24 dp.
//
// Writes res/drawable-*dpi/ic_stat_mre.png (24 dp, the star within the 22 dp
// the system leaves clear).
//
// Run: flutter test tool/app_icon/render_notification_icon_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const String _res = 'android/app/src/main/res';

void main() {
  testWidgets('renders the notification icon', (tester) async {
    await tester.runAsync(() async {
      const densities = {
        'mdpi': 1.0,
        'hdpi': 1.5,
        'xhdpi': 2.0,
        'xxhdpi': 3.0,
        'xxxhdpi': 4.0,
      };
      for (final MapEntry(key: name, value: scale) in densities.entries) {
        await _write('$_res/drawable-$name/ic_stat_mre.png', 24 * scale);
      }
    });
  });
}

/// The star, [side] pixels across: the union of the two squares, less a dot.
Path _star(double side) {
  final centre = Offset(side / 2, side / 2);
  // The squares' corners reach 11 of the 12 dp from the middle.
  final reach = side * 11 / 24;
  Path square(double start) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final angle = start + i * math.pi / 2 - math.pi / 2;
      final point = centre + Offset(math.cos(angle), math.sin(angle)) * reach;
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  final star = Path.combine(
    PathOperation.union,
    square(0),
    square(math.pi / 4),
  );
  final dot = Path()
    ..addOval(Rect.fromCircle(center: centre, radius: side * 0.13));
  return Path.combine(PathOperation.difference, star, dot);
}

Future<void> _write(String path, double size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final side = size.roundToDouble();
  canvas.drawPath(
    _star(side),
    Paint()
      ..color = const Color(0xFFFFFFFF)
      ..isAntiAlias = true,
  );
  final image = await recorder.endRecording().toImage(
    side.toInt(),
    side.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}
