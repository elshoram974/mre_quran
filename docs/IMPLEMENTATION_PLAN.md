# MRE Quran implementation plan

## Goal

Ship an Arabic-first, offline-first Mushaf reader. The interface uses calm
translucent chrome outside the reading surface, adaptive layout by window
constraints, purposeful 200–300 ms motion, and minimal motion when requested.
The reader itself remains visually quiet and never places blur over Quran text.

## Design direction

- **Reading surface:** warm paper, high contrast ink, no glass or image layer.
- **Application chrome:** restrained shader-based Liquid Glass treatment for
  navigation and sheets only. `liquid_glass_widgets` keeps one visual system on
  iOS and Android while Material semantics remain the fallback.
- **Adaptive policy:** compact `<600`, medium `600–839`, expanded `>=840` logical
  pixels. Compact shows one page and bottom navigation. Expanded shows a
  constrained two-page spread when authoritative page data is available.
- **Duo/fold policy:** layout follows window constraints and safe areas, not a
  device name or orientation. Page and navigation state survive resizing and
  pose changes.
- **Motion:** page selection, bookmark, mode selection, and sheets use short
  state-change motion. All nonessential motion is disabled when the platform
  requests reduced motion.

## Phase 0 — foundation

1. Pin and use Flutter 3.47.5 / Dart 3.13.4 through FVM.
2. Preserve the existing app identity: `MRE Quran`, bundle id
   `net.mrecode.mreQuran`.
3. Adopt strict analysis, ARB localization, Riverpod, typed `go_router`, and
   feature-first layers.
4. Add project conventions, progress, decisions, traceability, CI, and release
   guidance.
5. Record the baseline release size before content assets are approved.

## Phase 1 — reader MVP

1. Import the unmodified Tanzil Uthmani source after checksum verification.
2. Add metadata, normalized search index, last-read state, bookmarks, index,
   credits, light/dark/sepia modes, and font-size controls.
3. Implement `PageRenderer` and `AssetPackManager` contracts. Ship only the
   font renderer after QCF font provenance is confirmed.
4. Add data integrity, search, provider, widget, and approved golden tests.

## Phase 2 — reliability and platform fit

1. Add an opt-in crash reporting abstraction. Activate Firebase Crashlytics
   only after `flutterfire configure` has generated real app configuration.
2. Verify compact, medium, expanded, iPad, and iPhone Duo pose changes.
3. Run profile-mode reader performance checks and document measurements.

## Later phases

- Audio needs a licensed recitation source and a download manager.
- Study tools need licensed tafsir and translation sources.
- Prayer, Qibla, Hijri, reminders, and widgets need platform permission and
  device verification.
- Images mode remains deferred until image source, licence, format, and size are
  approved. It will be downloadable, resumable, Wi-Fi-aware, measurable, and
  deletable.
- `docs/COMPETITIVE_AUDIT.md` maps public Golden Quran feature categories into
  a licensed, privacy-first roadmap without copying its content or branding.

## Mandatory gates

Each completed phase requires clean formatting, zero analyzer issues, passing
tests, documented real measurements, and a focused commit. No Quran asset,
image, font, audio, tafsir, or translation is bundled without an immutable
source, terms, checksum, attribution, and tests.
