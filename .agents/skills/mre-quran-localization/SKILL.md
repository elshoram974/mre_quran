---
name: mre-quran-localization
description: Maintain MRE Quran ARB localization, Arabic/English locale state, and bidirectional Flutter layouts. Use when adding user-visible strings, locale settings, or directional UI.
---

# MRE Quran localization

- Keep all user-visible text in `lib/l10n/app_en.arb` and `app_ar.arb`.
- Run `fvm flutter gen-l10n` after an ARB change. Import the generated typed API
  through `core/l10n/l10n.dart`; do not introduce string-key lookup or globals.
- Keep Arabic as default. Persist only supported locale codes through
  `AppSettings` and expose language choices from one catalog.
- Use `EdgeInsetsDirectional`, `BorderRadiusDirectional`, `AlignmentDirectional`,
  `PositionedDirectional`, `TextAlign.start`, `TextAlign.end`, and `start`/`end`
  properties. Never add `left`, `right`, `fromLTRB`, or physical alignment for
  locale-relative UI.
- Physical direction is allowed only inside the verified Mushaf page renderer
  for immutable page geometry (for example, a glyph coordinate system). It
  requires an inline `mushaf-physical-geometry` explanation plus a widget test
  in both directions. Ordinary UI never receives this exception.
- Test every changed UI in Arabic RTL and English LTR. Test compact and expanded
  widths when layout changes.
