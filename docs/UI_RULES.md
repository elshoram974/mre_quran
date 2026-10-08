# UI rules

The single rule file for UI/UX. `AGENTS.md` points here. The design plan is in
`docs/UI_UX_PLAN.md`. Follow every rule; if one blocks you, say so instead of skipping it.

## 1. Platform-native

1. Decide the platform with `context.isCupertino`, which reads `Theme.of(context).platform`. Never read `defaultTargetPlatform` directly.
2. iOS/macOS use liquid glass (`liquid_glass_widgets`) for chrome: app bar, tab bar, rail, sheets, and cards.
3. Android and other platforms use Material 3: `AppBar`, `NavigationRail`, `Card`, Material sheets. No glass. The compact tab bar is `ExpandingNavBar`: a floating rounded pill above the system navigation bar where the selected destination grows into a labelled chip and the others show only their icon (owner's decision, 2026-10-06; redesigned 2026-10-08).
4. Branch only inside shared widgets (`AppShell`, `AppCard`, `AppSheet`, `AppSelectField`, `AppSwitchTile`). Feature screens never check the platform.
5. Glass never goes over Quran text. The reading surface is opaque paper.
6. Judge glass on a real iOS simulator or device, not only in Device Preview. Preview scales the view and can distort glass sampling.
7. The Mushaf reader is labelled like a printed Mushaf (surah and juz chips above the page, page number and an onward arrow below, in fixed room that never covers the text). A tap on the page or an ayah shows a floating toolbar and floating controls, opaque on every platform since they lie over the text; turning a page hides them.

## 2. Components

1. Reusable widgets live in `lib/core/widgets`. Look there before writing one. Extend instead of copying. A pattern used twice becomes a shared widget.
2. Single choice: `AppSelectField` (search field above 5 options). Never `DropdownButton`, `DropdownButtonFormField`, or `DropdownMenu`.
3. Bottom sheets: `AppSheet` only. It is draggable (medium and large on iOS glass, snap-drag on Android) and always sits above the keyboard. Never `showModalBottomSheet`, `GlassModalSheet`, or a hand-built sheet in a screen. Yes/no questions use `AppConfirmSheet`; times use `AppTimePicker`.
4. Switches: `AppSwitchTile`. Cards: `AppCard`. Text inputs: `MRETextField` / `MRETextFormField` from `mre_fields`.
5. Do not restyle a field, button, or card per screen. Change the theme or the shared widget.

## 3. Colour, shape, spacing

1. Colours come only from `Theme.of(context).colorScheme`. Never hard-code a colour in feature code.
2. Radius, spacing, and sizes come from `AppTokens`. Add a token instead of repeating a number.
3. Filled Material 3 field style is set once in `AppTheme`. All three themes (light, dark, sepia) get every component theme.
4. Contrast meets WCAG AA in all themes. Touch targets are at least 48dp, with visible pressed and focus states.
5. Pad scrolling content with `pagePadding(context)`. The glass shell publishes bar insets through `MediaQuery.padding`.

## 4. Layout

1. Use window size classes: compact `<600`, medium `600–839`, expanded `>=840`. Branch on constraints, never device names.
2. Compact uses the bottom tab bar. Medium and expanded use the rail and a constrained content column.
3. Use directional APIs only (`EdgeInsetsDirectional`, `AlignmentDirectional`, `TextAlign.start`/`end`).

## 5. Loading and state

1. Never rebuild a whole page for a small change. Use `ref.watch(provider.select(...))`, small widgets, `const`, stable keys, and `RepaintBoundary` for heavy parts.
2. Keep scroll position, selection, and focus across state, theme, and locale changes.
3. Never show a full-screen spinner over existing content. On refresh keep data visible (`skipLoadingOnRefresh`).
4. First load of async content uses the shared shimmer in `lib/core/widgets`, matching the final layout. It respects `MediaQuery.disableAnimations` and works in light, dark, and RTL. Never use it to hide errors or empty states.
5. Every async screen has four states: loading, data, empty, error with retry. Strings come from ARB files.
6. Small user actions are optimistic: update state first, persist after, roll back on failure. A settings screen never enters a loading state on save.
7. Show no loader for work under about 150 ms.
8. Heavy parsing or search runs off the main isolate.

## 6. Motion and feedback

1. Short, purposeful animations (200–300 ms). Implicit first. Respect `MediaQuery.disableAnimations`.
2. Use the platform's own tab and sheet motion (glass pill physics on iOS, Material indicator on Android). Do not fake it.
3. Vibration goes through the static functions of `Haptics` (`select`, `tick`, `step`, `celebrate`) in `lib/core/haptics`; never `HapticFeedback` or a plugin directly. The Settings switch turns it off for every call.

## 7. Navigation

4. Back never closes the app by accident: sheets and pushed routes pop first; at the shell, another tab returns to the Mushaf, and back on the Mushaf asks before closing.

1. Routes are typed `go_router` routes. Tabs are listed once in `AppRoute.tabs`, in the same order as the shell branches.
2. The app opens on the last used tab or on the Mushaf, per the startup setting. The Mushaf tab reopens at the last page read.
3. Adding a tab means: route, branch, `AppRoute.tabs`, destination, ARB strings, and a test.

## 8. Before finishing UI work

1. Check compact, medium, expanded; dark and sepia; text scale 2.0; Arabic RTL and English LTR.
2. Check one iPhone preset and one Android preset in Device Preview (DevTools). `syncPreviewPlatform()` switches the app to the chosen device's chrome.
3. Add or update widget tests for the touched widgets.
4. Delete screenshots and any throwaway file you made.
