import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_provider.dart';

const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
final _asciiDigits = RegExp('[0-9]');
final _nonWesternDigits = RegExp('[٠-٩۰-۹]');

/// Formats whole numbers for display, honouring the Arabic digits setting.
///
/// Only the digit glyphs change; the Quran text is never touched.
final digitsFormatterProvider = Provider<String Function(int)>((ref) {
  final format = ref.watch(displayDigitsFormatterProvider);
  return (value) => format('$value');
});

/// Formats digit shapes in visible text according to the saved setting.
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

/// Formats digit shapes without changing the surrounding text.
String formatDisplayDigits(String value, {required bool arabic}) {
  if (!arabic) {
    return value.replaceAllMapped(_nonWesternDigits, (match) {
      final code = match.group(0)!.codeUnitAt(0);
      return String.fromCharCode(
        0x30 + code - (code >= 0x06f0 ? 0x06f0 : 0x0660),
      );
    });
  }
  return value.replaceAllMapped(_asciiDigits, (match) {
    return _arabicIndic[match.group(0)!.codeUnitAt(0) - 0x30];
  });
}
