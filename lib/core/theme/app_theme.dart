import 'package:flutter/material.dart';
import 'package:mre_fields/mre_fields.dart';

/// Application themes, including a low-glare reader option.
abstract final class AppTheme {
  static ThemeData light = _build(
    brightness: Brightness.light,
    seed: const Color(0xFF176653),
    canvas: const Color(0xFFF8F7F1),
  );

  static ThemeData dark = _build(
    brightness: Brightness.dark,
    seed: const Color(0xFF79CDB4),
    canvas: const Color(0xFF111513),
  );

  static ThemeData sepia = _build(
    brightness: Brightness.light,
    seed: const Color(0xFF765A37),
    canvas: const Color(0xFFF4EBD8),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color seed,
    required Color canvas,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
      ),
      extensions: const [
        MREFieldsTheme(
          fieldBorderRadius: 18,
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ],
    );
  }
}
