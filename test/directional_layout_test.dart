import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('application layouts avoid physical horizontal APIs', () {
    final sourceFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.contains('/l10n/generated/'));
    final forbidden = [
      RegExp(r'EdgeInsets\.fromLTRB\('),
      RegExp(r'EdgeInsets\.only\([^)]*\b(left|right)\s*:'),
      RegExp(r'Positioned\([^)]*\b(left|right)\s*:'),
      RegExp(r'Alignment\.[A-Za-z]*(Left|Right)'),
      RegExp(r'TextAlign\.(left|right)'),
      RegExp(
        r'BorderRadius\.only\([^)]*\b(topLeft|topRight|bottomLeft|bottomRight)\s*:',
      ),
    ];

    for (final file in sourceFiles) {
      final source = file.readAsStringSync();
      for (final pattern in forbidden) {
        expect(
          pattern.hasMatch(source),
          isFalse,
          reason: '${file.path} contains ${pattern.pattern}',
        );
      }
    }
  });
}
