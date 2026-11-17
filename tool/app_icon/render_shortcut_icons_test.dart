// Draws the icons of the shortcuts a long press on the app's icon offers
// (AppShortcut): the same Material icons as the app's own tabs and pages,
// in the app icon's colours.
//
// Writes:
//   Android  res/drawable-*dpi/ic_shortcut_<name>.png: a gold disc, 44 of
//            48 dp, with the icon in navy, as launchers show shortcuts;
//   iOS      Assets.xcassets/ic_shortcut_<name>.imageset: the icon alone,
//            35 points, as a template image the system tints.
//
// The icons come from the Material Icons font in the Flutter SDK (Apache
// License 2.0), so they need no artwork of their own.
//
// Run: flutter test tool/app_icon/render_shortcut_icons_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/app/app_shortcuts.dart';

const Color _navy = Color(0xFF161B26);
const Color _gold = Color(0xFFE3C27A);

const String _res = 'android/app/src/main/res';
const String _ios = 'ios/Runner/Assets.xcassets';

const Map<AppShortcut, IconData> _icons = {
  AppShortcut.prayerTimes: Icons.mosque_outlined,
  AppShortcut.qibla: Icons.explore_outlined,
  AppShortcut.adhkar: Icons.volunteer_activism_outlined,
  AppShortcut.reader: Icons.auto_stories_outlined,
};

void main() {
  testWidgets('renders the shortcut icons', (tester) async {
    await tester.runAsync(() async {
      final font = File(
        '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/'
        'material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytesSync();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(font)))).load();

      const densities = {
        'mdpi': 1.0,
        'hdpi': 1.5,
        'xhdpi': 2.0,
        'xxhdpi': 3.0,
        'xxxhdpi': 4.0,
      };
      for (final MapEntry(key: shortcut, value: icon) in _icons.entries) {
        for (final MapEntry(key: name, value: scale) in densities.entries) {
          await _write(
            '$_res/drawable-$name/${shortcut.icon}.png',
            48 * scale,
            (canvas, side) {
              canvas.drawCircle(
                Offset(side / 2, side / 2),
                side * 22 / 48,
                Paint()..color = _gold,
              );
              _glyph(canvas, side, icon, side / 2, _navy);
            },
          );
        }
        final set = '$_ios/${shortcut.icon}.imageset';
        final images = <Map<String, String>>[];
        for (final scale in [1, 2, 3]) {
          final file = '${shortcut.icon}@${scale}x.png';
          await _write(
            '$set/$file',
            35.0 * scale,
            (canvas, side) => _glyph(canvas, side, icon, side, Colors.black),
          );
          images.add({
            'idiom': 'universal',
            'filename': file,
            'scale': '${scale}x',
          });
        }
        File('$set/Contents.json').writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert({
            'images': images,
            'info': {'author': 'xcode', 'version': 1},
            'properties': {'template-rendering-intent': 'template'},
          })}\n',
        );
      }
    });
  });
}

/// Draws [icon] [size] wide, centred, in [color].
void _glyph(
  Canvas canvas,
  double side,
  IconData icon,
  double size,
  Color color,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: 'MaterialIcons',
        fontSize: size,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    Offset((side - painter.width) / 2, (side - painter.height) / 2),
  );
}

Future<void> _write(
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
