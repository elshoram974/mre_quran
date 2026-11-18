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

## D-005: Firebase Crashlytics is on by default, with an opt-out

- **Decision (revised 2026-11-17, by the project owner):** Crash reports are collected from the first
  launch, without asking first, so problems on real devices are seen. The settings keep a switch to
  turn them off; the app applies it at every start. Debug builds never report. Collection is enabled
  natively (`firebase_crashlytics_collection_enabled`, `FirebaseCrashlyticsCollectionEnabled`) so a
  crash before Dart starts is reported too. The Crashlytics Gradle plugin uploads the R8 mapping of
  release builds. Do not add Analytics.
- **Was:** opt-in, off by default (decided before the first release).
- **Reason:** The owner needs crash data to fix problems before and after release. The privacy policy,
  the Data safety answers and the App Privacy answers say what a report holds.
- **Release builds:** they are obfuscated (`--obfuscate --split-debug-info=build/symbols`); upload the
  Dart symbols after each build or the Dart stack traces stay unreadable:
  `firebase crashlytics:symbols:upload --app=<Firebase app ID> build/symbols`.

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

## D-012: Native chrome per platform

- **Decision:** iOS/macOS use liquid glass chrome. Android uses stock Material 3.
  The platform comes from `Theme.of(context).platform`.
- **Reason:** Each platform should feel native. `device_preview` 3.0.0 was tried in debug
  and removed: it does not build on Flutter 3.47 (`PlatformDispatcher.resetInternalState`
  is unimplemented) and upstream has no fix. Check each platform on a simulator or device.

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

- **Decision:** `adhan` computes the five times from a foreground location chosen by the person; Android offers precise or approximate access. The stored coordinates are rounded to four decimal places. A map-selected place stays fixed, while a device-selected place may refresh quietly when already allowed. No location permission is requested at launch.
- **Alternatives:** A fixed daily time (wrong as the day moves); a server or API for times (sends the location away);
  background location (store review and battery cost).
- **Reason:** Prayer times are calculated locally, while a more precise foreground fix or a manually selected place can avoid an incorrect nearby village. The map uses Google Maps and the internet.

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


## D-027: Every sheet closes by pulling it down, from anywhere

