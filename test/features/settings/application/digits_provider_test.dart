import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/settings/application/digits_provider.dart';

void main() {
  test('formats every visible digit, including time and decimal values', () {
    expect(
      formatDisplayDigits('12:05 · -30.50', arabic: true),
      '١٢:٠٥ · -٣٠.٥٠',
    );
    expect(
      formatDisplayDigits('12:05 · -30.50', arabic: false),
      '12:05 · -30.50',
    );
  });
}
