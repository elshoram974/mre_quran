import 'package:flutter/material.dart';
import 'package:mre_fields/mre_fields.dart';

import 'app_tokens.dart';

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
    final fieldRadius = BorderRadius.circular(AppTokens.radiusField);
    UnderlineInputBorder border(Color color, [double width = 0]) =>
        UnderlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: width == 0
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        contentPadding: AppTokens.fieldPadding,
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        disabledBorder: border(Colors.transparent),
        focusedBorder: border(scheme.primary, 2),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 2),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppTokens.minTarget),
          shape: RoundedRectangleBorder(borderRadius: fieldRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppTokens.minTarget),
          shape: RoundedRectangleBorder(borderRadius: fieldRadius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: fieldRadius),
        selectedColor: scheme.primary,
        selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.45),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: fieldRadius),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusSheet),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
      ),
      extensions: const [
        MREFieldsTheme(
          fieldBorderRadius: AppTokens.radiusField,
          contentPadding: AppTokens.fieldPadding,
          expandedContentPadding: AppTokens.fieldPadding,
        ),
      ],
    );
  }
}
