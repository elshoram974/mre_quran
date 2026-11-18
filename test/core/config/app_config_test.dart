import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/config/app_config.dart';

void main() {
  test('the version is the one in pubspec.yaml', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((line) => line.startsWith('version:'));
    expect(
      line.substring('version:'.length).trim(),
      '${AppConfig.version}+${AppConfig.build}',
    );
  });

  test('every address is https on the media host', () {
    expect(AppConfig.mediaBase, startsWith('https://'));
    expect(AppConfig.mediaBase, endsWith('/'));
    expect(AppConfig.privacyPolicy, startsWith(AppConfig.mediaBase));
  });

  test('contact links open WhatsApp and email', () {
    expect(AppConfig.whatsApp.toString(), 'https://wa.me/201553668845');
    expect(AppConfig.mail.scheme, 'mailto');
    expect(AppConfig.mail.path, AppConfig.email);
  });
}
