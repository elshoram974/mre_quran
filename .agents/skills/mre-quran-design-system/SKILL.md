---
name: mre-quran-design-system
description: Build or change MRE Quran UI with the shared theme, tokens, glass chrome, fields, and pickers. Use for any screen, widget, form, sheet, or colour work.
---

# MRE Quran design system

## Sources of truth

- Colours: only `Theme.of(context).colorScheme` (Material 3 roles). Never hard-code a `Color(0x...)` in a feature. Seeds live in `lib/core/theme/app_theme.dart`.
- Radius, spacing, sizes: `AppTokens` in `lib/core/theme/app_tokens.dart`.
- Fields: Material 3 filled style (container `surfaceContainerHighest`, no outline at rest, `primary` 2 px indicator on focus), set once in `InputDecorationTheme`.
- Text inputs: `MRETextField` / `MRETextFormField` from `mre_fields`. `MREFieldsTheme` is wired to `AppTokens`, so do not pass per-field radius or padding.
- Pickers: `AppSelectField` (search appears above 5 options).
- Cards: `AppCard` (glass). Do not nest a `Card` or glass control inside it.

## Liquid glass

- Glass belongs to chrome: app bar, tab bar, rail, sheets, floating cards. Never over Quran text.
- Screens render inside `GlassScaffold` (see `lib/app/app_shell.dart`). It needs a `Material` ancestor, which the shell supplies.
- Pad scrolling content with `pagePadding(context)`; the shell publishes the bar insets through `MediaQuery.padding`.
- Sheets use `GlassModalSheet.show(useRootNavigator: true)` with a surface-tinted `LiquidGlassSettings` so text stays readable.
- Glass must stay readable: keep text on a tinted surface, check contrast in light, dark, and sepia.

## Responsive

- Branch with `WindowSize.fromWidth` on `LayoutBuilder` or `MediaQuery.sizeOf`. Compact uses the glass tab bar, medium and expanded use a glass rail.
- Gutter: `AppTokens.gutterCompact` / `gutterWide`. Content max width via `ContentContainer`.

## Checklist before finishing

1. No hard-coded colours, radii, or paddings that duplicate a token.
2. Reuse a widget from `lib/core/widgets`; extract a new one when a pattern repeats.
3. Check compact, medium, expanded, dark, sepia, large text, Arabic RTL, and English LTR.
4. Loading uses the shared shimmer, never a full-screen spinner over content.
5. Delete throwaway files and screenshots.
