import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_provider.dart';

const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';

/// Formats whole numbers for display, honouring the Arabic digits setting.
///
/// Only the digit glyphs change; the Quran text is never touched.
final digitsFormatterProvider = Provider<String Function(int)>((ref) {
  final arabic = ref.watch(
    settingsProvider.select(
      (settings) => settings.value?.useArabicDigits ?? true,
    ),
  );
  return (value) => arabic ? formatDigits(value, arabic: true) : '$value';
});

/// Writes [value] with Arabic-Indic digits when [arabic] is true.
String formatDigits(int value, {required bool arabic}) {
  final text = '$value';
  if (!arabic) return text;
  return text.split('').map((c) {
    final digit = int.tryParse(c);
    return digit == null ? c : _arabicIndic[digit];
  }).join();
}
