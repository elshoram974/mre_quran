// Draws the maker's mark under the launch screen's star: "made by" in a
// light italic over "MRECode" in inscription capitals, in the star's gold
// on the sepia paper, 200 by 80 (dp or points).
//
// Writes the same picture for every place a launch screen shows it:
//   Android  res/drawable-*dpi/splash_brand.png: the branding image of
//            Android 12 and later (values-v31/styles.xml), and the bottom
//            layer of the launch window before 12 (drawable/launch_compat.xml);
//   iOS      Assets.xcassets/LaunchBrand.imageset (LaunchScreen.storyboard).
// The launch screen is native only; Flutter draws no splash of its own.
//
// The letters: Marcellus (Brian J. Bonislawsky, Astigmatic) and Cormorant
// Garamond Italic (the Cormorant Project), both SIL Open Font License 1.1,
// kept with their licences in app_assets/brand/fonts. Only these pictures
// ship, never the fonts.
//
// Run: flutter test tool/app_icon/render_splash_brand_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The star's gold on the launch screen (splash_star.xml).
const Color _gold = Color(0xFF8A6416);

const String _fonts = 'app_assets/brand/fonts';
const String _res = 'android/app/src/main/res';
const String _ios = 'ios/Runner/Assets.xcassets/LaunchBrand.imageset';

/// The picture's size in dp or points, as Android 12 wants its branding
/// image.
const Size _size = Size(200, 80);

Future<void> _load(String family, String file) async {
  final bytes = File('$_fonts/$file').readAsBytesSync();
  await (FontLoader(
    family,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

Future<List<int>> _draw(double scale) async {
  final width = (_size.width * scale).round();
  final height = (_size.height * scale).round();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  TextPainter line(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final madeBy = line(
    'made by',
    TextStyle(
      fontFamily: 'BrandCormorant',
      fontVariations: const [FontVariation('wght', 500)],
      fontSize: 17 * scale,
      height: 1,
      letterSpacing: 0.4 * scale,
      color: _gold.withValues(alpha: 0.85),
    ),
  );
  final name = line(
    'MRECode',
    TextStyle(
      fontFamily: 'BrandMarcellus',
      fontSize: 34 * scale,
      height: 1,
      letterSpacing: 1.2 * scale,
      color: _gold,
    ),
  );
  final gap = 5 * scale;
  var y = (height - madeBy.height - gap - name.height) / 2;
  madeBy.paint(canvas, Offset((width - madeBy.width) / 2, y));
  y += madeBy.height + gap;
  name.paint(canvas, Offset((width - name.width) / 2, y));
  final image = await recorder.endRecording().toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void _write(String path, List<int> bytes) => File(path)
  ..createSync(recursive: true)
  ..writeAsBytesSync(bytes);

void main() {
  testWidgets('renders the launch screen brand', (tester) async {
    await tester.runAsync(() async {
      await _load('BrandMarcellus', 'Marcellus-Regular.ttf');
      await _load('BrandCormorant', 'CormorantGaramond-Italic[wght].ttf');
      const android = {
        'mdpi': 1.0,
        'hdpi': 1.5,
        'xhdpi': 2.0,
        'xxhdpi': 3.0,
        'xxxhdpi': 4.0,
      };
      for (final MapEntry(key: name, value: scale) in android.entries) {
        _write('$_res/drawable-$name/splash_brand.png', await _draw(scale));
      }
      final images = <Map<String, String>>[];
      for (final scale in [1, 2, 3]) {
        final file = 'splash_brand@${scale}x.png';
        _write('$_ios/$file', await _draw(scale.toDouble()));
        images.add({
          'filename': file,
          'idiom': 'universal',
          'scale': '${scale}x',
        });
      }
      File('$_ios/Contents.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({
          'images': images,
          'info': {'author': 'xcode', 'version': 1},
        })}\n',
      );
    });
  });
}
