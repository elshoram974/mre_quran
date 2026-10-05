# Decisions

## D-001: Use the existing project identity

- **Decision:** Keep `MRE Quran` and `net.mrecode.mreQuran`.
- **Alternatives:** Rename the application or recreate the project.
- **Reason:** The application already exists and the request did not provide a
  replacement identity.

## D-002: Use FVM Flutter 3.47.5

- **Decision:** Run project commands through `fvm flutter`.
- **Alternatives:** Use the globally selected Flutter 3.44.1.
- **Reason:** `.fvmrc` and `pubspec.yaml` require Flutter 3.47.5 / Dart 3.13.4.

## D-003: Adapt by constraints

- **Decision:** Use compact, medium, and expanded window widths instead of
  device detection.
- **Alternatives:** Branch by iPhone, iPad, Android foldable, or orientation.
- **Reason:** This preserves state through iPhone Duo and foldable resizing and
  also works in split view and desktop windows.

## D-004: Glass is chrome, never Quran content

- **Decision:** Limit translucent Liquid Glass surfaces to navigation, sheets,
  and controls.
- **Alternatives:** Blur the Mushaf page or use a full-screen glass effect.
- **Reason:** The reader needs stable contrast, lower GPU cost, and reverence.

## D-005: Firebase Crashlytics is configured but opt-in

- **Decision:** Use the Firebase project configured for MRE Quran (technical ID
  `mre-golden-quran-2026`) for Android and iOS Crashlytics. Initialise Firebase at startup, disable collection before
  rendering, and enable it only after the reader switches on the explicit
  Settings control. Do not add Analytics.
- **Alternatives:** Add a placeholder configuration or collect automatically.
- **Reason:** This preserves the offline/private product promise while keeping
  a real, verified crash-reporting integration ready for consent.

## D-006: Do not bundle QCF assets yet

- **Decision:** Wait for a verified KFGQPC font source and its redistribution
  terms before committing fonts or page maps.
- **Alternatives:** Repackage a third-party mirror or use a generic Arabic font.
- **Reason:** Exact Madinah layout and Quran integrity cannot be claimed without
  a verified matching source.

## D-007: iOS minimum deployment target is 16.0

- **Decision:** Raise the iOS target from 15.0 to 16.0.
- **Alternatives:** Keep iOS 15 support.
- **Reason:** The product targets modern iPhone layouts and benefits from a
  single, current baseline. The shader glass implementation itself has no
  native iOS plugin requirement.

## D-008: Use typed Flutter ARB localization

- **Decision:** Keep Flutter's generated ARB localization instead of copying
  Ledger's hand-written string-map engine.
- **Alternatives:** A key-value map with `.tr()` and static current-locale state.
- **Reason:** ARB gives compile-time typed strings, ICU plural/select support,
  reactive rebuilds, and normal Flutter/Shorebird patch compatibility. Ledger's
  useful practices remain: a supported-locale catalog, stored language choice,
  and context-based reactive access.

## D-009: Directional APIs are mandatory

- **Decision:** Use `start` and `end` APIs for all locale-relative layout.
- **Alternatives:** Physical `left`, `right`, `fromLTRB`, and `Alignment.*Left`.
- **Reason:** Arabic RTL and English LTR must mirror without special branches.

## D-010: MRE Quran is the product identity

- **Decision:** Keep `MRE Quran` as the only product/app identity.
- **Alternatives:** Reuse a competitor's product name.
- **Reason:** Golden Quran is a competitor researched only for public feature
  planning; it is not this application's name, assets, or branding.

## D-011: Use `liquid_glass_widgets` for restrained cross-platform glass

- **Decision:** Replace `liquidify` with `liquid_glass_widgets` and apply it to
  application chrome only.
- **Alternatives:** Keep an unmaintained native-plugin fork, or apply blur over
  every screen.
- **Reason:** `liquidify 0.1.1` fails to compile under Xcode 26.6. The selected
  package is pure Flutter/shader based, works on both target platforms, and its
  standard-quality mode honors accessibility settings. Quran page content stays
  opaque for legibility, reverence, and predictable performance.

## D-012: Native chrome per platform; Device Preview 3 in debug

- **Decision:** iOS/macOS use liquid glass chrome. Android uses stock Material 3.
  The platform comes from `Theme.of(context).platform`. `device_preview` 3.0.0 is
  enabled with `DevicePreview.enable(enabled: kDebugMode)`, and
  `syncPreviewPlatform()` (debug only) applies the chosen device's operating system.
- **Alternatives:** Glass on every platform (narrows D-011 to iOS); `device_preview_plus`
  and `device_frame_plus` (catalog stops at iPhone 14 Pro); `device_preview_screenshot`
  (requires Dart < 3).
- **Reason:** Each platform should feel native. `device_preview` 3.0 ships current
  presets with real frames and system UI (iPhone 16/17/Air, Pixel 9/10, Galaxy S24/S25,
  foldables, tablets). It is controlled from Flutter DevTools. Its screenshot tool lives
  there too, so no custom screenshot tool is added. Device and target platform are
  separate overrides, which `syncPreviewPlatform()` keeps in step.

## D-013: Shared draggable sheet and optimistic settings

- **Decision:** All bottom sheets use `AppSheet` (`DraggableScrollableSheet`): translucent
  blurred surface on iOS, Material 3 container on Android. Settings changes apply
  immediately and persist in the background with rollback on failure.
- **Alternatives:** `GlassModalSheet` (rendered a clipped artifact inside a scaled
  preview and is not draggable by content); awaiting storage before applying (delayed
  theme changes and flashed a spinner).
- **Reason:** One predictable, draggable sheet on both platforms; theme and locale
  switches feel instant.

## D-014: Bundle Tanzil text and keep two search keys per ayah

- **Decision:** Bundle Tanzil Uthmani and Simple Clean (`txt-2`, v1.1) unmodified. Display uses Uthmani. Search
  folds both texts and matches either spelling.
- **Alternatives:** Derive the plain text from Uthmani in code; search only the Simple Clean text.
- **Reason:** Both files have a clear CC BY 3.0 licence and cost about half a megabyte compressed. Folding
  Uthmani alone cannot recover imlaei spellings (dagger alef against full alef), and folding only the plain
  text misses a query copied from the Mushaf. Each file keeps its own checksum and is never edited.
