# MRE Quran UI/UX plan

One reference for shapes, colour, layout, motion, components, and screens. The
rules that enforce it live in `AGENTS.md` and the `mre-quran-design-system` skill.

## 1. Principles

1. **Native per platform.** iOS/macOS use liquid glass chrome and Cupertino
   behaviour. Android uses stock Material 3. Branch with `context.isCupertino`.
2. **Quiet reading surface.** Quran text sits on opaque paper. No glass, blur, or
   decoration over it.
3. **Instant feedback.** Changes apply at once. No spinner replaces visible
   content. First loads use the shared shimmer.
4. **One system.** Colour, radius, spacing, and sizes come from tokens. No
   per-screen styling.
5. **Arabic first.** RTL by default; every layout uses directional APIs.

## 2. Shape language

| Element | Radius token | iOS | Android |
|---|---|---|---|
| Fields, buttons, list rows | `radiusField` 16 | same | same |
| Cards, panels | `radiusCard` 24 | glass superellipse | M3 card |
| Sheets (top corners) | `radiusSheet` 28 | blurred surface | M3 container |
| Tab bar | pill | floating glass pill | M3 navigation bar |

Corners are never mixed on one surface. New shapes add a token first.

## 3. Colour

- Source: `ColorScheme` built by `AppTheme` from one seed per theme. Surface roles
  are rebuilt around the page canvas so pages, cards, fields, and bars share one hue.
- Themes: light, dark, sepia (reader). All three get every component theme.
- Roles: page `surface`; cards `surfaceContainerLow`; filled fields
  `surfaceContainerHighest`; selected state `secondaryContainer`; accent `primary`.
- Never hard-code a colour. Contrast meets WCAG AA in all three themes.

## 4. Layout and responsiveness

- Size classes: compact `<600`, medium `600–839`, expanded `>=840` (`WindowSize`).
- Compact: single column, bottom tab bar. Medium/expanded: navigation rail and a
  constrained content column (`ContentContainer`, max 960).
- Gutter: 16 compact, 24 wider (`pagePadding`). Content never sits under bars: the
  glass shell publishes bar insets through `MediaQuery.padding`.
- Verify at 320, 390, 600, 840, 1200 wide, portrait and landscape, text scale 1.0
  and 2.0, light/dark/sepia, Arabic RTL and English LTR.

## 5. Motion

- 200–300 ms, standard easing, implicit animations first.
- Respect `MediaQuery.disableAnimations`. Shimmer falls back to a static block.
- Tab switch uses the glass pill's own physics on iOS and the M3 indicator on
  Android. Sheets are draggable and snap.

## 6. Components (all in `lib/core/widgets`)

| Component | Purpose |
|---|---|
| `AppCard` | Grouped content (glass / Material) |
| `AppSelectField` | Single choice picker; search above 5 options |
| `AppSheet` | Draggable bottom sheet (glass on iOS); every sheet uses it |
| `AppSwitchTile` | On/off row, platform switch with app colours |
| `EmptyState` | Empty and error blocks with a retry action |
| `AppShimmer` *(to build)* | Skeleton loading, matches final layout |
| `MRETextField` (`mre_fields`) | Every text input |

Before writing a widget, look here. A pattern used twice becomes a component.

## 7. States

Every async screen has four states: loading (shimmer), data, empty, error with
retry. Small user actions are optimistic with rollback. Never flash a loader for
work under ~150 ms.

## 8. Screens

| Screen | Content | Status |
|---|---|---|
| Shell | App bar, tab bar / rail | done |
| Settings | Theme, language, launch behaviour (last tab / Mushaf), motion, digits, crash reports, About | done |
| Bookmarks | Empty state; list later | placeholder |
| Duas | Adhkar and duas tab | tab added, content blocked on a licensed source |
| Reader | Mushaf pages, surah/juz index, search, last position | blocked on sources |
| Credits | Attribution and licences | basic |

## 9. Roadmap

1. **Now:** shared shimmer; skeleton, empty, and error states for every screen.
2. **Reader data (needs your approval):** verified Tanzil Uthmani text and the
   KFGQPC fonts plus page map, each with source, licence, SHA-256, and attribution.
   Nothing is downloaded or bundled before you approve the sources.
3. **Reader UI:** surah/juz index, paged Mushaf with last position, search.
4. **Bookmarks, font size, goldens** for pages 1, 2, 42, and 604.
5. Audio, study tools, prayer times, advanced modes follow `IMPLEMENTATION_PLAN.md`.

## 10. Launch and reading position

- Setting "On launch": **last tab** (default) or **Mushaf**. The last tab is stored apart from settings and resolved before the first frame.
- The Mushaf tab reopens at the last page read. That position belongs to the reader feature and arrives with it.
