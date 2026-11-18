// Draws the maker's name, MRECode, under the launch screen's star: Android
// 12 and later show it as the launch screen's branding image (200 by 80
// dp), in the star's gold on the sepia paper. iOS writes the same name in
// LaunchScreen.storyboard and StartupSplash.
//
// Writes res/drawable-*dpi/splash_brand.png. The letters are Roboto Bold
// from the Flutter SDK (Apache License 2.0).
//
// Run: flutter test tool/app_icon/render_splash_brand_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The star's gold on the launch screen (splash_star.xml).
const Color _gold = Color(0xFF8A6416);

const String _res = 'android/app/src/main/res';

void main() {
  testWidgets('renders the launch screen brand', (tester) async {
    await tester.runAsync(() async {
      final font = File(
        '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/'
        'material_fonts/Roboto-Bold.ttf',
      ).readAsBytesSync();
      await (FontLoader(
        'BrandRoboto',
      )..addFont(Future.value(ByteData.sublistView(font)))).load();
      const densities = {
        'mdpi': 1.0,
        'hdpi': 1.5,
        'xhdpi': 2.0,
        'xxhdpi': 3.0,
        'xxxhdpi': 4.0,
      };
      for (final MapEntry(key: name, value: scale) in densities.entries) {
        final width = (200 * scale).round();
        final height = (80 * scale).round();
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final painter = TextPainter(
          text: TextSpan(
            text: 'MRECode',
            style: TextStyle(
              fontFamily: 'BrandRoboto',
              fontSize: 18 * scale,
              letterSpacing: 2.4 * scale,
              color: _gold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(
          canvas,
          Offset((width - painter.width) / 2, (height - painter.height) / 2),
        );
        final image = await recorder.endRecording().toImage(width, height);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$_res/drawable-$name/splash_brand.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
      }
    });
  });
}
