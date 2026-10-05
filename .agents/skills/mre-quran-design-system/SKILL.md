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
- Pickers: `AppSelectField` (search appears above 5 options). Sheets: `AppSheet` (draggable). Switches: `AppSwitchTile`.
- Plan and screen list: `docs/UI_UX_PLAN.md`.
- Cards: `AppCard` (glass). Do not nest a `Card` or glass control inside it.

## Native per platform

- Decide with `context.isCupertino` (reads `Theme.of(context).platform`). Never use `defaultTargetPlatform` directly.
- iOS/macOS: liquid glass chrome (`GlassScaffold`, `GlassAppBar`, `GlassTabBar`, `GlassModalSheet`, `GlassCard`). Never over Quran text. Keep text on a tinted surface and check contrast in light, dark, and sepia.
- Android: stock Material 3 (`Scaffold`, `AppBar`, `NavigationBar`, `Card`, `showModalBottomSheet`). No glass.
- Keep branching inside shared widgets: `AppShell` (`lib/app/shell/`), `AppCard`, `AppSelectField`.
- Glass screens pad content with `pagePadding(context)`; the glass shell publishes bar insets through `MediaQuery.padding`.
- Preview both platforms with Device Preview 3 (debug only, DevTools panel): choose an iPhone preset for iOS chrome and a Pixel or Galaxy preset for Android.

## Responsive

- Branch with `WindowSize.fromWidth` on `LayoutBuilder` or `MediaQuery.sizeOf`. Compact uses a bottom tab bar, medium and expanded use a rail (glass on iOS, Material on Android).
- Gutter: `AppTokens.gutterCompact` / `gutterWide`. Content max width via `ContentContainer`.

## Checklist before finishing

1. No hard-coded colours, radii, or paddings that duplicate a token.
2. Reuse a widget from `lib/core/widgets`; extract a new one when a pattern repeats.
3. Check compact, medium, expanded, dark, sepia, large text, Arabic RTL, and English LTR.
4. Loading uses the shared shimmer, never a full-screen spinner over content.
5. Delete throwaway files and screenshots.
