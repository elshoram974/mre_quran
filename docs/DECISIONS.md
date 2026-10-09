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

## D-015: Provisional Mushaf with Amiri Quran

- **Decision:** The Mushaf tab shows the pages now, drawn with Amiri Quran (SIL OFL 1.1). Each page holds the
  ayahs that start on that Madinah page, auto-fits its text to the frame, and shows a surah banner (name,
  order, ayah count, Meccan or Medinan), the basmala, ayah markers, and a page medallion. Ornaments are
  drawn in code, not images.
- **Alternatives:** Wait for the KFGQPC fonts and line layout; bundle per-page fonts without permission.
- **Reason:** The text and page starts are verified and licensed, and an open Quran font needs no
  permission. Lines are not yet the printed lines; that waits for the layout data.

## D-016: Adhkar are data, evidence is mandatory

- **Decision:** Collections are declared in `assets/adhkar/manifest.json`; entry files are checked by SHA-256 and a
  test fails when an entry has no source. Titles live in the manifest (like surah names), not in ARB.
  Quran dhikr store only ayah references; the text comes from the verified Tanzil file.
- **Alternatives:** One Dart enum per collection with ARB titles (every new list needs code); copying an
  unlicensed full Hisn al-Muslim JSON; typing the adhkar by hand.
- **Reason:** Changing content is a data edit. Religious text is either copied unmodified from a licensed
  source or cut from the hadith itself by a tool that fails when a reference does not hold.

## D-017: Back never closes the app by accident

- **Decision:** Pushed routes and sheets pop normally. At the shell: immersive reading restores its controls,
  any other tab returns to the Mushaf, and back on the Mushaf asks before closing (`AppConfirmSheet`).
- **Alternatives:** Double-back-to-exit toast; letting back leave the app from any tab.
- **Reason:** One stray back press should never lose a reading session; the warning appears only at the root.

## D-018: Sheets sit above the keyboard; Android tab bar expands the selected item

- **Decision:** `AppSheet` lifts itself by the keyboard height, limits its height to the room left, and keeps drag to
  dismiss. The Android tab bar is a floating pill where the selected destination grows into a labelled chip
  (`ExpandingNavBar`); iOS keeps the liquid glass tab bar.
- **Reason:** A sheet under the keyboard hid its own button; the old bar looked like stock Material.

## D-019: All of Hisn al-Muslim that can be checked, no more

- **Decision:** The remaining Hisn chapters are built by `tool/build_hisn.py` from the Arabic hadith editions: a dua is kept only
  when its words are found in a hadith (97% match, 85% of the entry) and the hadith has an acceptable grading. The
  words shown come from the hadith. About two thirds of the book's entries pass; the rest are listed, not shown.
- **Alternatives:** Copy the dataset's text (no licence, no evidence per entry); keep every entry with a note that it is unchecked.
- **Reason:** The tab promises evidence for every dhikr. A smaller list that can be proved is better than a complete one that cannot.

## D-020: After-prayer reminders use prayer times worked out on the device

- **Decision:** `adhan` computes the five times from an approximate location read when the person turns the feature on
  (and quietly at start-up when already allowed). Seven days of one-time notifications are scheduled each time the app opens.
- **Alternatives:** A fixed daily time (wrong as the day moves); a server or API for times (sends the location away);
  background location (store review and battery cost).
- **Reason:** No network, only coarse foreground location, and the reminder follows the real prayer.

## D-021: Vibration goes through one class, with a switch

- **Decision:** `Haptics` (`lib/core/haptics`) has static `select`, `tick`, `step`, `celebrate`. On Android it drives the
  vibrator directly with a short, strong pulse (the `vibration` plugin) and falls back to `HapticFeedback`; iOS uses the
  system haptics. A Settings switch sets `Haptics.enabled`. Feedback fires when the finger lands, before anything is saved.
- **Alternatives:** `HapticFeedback` at each call site.
- **Reason:** `HapticFeedback` is silent on many phones when "touch feedback" is off in their settings, which is why
  nothing was felt on a real device. One class keeps the patterns and the switch in one place.

## D-022: Prayer time alerts use the notification sound until an adhan recording is licensed

- **Decision:** The alert at each prayer is a high-importance notification on its own channel. It uses the phone's sound.
  No adhan recording is bundled: none was found with a clear licence, and `AGENTS.md` forbids audio without source,
  licence, checksum, and attribution. The channel is separate so a recording can be added later without touching the rest.
- **Alternatives:** Bundle a recording from a site with unclear terms; a download pack from a third party.
- **Reason:** A recording needs the reciter's and the recordist's permission, not only a file licence. A request is drafted
  in `docs/PERMISSION_REQUESTS.md`. iOS notification sounds are limited to 30 seconds, so the recording must be a short clip
  (kept in `Library/Sounds`, copied from a Flutter asset at start, so the Xcode project need not change); on Android it goes in `res/raw`.

## D-023: The notification scheduler, the payloads, and the clock are shared

- **Decision:** `lib/core/notifications` (scheduler, its provider, payloads) and `lib/core/time` (the ticking clock) serve
  both the adhkar and the prayer features.
- **Reason:** Two features used them; one should not import the other.

## D-024: A list opens as steps in a bottom sheet

- **Decision:** `AdhkarSteps` shows one dhikr per step, moves on when the count is done, and ends with the next list. The old
  page stays as "show as a list" and as the place a deep link can land. Both count through `countDhikr`.
- **Alternatives:** Only a long list of cards (the person scrolls to find where they are); a full-screen pager.
- **Reason:** One thing to read and one big button to press, with the list one tap away. The sheet keeps the tab underneath.

## D-025: A Qibla compass instead of a map

- **Decision:** `/qibla` shows a compass card drawn on the phone: the bearing comes from the `adhan` package and the heading
  from the accelerometer and magnetometer (`sensors_plus`), tilt-compensated and smoothed in `HeadingFilter`. A Kaaba marker
  sits at the Qibla; the phone ticks once when it faces it. Without a sensor the card is fixed with north up and says so.
- **Alternatives:** A map with tiles (needs the network and sends the person's place to a tile server; breaks the privacy
  promise and offline use); only a bearing number.
- **Reason:** It answers the same question, works offline, adds no permission, and keeps the location on the device.

## D-026: Shared row, header, tag, notice and group widgets

- **Decision:** `AppSectionHeader`, `AppTileCard`, `AppTag`, `AppNotice` and `AppGroupCard` in `lib/core/widgets` replace the
  per-screen copies in Settings, Adhkar and Prayer. `PrayerNoPlace` is shared by the prayer and Qibla pages.
- **Reason:** The same row, heading and message were written three or four times with small differences.

