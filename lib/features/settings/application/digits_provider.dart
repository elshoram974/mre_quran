import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_provider.dart';

const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';

/// Formats whole numbers for display, honouring the Arabic digits setting.
///
/// Only the digit glyphs change; the Quran text is never touched.
final digitsFormatterProvider = Provider<String Function(int)>((ref) {
  final format = ref.watch(displayDigitsFormatterProvider);
  return (value) => format('$value');
});

/// Formats every ASCII digit in visible text according to the saved setting.
final displayDigitsFormatterProvider = Provider<String Function(String)>((ref) {
  final arabic = ref.watch(
    settingsProvider.select(
      (settings) => settings.value?.useArabicDigits ?? true,
    ),
  );
  return (value) => formatDisplayDigits(value, arabic: arabic);
});

/// Writes [value] with Arabic-Indic digits when [arabic] is true.
String formatDigits(int value, {required bool arabic}) {
  return formatDisplayDigits('$value', arabic: arabic);
}

/// Replaces every Western digit in [value] with its Arabic-Indic equivalent.
String formatDisplayDigits(String value, {required bool arabic}) {
  if (!arabic) return value;
  return value.replaceAllMapped(RegExp('[0-9]'), (match) {
    return _arabicIndic[match.group(0)!.codeUnitAt(0) - 0x30];
  });
}
