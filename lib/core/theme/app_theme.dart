import 'package:flutter/material.dart';
import 'package:mre_fields/mre_fields.dart';

import 'app_tokens.dart';

/// Application themes, including a low-glare reader option.
abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    seed: const Color(0xFF176653),
    canvas: const Color(0xFFF8F7F1),
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    seed: const Color(0xFF79CDB4),
    canvas: const Color(0xFF111513),
  );

  static ThemeData get sepia => _build(
    brightness: Brightness.light,
    seed: const Color(0xFF765A37),
    canvas: const Color(0xFFF4EBD8),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color seed,
    required Color canvas,
  }) {
    final scheme = _harmonize(
      ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
      canvas,
    );
    WidgetStateProperty<Color?> byState({
      required Color selected,
      required Color unselected,
      Color? disabled,
    }) => WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? disabled ?? scheme.onSurface.withValues(alpha: 0.12)
          : states.contains(WidgetState.selected)
          ? selected
          : unselected,
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
        selectedTileColor: scheme.secondaryContainer,
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
      switchTheme: SwitchThemeData(
        thumbColor: byState(
          selected: scheme.onPrimary,
          unselected: scheme.outline,
        ),
        trackColor: byState(
          selected: scheme.primary,
          unselected: scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: byState(
          selected: Colors.transparent,
          unselected: scheme.outline,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: byState(
          selected: scheme.primary,
          unselected: Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 2),
      ),
      radioTheme: RadioThemeData(
        fillColor: byState(
          selected: scheme.primary,
          unselected: scheme.outline,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.secondaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: fieldRadius),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.secondaryContainer,
          selectedForegroundColor: scheme.onSecondaryContainer,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSheet),
        ),
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

  /// Rebuilds the surface roles around [canvas] so cards, fields, and the page
  /// share one hue instead of the seed's default tonal surfaces.
  static ColorScheme _harmonize(ColorScheme base, Color canvas) {
    final dark = base.brightness == Brightness.dark;
    Color tint(double alpha) =>
        Color.alphaBlend(base.primary.withValues(alpha: alpha), canvas);
    return base.copyWith(
      surface: canvas,
      surfaceContainerLowest: dark
          ? Color.alphaBlend(Colors.black.withValues(alpha: 0.25), canvas)
          : Color.alphaBlend(Colors.white.withValues(alpha: 0.6), canvas),
      surfaceContainerLow: tint(0.04),
      surfaceContainer: tint(0.07),
      surfaceContainerHigh: tint(0.10),
      surfaceContainerHighest: tint(0.14),
      secondaryContainer: tint(0.20),
      onSecondaryContainer: base.onSurface,
    );
  }
}