- **Decision:** `AppSheet` draws its own handle only (the theme's `showDragHandle` drew a second one). A sheet
  sized to its content follows the finger down once its body is scrolled to the top and closes when let go a
  quarter of the way down or with a flick; a draggable sheet closes when its body lets it go below half the
  screen. `AppSheet.show(above:)` floats what the sheet acts on above it, outside it (the pressed ayah).
- **Reason:** A sheet whose body scrolled could only be closed from its handle.

## D-028: Ayahs are shared as a range that may cross surahs

- **Decision:** `AyahRange` (start and end `AyahRef`) replaces the one-surah span; `AyahOrder` numbers a
  reading's ayahs so a range is counted, stepped and cut per surah with that reading's own counts. Up to 50
  ayahs at once. The copied text puts each surah's ayahs in their own brackets with their reference. A long
  choice becomes several pictures of whole ayahs (about 650 letters each), all shared together. In the reader,
  "choose more ayahs" from an ayah's actions highlights a range that grows to each ayah tapped (or pressed),
  on any page, with a bar to copy or share it.
- **Alternatives:** Raise the old ten-ayah limit inside one surah; one tall picture.
- **Reason:** Passages often run across a surah's end (the end of Al-Baqarah into Al Imran). A picture taller
  than a phone screen is unreadable where it is sent.

## D-029: The adhan plays as announcement, adhan, dua; Fajr has its own adhan

- **Decision:** At prayer time Android plays, in order: the announcement of the prayer (when its recording
  exists), the chosen adhan (at Fajr the chosen Fajr adhan, with "الصلاة خير من النوم"), and the dua after the
  adhan; each can be turned off. A reminder comes 15 minutes before each alerting prayer (5 to 45, or off).
  The recordings are built by `tool/audio/build_adhan_audio.py` (cut, cleaned, -16 LUFS), bundled ones in
  `res/raw`, the rest served from the media repository's tag. See `docs/AUDIO_SOURCES.md`, which also lists
  the licences still to obtain.
- **Was:** One adhan for every prayer from Wikimedia Commons, too loud and with long silences.

## D-030: A month of adhan with one system alarm

- **Decision:** Android plans 30 days of prayers. The native scheduler keeps the list and arms only the next
  adhan; each one, when it fires, arms the one after it (and a restart arms the next). Notifications (the
  reminder before, the after-prayer adhkar, and the at-time alerts when the adhan does not play) are capped at
  the earliest 150. iOS plans 7 days and at most 48 notifications, inside its limit of 64.
- **Alternatives:** A background task (WorkManager, BGAppRefresh) that plans again daily: it needs the Dart
  engine and the adhan's method channel in the background, and iOS runs it when it chooses.
- **Reason:** The adhan must go on when the app is not opened for days, without nearing the alarm limit a
  phone sets an app.

## D-031: Shortcuts on the app's icon

- **Decision:** `quick_actions` (Flutter team) offers prayer times and adhan, Qibla, adhkar, and continue
  reading on a long press of the icon, named in the app's language and opened through the typed routes. Their
  icons are the app's own Material icons, drawn by `tool/app_icon/render_shortcut_icons_test.dart`.

## D-032: The launch screen goes the moment the first screen is ready

- **Decision:** `StartupSplash` stays mounted in the app's builder: it is what lets Android's launch screen go
  (without it the screen waited for its 4-second limit, its star stopped after 1.6 s, and the app looked
  frozen). On Android there is no least time: the launch screen goes as soon as the Quran text is read and
  the Mushaf page is drawn. The first page appears without fading (nobody sees a fade under the launch
  screen), and the pages around it are prepared only after it, so they do not compete with it. The text's
  three checksums are computed off the main thread, the files read at once, and the search keys built only
  when search is first used. When a notification, widget or shortcut opens another screen over the Mushaf
  (`opensOnReaderProvider`), the launch screen waits only for the text.
- **Measured** (emulator, profile build, cold start): ready at ~0.85 s after the process started, from ~1.5 s,
  and from 5.2 s with the launch screen held to its limit. Opening from the prayer widget no longer waits
  for the limit.

## D-033: Vibration is for counting only

- **Decision:** The app vibrates when an adhkar, tasbih or dua count ticks, a dhikr is done, or a list is
  done; and once, as a sample, when vibration is switched on. Navigation, pickers, the reader, the page
  scrubber and the Qibla stay still. `Haptics.select` is gone. Reminders vibrate through their notification.

## D-034: A basmala goes with its surah's first ayah

- **Decision:** Choosing a surah's first ayah highlights its basmala too (on the printed page, a box over
  the basmala's line above the ayah, also tappable; on the typeset page, the basmala line), and copying or
  sharing from a first ayah puts the basmala on its own line before it. Not for Al-Fatiha (its basmala is
  its first ayah), At-Tawbah, or a reading whose text has no separate basmala (the Complex's other readings).

## D-035: Adhan downloads come from where each recording was found, until the media repository exists

- **Decision:** `tool/audio/build_adhan_audio.py --serve source` points each downloadable voice at its own
  file (archive.org, or GitHub at a pinned commit) with that file's SHA-256, so download and preview work
  now. `--serve media` switches to the cleaned files once the media repository is published. The dua after
  the adhan is in Sheikh Al-Shaarawy's voice by default, or Sheikh Mishary Alafasy's, both bundled and each
  heard on the Adhan page. The announcement choice appears only once its six recordings are bundled.

## D-036: The prayer card widget, and seconds by choice

- **Decision:** A 4×2 prayer card (Android) and medium card (iOS) in the app icon's navy and gold: the
  coming prayer, its time, the time left, the Hijri date, and the day's five prayers. The time left counts to
  the second only when the person turns it on in the settings (Android `Chronometer`, iOS
  `Text(_:style: .timer)`, both counted by the system without waking the app); the app's own countdown
  always shows seconds. The tasbih widget is two cells by one at the least.
- **Splash:** `windowSplashScreenAnimationDuration` is 4000 ms, the longest the launch screen stays, as
  Android 12 and 13 stop the turning star after it.

## D-037: Al-Tafsir Al-Muyassar from an ayah's actions

- **Decision:** An ayah's actions offer its tafsir (Hafs only: the Muyassar explains the Hafs text). It is the
  `aya_tafseer` column of the Complex's file already bundled for the Mushaf script, read the first time it is
  asked for (checked against the file's SHA-256 on another isolate), never at start-up. The words are the
  source's; only the `<span class='aya'>` markup is taken out, and the Quran it quotes is set in the Mushaf
  script. The sheet shows the whole ayah above it, steps to the ayah before or after, and copies it with its
  reference (the source's ornate bracket glyphs become ﴿ ﴾ in the copy only).

## D-038: The sources and licences page

- **Decision:** The About page lists every source by kind (the Quran, the printed Mushaf and the readings,
  adhkar, recordings, prayer times, fonts and icons), each with where it comes from and its licence, and
  links to the libraries' licences. The adhan recordings are listed from the catalogue, so none is left out.

## D-039: On iOS the prayer alert rings with the adhan's opening

- **Decision:** iOS lets no app start a long sound by itself, and a background task cannot run at a set time
  or start audio (keeping the app alive with silent audio is rejected by App Review, guideline 2.5.4). So the
  alert at prayer time plays the first 29.5 seconds of the bundled adhan (the Fajr adhan at Fajr), copied at
  run time into `Library/Sounds` (no Xcode change), and is "Time Sensitive" so it comes through Focus
  (entitlement `com.apple.developer.usernotifications.time-sensitive`). The clips are iOS-only assets.
- **Not done:** Critical alerts (they would ring on silent) need Apple's approval, which is rarely given for
  this use. A chosen downloaded voice is not used on iOS: its sound would have to be converted on the phone.

## D-040: The tafsir for every reading

- **Decision:** Every reading offers Al-Tafsir Al-Muyassar. Shu'bah counts as Hafs. For Warsh, Qalun and Al-Duri,
  `tool/build_riwaya_tafsir_map.py` aligns each surah's ayahs with Hafs's by their words (letter skeletons,
  Gale-Church moves) and writes the ayahs whose Hafs ayah(s) differ in number (`<edition>_hafs.txt`,
  checked by SHA-256). An ayah that is only part of a Hafs ayah takes the Hafs ayah the one before it ended in.
  The sheet says "the tafsir of ayah N as Hafs numbers it" when it is another number.

## D-041: Hints at the right moment

- **Decision:** Four hints, each in a sheet, each at most once a run, with "don't remind me again" left
  clear: what permissions are asked for and why (before the first, once ever); try the adhan (once alerts are
  on); add the prayer card to the home screen (after the adhan was tried; Android asks the launcher, iOS says
  how); and, firmly, that the printed Mushaf needs the internet except for pages already opened (when a page
  is not on the device and the whole Mushaf is not downloaded), with a button to download the reading.

## D-042: The `global` branch

- **Decision:** The files the app downloads (cleaned adhan recordings) and the privacy policy live in the
  folder `mre_quran_global` beside the repository, pushed as the branch `global` of the repository
  `elshoram974/mre_quran_global` and published with GitHub Pages at
  `https://elshoram974.github.io/mre_quran_global/` (`AppConfig.mediaBase`). Every new media file goes there.
  Voices come from it, and from each recording's original when that fails. The policy is
  published from it with GitHub Pages. Its `LINKS.md` lists every address the app downloads from.
- **Splash:** "made by" over "MRECode" under the star, one picture (Marcellus and Cormorant Garamond
  Italic, OFL, drawn by `tool/app_icon/render_splash_brand_test.dart`): Android 12+ branding image, the launch
  window before Android 12 (`drawable/launch_compat.xml`), the iOS storyboard and StartupSplash.
- **Default adhan:** Nasser Al-Qatami (bundled); Mishary Alafasy's adhan is a download. Mishary's Fajr adhan
  stays the bundled Fajr default.
- **App facts:** names, version, and every outside address (media, privacy policy, WhatsApp, email) are in
  `lib/core/config/app_config.dart`.
