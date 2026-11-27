# UI rules

The single rule file for UI/UX. `AGENTS.md` points here. The design plan is in
`docs/UI_UX_PLAN.md`. Follow every rule; if one blocks you, say so instead of skipping it.

## 1. Platform-native

1. Decide the platform with `context.isCupertino`, which reads `Theme.of(context).platform`. Never read `defaultTargetPlatform` directly.
2. iOS/macOS use liquid glass (`liquid_glass_widgets`) for chrome: app bar, tab bar, rail, sheets, and cards.
3. Android and other platforms use Material 3: `AppBar`, `NavigationRail`, `Card`, Material sheets. No glass. The compact tab bar is `ExpandingNavBar` on both platforms (liquid glass on iOS): a floating rounded pill above the system navigation bar where the selected destination grows into a chip with its label beside its icon and the others show only their icon (owner's decision, 2026-10-06; redesigned 2026-10-08; on iOS too since 2026-11-25, as the glass tab bar can only put a label under its icon). A wide window gets `ExpandingNavRail`, the same pill stood on end: the chosen destination names itself, under its icon (on iOS the glass segmented control stood upright, with its glass indicator), or beside it as a chip on a large screen (1200 wide and up); the others are icon-only. It floats: over the Mushaf it lies on the page and never moves it; on other pages the content keeps clear of it. The bar and the rail slide away with the reader's bars instead of popping (2026-11-25).
4. Branch only inside shared widgets (`AppShell`, `AppCard`, `AppSheet`, `AppSelectField`, `AppSwitchTile`). Feature screens never check the platform.
5. Glass never goes over Quran text. The reading surface is opaque paper.
6. Judge glass on a real iOS simulator or device, not only in a scaled preview, which can distort glass sampling.
7. The Mushaf reader is labelled like a printed Mushaf (surah, juz and hizb chips above the page, page number and an onward arrow below, in fixed room that never covers the text). The chips above the page share the row by need (`ReaderHeader`): on a short row the gaps and the pills' padding give way before any text is cut, and the surah's name before a juz or hizb number (`docs/DECISIONS.md` D-077). A tap on the page or an ayah shows a floating toolbar and floating controls, opaque on every platform since they lie over the text; turning a page hides them.

## 2. Components

1. Reusable widgets live in `lib/core/widgets`. Look there before writing one. Extend instead of copying. A pattern used twice becomes a shared widget.
2. Single choice: `AppSelectField` (search field above 5 options). Never `DropdownButton`, `DropdownButtonFormField`, or `DropdownMenu`.
   Choosing among a few places or modes (the index's lists, the reader mode): `AppSegmentedControl`. The chosen one sits
   on a filled accent pill with a bold label; the segments share the width when every label fits and scroll sideways
   otherwise; on iOS it is the glass segmented control, its order kept right to left. Chips (`ChoiceChip`,
   `FilterChip`) take the theme: a chosen chip is filled with the accent and ticked. What is chosen is never told by a
   pale tint alone (owner's request, 2026-11-25).
3. Bottom sheets: `AppSheet` only. A tall one is draggable and rests wherever it is let go, from a third of the screen to the full height under the status bar (no snapping; a flick up takes it to the top, a pull below a third or a quick flick down closes it), and it always sits above the keyboard and clear of the system navigation bar. Never `showModalBottomSheet`, `GlassModalSheet`, or a hand-built sheet in a screen. Yes/no questions use `AppConfirmSheet`; times use `AppTimePicker`.
4. Switches: `AppSwitchTile`. Cards: `AppCard` (pass `onTap`, never wrap it in your own `InkWell`); a card holding Quran text: `AppSurfaceCard`; the top highlight of a screen: `AppHeroCard`; a leading icon: `AppIconBadge`; a card that is one row: `AppTileCard`; a card of rows: `AppGroupCard`; headings between groups: `AppSectionHeader`; small labels: `AppTag`; a hint or error line: `AppNotice`. Text inputs: `MRETextField` / `MRETextFormField` from `mre_fields`.
5. Do not restyle a field, button, or card per screen. Change the theme or the shared widget.

## 3. Colour, shape, spacing

1. Colours come only from `Theme.of(context).colorScheme` and `AppSurfaceStyle.of(context)`. Raw colour literals live only in `lib/core/theme/app_palette.dart`.
2. Radius, spacing, and sizes come from `AppTokens`. Add a token instead of repeating a number.
3. Filled Material 3 field style is set once in `AppTheme`. All three themes (light, dark, sepia) get every component theme.
4. Contrast meets WCAG AA in all themes. Touch targets are at least 48dp, with visible pressed and focus states.
5. Pad scrolling content with `pagePadding(context)`. The glass shell publishes bar insets through `MediaQuery.padding`.

## 4. Layout

1. Use window size classes: compact `<600`, medium `600–839`, expanded `>=840`. Branch on constraints, never device names.
2. Compact and medium use the bottom tab bar; expanded uses the floating rail (`ExpandingNavRail`) and a constrained content column. Chrome that comes and goes over the Mushaf floats over it and never resizes the page.
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
9. **Drawn first, live when loaded.** Rule 4's shimmer is for content whose layout depends on the data: lists and cards whose number or size is not yet known. Where a page's layout does not wait on its data (the Qibla page: its dial, lines and hints are the same wherever the person is), do not shimmer. Draw the real page at once, every element in its place but inert: dimmed with `AppTokens.inertOpacity`, deaf to touches, and saying nothing that is not yet known, to the eye or to a screen reader. The bar says the page is loading through `AppPageScaffold(loading: true)`: a thin line on the bar's bottom edge on Android, a spinner at the bar's end on iOS, announced, moving nothing, and not shown for a wait under `AppTokens.loaderDelay` (rule 7). The page's centrepiece may arrive once with a soft bounce (`AppTokens.motionEntrance` from `AppTokens.entranceScale`, the one motion longer than section 6 allows), never again on a rebuild and not at all with `MediaQuery.disableAnimations`. When the data arrives the page comes alive where it stands, with no jump; empty and error states cross-fade in. Never tie the loader to something that may never come, such as a sensor's first reading.

## 6. Motion and feedback

1. Short, purposeful animations (200–300 ms). Implicit first. Respect `MediaQuery.disableAnimations`.
2. Use the platform's own sheet motion (glass on iOS, Material on Android). Do not fake it. The phone's tab bar is the exception the owner chose: the same expanding pill on both platforms, glass on iOS.
   A tappable card (`AppCard`, `AppSurfaceCard`, `AppTileCard`, the index rows) gives a little under the finger and springs back (`PressScale`, `AppTokens.pressScale`, 120 ms): it only listens, so the tap, ripple and scrolling are unchanged, and it stays still when animations are off. New tappable cards get it by being built from those widgets.
3. Vibration goes through the static functions of `Haptics` (`select`, `tick`, `step`, `celebrate`) in `lib/core/haptics`; never `HapticFeedback` or a plugin directly. The Settings switch turns it off for every call.

## 7. Navigation

4. Back never closes the app by accident: sheets and pushed routes pop first; at the shell, another tab returns to the Mushaf, and back on the Mushaf asks before closing.

1. Routes are typed `go_router` routes. Tabs are listed once in `AppRoute.tabs`, in the same order as the shell branches.
2. The app opens on the Mushaf unless the person chose the last used tab in the settings. The Mushaf tab reopens at the last page read.
3. Adding a tab means: route, branch, `AppRoute.tabs`, destination, ARB strings, and a test.

## 7b. The app's identity

1. Whatever the app says in passing or asks is the app's: a snack bar is `AppSnackBar` (never `SnackBar`), a question is `AppConfirmSheet` and a hint is `showAppHint`, both signed with `AppBrand` (the mark and the name). Dialogs, pickers and menus take the theme's paper, edge and corners (`AppTheme`), never a screen's own.
2. A notice the person must not miss is `AppNotice(important: true)`: red, boxed, with its action inside.
3. Anything shared ends with the app's name and its store links (`appShareFooter`), each from `AppConfig.stores`; a store with no address is left out, and with none there is no footer.
4. Text size is changed only where there is text to read (the adhkar and the typeset Mushaf), by a slider in the view settings or two fingers on the text, never by scaling the app.

## 8. Before finishing UI work

1. Check compact, medium, expanded; dark and sepia; text scale 2.0; Arabic RTL and English LTR.
2. Check one iOS simulator or device and one Android emulator or device.
3. Add or update widget tests for the touched widgets.
4. Delete screenshots and any throwaway file you made.
