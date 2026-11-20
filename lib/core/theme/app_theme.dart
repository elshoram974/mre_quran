import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_fields/mre_fields.dart';

import 'app_palette.dart';
import 'app_surface_style.dart';
import 'quran_colors.dart';
import 'app_tokens.dart';

/// Application themes: one paper plus one accent, from [AppPalette].
abstract final class AppTheme {
  /// Cream paper, gold accent.
  static ThemeData get light => of(AppPaper.cream, AppAccent.gold);

  /// Navy paper, gold accent.
  static ThemeData get dark => of(AppPaper.navy, AppAccent.gold);

  /// Sepia paper, gold accent.
  static ThemeData get sepia => of(AppPaper.sepia, AppAccent.gold);

  static final Map<(AppPaper, AppAccent, TargetPlatform), ThemeData> _cache =
      {};

  /// The theme for [paper] with [accent]. Built once per pair, so switching
  /// back and forth hands `MaterialApp` the same object and animates only
  /// real changes.
  ///
  /// `ThemeData` records the platform it was built on, which decides glass
  /// or Material chrome, so the platform is part of the key: Device Preview
  /// and tests switch it at run time.
  static ThemeData of(AppPaper paper, AppAccent accent) => _cache.putIfAbsent((
    paper,
    accent,
    defaultTargetPlatform,
  ), () => _build(AppPalette.scheme(paper, accent)));

  static ThemeData _build(ColorScheme scheme) {
    final surfaces = AppSurfaceStyle.from(scheme);
    final text = _textTheme(scheme);
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
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: text.labelMedium?.copyWith(
          color: scheme.primary,
        ),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaces.raised,
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
      // What the app says in passing: a floating card in the accent's own
      // edge, its action in the accent, and (see AppSnackBar) the app's mark.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        disabledActionTextColor: scheme.onInverseSurface.withValues(alpha: 0.5),
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppTokens.gutterCompact),
        shape: RoundedRectangleBorder(
          borderRadius: fieldRadius,
          side: BorderSide(color: scheme.inversePrimary.withValues(alpha: 0.5)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
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
      // Dialogs, pickers and menus: the same raised paper, the same hairline
      // edge and the same corners as the cards and sheets, with the accent for
      // what is chosen.
      dialogTheme: DialogThemeData(
        backgroundColor: surfaces.raised,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        iconColor: scheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSheet),
          side: BorderSide(color: surfaces.hairline),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surfaces.raised,
        hourMinuteColor: scheme.primaryContainer,
        hourMinuteTextColor: scheme.onPrimaryContainer,
        dayPeriodColor: scheme.primaryContainer,
        dayPeriodTextColor: scheme.onPrimaryContainer,
        dialBackgroundColor: scheme.surfaceContainerHighest,
        dialHandColor: scheme.primary,
        entryModeIconColor: scheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSheet),
          side: BorderSide(color: surfaces.hairline),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaces.raised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: fieldRadius,
          side: BorderSide(color: surfaces.hairline),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: fieldRadius,
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
      extensions: [
        surfaces,
        QuranColors.from(scheme),
        const MREFieldsTheme(
          fieldBorderRadius: AppTokens.radiusField,
          contentPadding: AppTokens.fieldPadding,
          expandedContentPadding: AppTokens.fieldPadding,
        ),
      ],
    );
  }

  /// Material 2021 type with firmer headings, so titles read clearly against
  /// the soft card surfaces.
  static TextTheme _textTheme(ColorScheme scheme) {
    final base =
        (scheme.brightness == Brightness.dark
                ? Typography.material2021().white
                : Typography.material2021().black)
            .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    TextStyle? firm(TextStyle? style) =>
        style?.copyWith(fontWeight: FontWeight.w600);
    return base.copyWith(
      headlineLarge: firm(base.headlineLarge),
      headlineMedium: firm(base.headlineMedium),
      headlineSmall: firm(base.headlineSmall),
      titleLarge: firm(base.titleLarge),
      titleMedium: firm(base.titleMedium),
      titleSmall: firm(base.titleSmall),
    );
  }
}
