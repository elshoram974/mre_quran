# Decisions

## D-001: Use the existing project identity

- **Decision:** Keep `MRE Quran` and `net.mrecode.mreQuran`.
- **Alternatives:** Rename the application or recreate the project.
- **Reason:** The application already exists and the request did not provide a
  replacement identity.

## D-002: Latest stable Flutter, no version manager

- **Decision:** Use the latest stable Flutter on the PATH (3.50.0, Dart 3.14.0 at the time of writing), with
  plain `flutter` commands. No FVM: the owner keeps the machine on the latest stable.

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
  `tool/build_android_release.sh` builds and uploads in one step.
- **Breadcrumbs:** every `AppLogger.debug` line also goes to Crashlytics' log (`AppLogger.attach`), so a report
  carries the steps before it; the lines name kinds of failures and steps, never what the person read or where
  they are. An error the app recovered from is reported, not fatal, with its stack (`AppLogger.recovered`).

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

- **Decision:** Only the platform's own launch screen shows; Flutter draws no splash. Android and iOS keep
  their launch screen until Flutter sends its first frame, so `main` holds that frame back
  (`LaunchHold`, `deferFirstFrame`): the first screen is built, laid out and painted underneath, and
  `LaunchGate` lets the frame through as soon as the Quran text is read and the Mushaf page is drawn
  (`startupReadyProvider`). When a notification, widget or shortcut opens another screen over the Mushaf
  (`opensOnReaderProvider`), it waits only for the text. The hold has its own limit (`AppTokens.launchMost`,
  4 s, timed from `main`, not from a widget), so nothing that goes wrong while the app builds can keep the
  launch screen up. The pages around the first are prepared only after it, and the text's checksums are
  computed off the main thread.
- **Why not hold Android's launch screen natively** (`setKeepOnScreenCondition`): Flutter already delays
  Android's first draw until its own first frame, and holding the draw from both sides left the app stuck
  on its launch screen.
- **Measured** (emulator, profile build, cold start, before this change): ready at ~0.85 s after the process
  started.
- **The emblem keeps moving until the screen goes** (Android 12+, `splash_star.xml`): the contours draw once,
  then the emblem hops on a loop, so the launch screen is never still while the app is not ready. It stops
  when the first frame is shown, or at the hold's limit (`AppTokens.launchMost`, 4 s), whichever comes
  first. Older Android and iOS draw a still launch screen; they cannot animate it.
- **Start-up must not end before `runApp`** (2026-11-19, found on a Xiaomi POCO X3 NFC, Android 12, from the
  hung process's own log): the launch screen waits for the first frame, so `main` ending early leaves it up for
  good, with no crash and no ANR. A launch opened from the adhan's notice stopped in `main` with
  `type 'Null' is not a subtype of type 'bool'` from Crashlytics (`setCrashlyticsCollectionEnabled`), which
  throws on the call itself, before it returns a future, while its native side has not reported yet. The call
  was an argument to `_optionalStartup`, so nothing caught it. Now `optionalStartup` takes the step as a
  function and catches it where it is called, `FirebaseCrashReporter`'s methods are `async` so a plugin that
  is not ready fails the future and never the caller, and `main` falls back to opening the app on its defaults
  if anything else before `runApp` throws (the failure is then rethrown, so it is reported).

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
  window before Android 12 (`drawable/launch_compat.xml`) and the iOS storyboard.
- **Default adhan:** Nasser Al-Qatami (bundled); Mishary Alafasy's adhan is a download. Mishary's Fajr adhan
  stays the bundled Fajr default.
- **App facts:** names, version, and every outside address (media, privacy policy, WhatsApp, email) are in
  `lib/core/config/app_config.dart`.

## D-043: Every launch leaves a trace until it is on screen

- **Decision:** `StartupTrace` (`MainActivity.kt`/`StartupTrace.kt` on Android, `AppDelegate.swift` on iOS)
  notes each step of a launch: where it came from (the icon, a restore, or the intent's action and extra
  names; the launch option names on iOS), the engine, the activity or scene lifecycle, Dart's own steps
  (`dart:main`, any start-up service that timed out, `dart:runApp`, `release:ready` or `release:limit`), and
  the first frame on screen. Each step goes to the system log (logcat tag `MushafiStartup`; iOS subsystem
  `net.mrecode.mreQuran`, category `startup`) and is kept on the device until the first frame is shown.
  When a launch never got there (and was not left by the person within 3 s), the next launch reports it
  through `AppLogger.launchStalled` as a non-fatal `LaunchStalled` carrying its steps.
- **Why:** a launch that stayed on the launch screen happened on a device and could not be reproduced on
  emulators; the trace says where it stopped the next time it happens.
- **Privacy:** step names, milliseconds, the OS version and the intent's extra names only; reported only when
  crash reports are on, and never from debug builds.

## D-044: Widget previews are drawn in the app, and the widgets have a language of their own

- **Decision:** The widgets page draws each widget's preview with Flutter (`HomeWidgetPreview`), from the
  colours of the Android resources (`WidgetPalette`) and the arrangement of their layouts, at the widget's
  default size, with today's real times when a place is saved (the sample day otherwise). The pictures in
  `res/drawable-*nodpi` stay only as the launcher picker's own `previewImage` (redrawn by
  `tool/capture_widget_previews.sh`); Flutter no longer bundles them. The widgets speak the language chosen for
  them (`AppSettings.widgetLocaleCode`: the app's own, Arabic or English): their words, dates, clock and
  direction, set when the app sends them their data (`PrayerWidgetSyncScope`).
- **The prayer card is two launcher rows tall** (it was three, which left it empty in the middle). Under 150dp
  it shows the coming prayer and the next three prayers in one row; from 150dp, the whole day.
- **Padding follows the size**, like the text: every prayer widget scales its padding with `WidgetScale`.
- **Not decided yet:** the native text that is not sent from the app (the widget's name, the empty-state line)
  still follows the phone's language.

## D-045: Weekly reminders come from a JSON file, and the widgets page is a list of sections

- **Decision:** Reminders that repeat on a weekday are listed in `assets/reminders/weekly.json` (schema 1: `id`,
  `weekday` 1–7 from Monday, `time`, Arabic and English title and body, an optional `surah` to open). Adding one
  needs no code: `WeeklyRemindersNotifier` schedules each with `DateTimeComponents.dayOfWeekAndTime`, remembers
  whether the person turned it on and at what time, and a tap opens the surah. The first entry is Friday's
  Surat Al-Kahf (`friday_kahf`, 09:00). An entry that does not parse is skipped, never fatal.
- **The widgets page** keeps the settings for every widget (colours, language) at the top, then one section per
  widget that opens to its preview and the settings that belong to it alone (today only the prayer schedule's).
  Each header says what the widget is and has its own *Add* button.

## D-046: Share pictures hold more ayahs, and the person chooses how many pictures

- **Decision:** On the share card the ayahs of a surah flow as one justified paragraph, as on a Mushaf page, each
  number tied to its ayah with a no-break space (a line never ends on an ayah and starts the next with its
  number). A single short line is centred. Left automatic, a picture holds up to
  `AyahShareText.lettersPerPicture` (1400) letters, tashkeel counted; the person can instead set the number of
  pictures (1 to `maxPictures`, never more than the ayahs), and the letters are shared between them as evenly as
  whole ayahs allow. The *Automatic* chip hands the choice back.
- The surah banner leaves more room above and below the name, so its caption never touches the plaque's line.

## D-047: The app opens on the Mushaf, important notices are red, and every ayah is in the Quran's font

- **Decision:** `StartupBehavior.reader` is the default: the app opens on the Mushaf until the person chooses
  *last tab* in Settings. The stored key is `settings.startup_behavior`, so a choice saved before this default
  existed does not keep an old default alive.
- **Important notices** (`AppNotice(important: true)`) are red, on a tinted box with the action inside it: a
  setting the alerts depend on (exact alarms, for the prayer alerts and the adhan) must be seen as the page opens.
  Plain hints stay muted; errors stay red without the box.
- **Every ayah in the app is drawn in the Quran's own font** (`appQuranFont`): the Mushaf script
  (`QuranText.mushaf`, KFGQPC Hafs) with its font, in the reader, the share card, the tafsir, the search and
  bookmark results and the Quran dhikr of the adhkar. The Tanzil Uthmani text stays for copying and sharing as
  text, and the plain words of the duas stay in the app's Quran font (Amiri).
- **The map page** shows what to do, the place chosen (named when its name is found) and what the map needs, with
  a labelled *Use my current location* button; the pin is red with its tip marked; a search that finds several
  places lists them by name.

## D-048: Pinching resizes the text of the adhkar and of the typeset Mushaf, and nothing else

- **Decision:** Two fingers change a text size only where there is text to read: the words of the adhkar
  (`AdhkarPinch`, kept as `AppSettings.adhkarFontScale`) and the typeset Mushaf's text
  (`AppSettings.readerFontScale`). The app-wide text scaler is gone, so a pinch changes nothing on the settings, the
  prayer page, the bookmarks, or the map (which keeps its own zoom). A printed page cannot be enlarged: a pinch there
  only suggests turning the phone (`PinchOut`).
- **How:** `PinchZoom` magnifies nothing. While the fingers move it hands the size they have reached, in steps of
  0.02, to its owner, which sets its text at that size at once; on release it hands the final size to keep, once. A
  pinch counts from the size it began at, so an owner that shows the size as it changes does not compound it.

## D-049: The alerts and the Friday reminder are on until the person turns them off

- **Decision:** The first time a place is given (the phone's location, or a point on the map), the alert at each of
  the five prayers comes on, and the notification permission is asked for then: the person's own tap set the
  place. If it is refused the place still saves and the alerts stay off, and nothing asks again. It happens once: a
  place set before, or alerts already chosen, leave it alone, and a person who turned them off keeps them off when
  the place changes. Nothing is asked at launch.
- **Weekly reminders** (`assets/reminders/weekly.json`) take `"enabled": true` to be on until the person turns them
  off (the Friday Surat Al-Kahf reminder does); without it they are off until turned on. A reminder that is on is
  scheduled when the app starts, without asking. The reminders sheet asks once when it opens with a reminder on, and,
  if the phone refuses notifications, says so in red at the top: a switch that is on must not promise what cannot
  happen.

## D-050: The prayer page is a tab, and the settings are a list of pages

- **Decision:** The bar has five tabs: Mushaf, Adhkar, **Adhan** (the prayer times, their alerts, the qibla and the
  adhan's voice), Bookmarks, Settings. Everything that used to push the prayer page now switches to the tab, so
  there is one prayer page and no copy over another screen.
- **The settings** are a list of what can be set (`SettingsPage`): *Appearance* (colours, language, digits, motion),
  *Reading* (what opens first, the reader's mode, layout, frame, page turn), *Offline Mushaf*, *Alerts and
  vibration* (the prayer times, the adhan, the reminders, vibration), *Widgets* (which also holds the seconds on the
  prayer widgets), *Privacy*, and, under *Contact us*, WhatsApp, e-mail and *About*. Each opens a page of its own, at
  `/settings/<name>`, so no page is long.

## D-051: The adhkar's text size, the view settings, the app's identity, and the app's links

- **Text size:** `AppSettings.adhkarFontScale` sizes the adhkar's words, their heading, and the evidence sheet;
  `readerFontScale` sizes the typeset Mushaf. Both are set by a slider on the *Display* settings page (and the
  Mushaf's by the one in its display options), or by two fingers on the text (D-048).
- **The settings** are one entry for everything about the view (*Display*: colours, language and digits, the two text
  sizes, what opens first, how the Mushaf is shown, motion and vibration) and one entry for each other thing: the
  adhan, the reminders, the offline Mushaf, the widgets, privacy. Adhan and reminders open straight onto their own
  page and sheet.
- **Identity:** `AppSnackBar` (the app's mark, the accent's edge), `AppBrand` (the mark and the name) on the
  confirmation and hint sheets, and one set of paper, edge and corners for dialogs, the time picker, menus and
  tooltips in `AppTheme`. `AppMark` draws the launch screen's star.
- **The app's links:** `AppConfig.googlePlayUrl`, `appStoreUrl` and `appGalleryUrl`, empty until the app is in that
  store. `StoreLink.available` keeps the ones that are real web addresses. Shared ayahs (as text or beside pictures)
  end with the app's name and one line per store, each line from the right; copying takes the ayahs alone. A
  *Share the app* tile in the settings sends the same lines, and is not there while no store has the app.

## D-052: The start-up location read is silent

- **Decision:** At each start the app may refresh a device-selected place, but only when the permission is already
  given **and location is switched on** (`LocationSource.quiet`). With location off it reads nothing.
- **Reason:** Asking Android's fused provider for a fix while location is off makes Google Play services show its own
  "turn on location" dialog over whatever the person is doing (reading, or looking at the prayer times). D-020's
  "no location permission at launch" now covers that dialog too. The explicit paths (*Use my location*, the map's
  button) already check first and say what to do in the app's own words.

## D-053: A downloaded Mushaf is unpacked without the settings, and offline the reader turns to text for real

- **Unpacking:** The system downloader finishes the offline Mushaf even when the app is closed, and its notice then
  says it works offline. Nothing unpacked the archives until the *Offline Mushaf* page was opened, so the reader
  went to the network for pages already on the phone and said there was no internet. Now the reader unpacks a
  waiting download once its first page is drawn (`waitingPackProvider`), the store unpacks it before it would
  download a page (`SvgPageStore._ensure`), and the pack shows as being made ready, never as missing, while it is.
- **Offline:** When a printed page of Hafs cannot be had because the server cannot be reached (`isUnreachable`), the
  whole reader switches to the typeset text, saved in the settings with `AppSettings.textUntilOnline`, and a snack
  bar says why. The settings say it too. The reader keeps trying a page that is not on the phone (on a page turn,
  when the app comes back, every 30 seconds) and returns to the printed Mushaf, with a snack bar, as soon as one
  downloads, or at once when every page is on the phone. The person choosing a mode
  (`SettingsNotifier.chooseReaderMode`) ends it. A page out of sight never switches the reader. Another reading has
  no text of its own, so it stays printed and says why on the page. A slow page (30 seconds) still shows its text
  in place, as before; a server that answers with an error is not "offline".
- **Was:** Text stood in for the one page while the settings still said *Printed Mushaf*.

## D-054: The adhan is an alarm clock, a late one still shows, and battery saving is named

- **Decision:** With exact alarms allowed, each adhan is armed with `AlarmManager.setAlarmClock` (D-030's one alarm at a
  time is unchanged). The system keeps an alarm clock to the minute through Doze, app standby buckets and battery
  saving, lets it start the adhan's service from the background, and shows the next one with the alarm icon; a tap
  on it opens the prayer times.
- **Late delivery:** The receiver used to drop an alarm the system handed over after its minute, silently, and the
  plain at-time notification is not scheduled when the adhan takes the prayer. Now an alarm up to 3 minutes late
  still plays; up to an hour late, the prayer's notice shows without sound; later than that (a clock moved on) it is
  dropped.
- **Battery:** While the adhan is on and the phone optimises or restricts the app's battery use, the Adhan page and the
  prayer alerts show a red notice with a button to the app's system settings, where *Battery* is set to
  *Unrestricted* (some phones: *No restrictions*, *Auto-start*). It is checked again when the app comes back. No
  permission is declared for it; `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (a one-tap system dialog) is restricted by
  Google Play and is not used.
- **Exact alarms:** The Adhan page now says that without them the adhan does not play at all, only a plain
  notification, rather than that it may come a few minutes late.

## D-055: The timetable widget's countdown has room of its own, and its date has no year

- **Decision:** The coming prayer's countdown sits 2dp above its name and time (`schedule_countdown_gap`) with its
  font's own padding, instead of being tucked 2dp into them. A phone's own font can draw taller than its line; with
  the tuck, the countdown and the time ran into each other. The timetable needs 6dp more for it (`COUNTDOWN`).
- **The date** on the widgets is weekday, day and month (`DateFormat.MMMEd`); the year made it run past the narrow
  timetable ("…٢٠"), and the Hijri line under it carries its own year.
- **The header** of the timetable is set apart from the times: 3dp between the date and the Hijri date, then a
  faint gold hairline (`widget_divider`) 8dp under them, and 12dp above and below the content. The sides keep their
  room (12dp, and 10dp to the text); nothing was widened.
- **The prayer card** on a launcher whose cells are tall used to open an empty band under the coming prayer: its
  content is made for about 210 by 150dp. On Android 12 and later its rows of times now take 90% of the height left
  over once the top has its room (`cardRows`), so it fills its cell as its preview shows; earlier versions cannot change a view's height and
  keep the band. The widgets' picker previews are drawn again from the layouts.

## D-056: The reminder before a prayer counts down to the adhan

- **Decision:** On Android the reminder before a prayer (D-029) is a notification of the app's own
  (`PrayerSoonNotice`), not one of the plugin's: its content area shows the prayer's name, *Left until the adhan ·
  4:56 pm*, and the time left as a large countdown to the second. The countdown is a `Chronometer` in a
  `RemoteViews` layout (`prayer_soon_notice.xml`), which the system redraws every second itself, so the app does not
  run, wake or hold a service while it counts. Text that changed every minute would need the app awake every minute,
  which battery saving holds back, so none is used. The notice stays until the adhan and then goes by itself
  (`timeoutAfter`), and has a *Remove* button that takes it away at once without opening the app and a settings
  button. It follows the app's language and direction, not the phone's (`rtl`, as the widgets do). It is on until the
  person turns it off under the reminder on the prayer times page (`PrayerSettings.beforeCountdown`); off, it is a
  normal notification whose words say how many minutes are left.
- **Scheduling:** `PrayerSoonScheduler` keeps the list and arms only the next alarm, as the adhan's scheduler does
  (D-029), and arms again after a restart (`PrayerSoonReceiver`). The channel is the same `prayer_soon` the reminder
  always had, so the person's choices for it stay. Dart reaches it through `PrayerSoonPlatform`.
- **iOS** has no countdown in a notification; there the reminder still says how many minutes are left.

## D-057: Reminders of the sunnah fasts

- **Decision:** The reminders sheet has *Sunnah fasts*: Mondays and Thursdays, the white days (13th to 15th), the Day
  of Arafah, Tasu'a and Ashura, and six days of Shawwal, each with its own switch and the day it comes next. One
  notification comes the evening before (9 pm, the person may move it), naming every reason the day is a fast. All
  are on until the person turns them off, as D-049's alerts are. A tap opens the prayer times (Fajr and Maghrib).
- **Dates:** Hijri dates are Umm al-Qura's (`HijriDate`), which can be a day off the local moon sighting. So no
  reminder falls on a day that could locally be a day when fasting is not allowed: none in Ramadan, on the 1st or 2nd
  of Shawwal, or from the 10th to the 14th of Dhu al-Hijjah. The six of Shawwal are reminded of for the 3rd, and the
  white days are not reminded of in Dhu al-Hijjah. The sheet says so.
- **Planning:** Each run plans afresh (`FastingPlan`, ids from 7003001): Android 60 days ahead; iOS 21 days and at most
  8 notifications, within its 64 pending with the prayer alerts.

## D-058: Every notification has a Settings button

- **Decision:** Each reminder carries a *Settings* button (`settingsLabel`): the adhkar, weekly, after-prayer and
  fasting reminders open the reminders sheet over the Settings tab (`ReminderPayload.remindersSettings`); the
  reminder before a prayer and the prayer-time notice open the prayer times, where their alerts are chosen
  (`prayerSettings`); the adhan's own notice, beside *Stop*, opens the Adhan settings (`adhanSettings`) while the
  adhan plays on. On Android the button opens the app (`showsUserInterface`); on iOS it is a category action, named
  once at start-up in the app's language then, so a language change shows on it from the next launch.

## D-059: The reader says exactly why it changed, and another reading can be read as text

- **Messages:** Switching to text offline says there is no internet and the page is not on the phone. Coming back
  says "the internet is back" only when a page was downloaded; when every page of the reading is on the phone (a
  reading downloaded whole, or a download unpacked meanwhile) it says that instead, internet or not. A page that
  is only slow says it is slow; one the server failed says it could not be loaded, and, without text to stand in,
  to try again in a moment rather than to check the connection.
- **Another reading:** Its page that cannot be had offers *Read the typeset text (Hafs)*. Offline, the reader shows
  the text until the printed reading can be had again, and says so naming the reading; when the server failed, the
  text is the person's own choice and stays. Its *Download the whole reading* button opens the Offline Mushaf page
  itself.

## D-060: A failed printed page is retried by hand, afresh; offline, other readings are offered

- **Retry:** Riverpod's own retry is off for the printed pages (`retry: (_, _) => null`): it downloaded a failed page
  again and again offline, and kept showing the failure while it did. The page's *Retry* button builds the page
  view afresh (`_SlowGate` keys it by a generation), so nothing the failed view held is used again, and the page
  shows as loading, not as failed, until it is had or fails anew. A provider no longer uses its `ref` after a wait
  without checking `ref.mounted`.
- **A blank page:** a person tapping *Retry* got a grey page: building the view threw "called
  ProviderSubscription.read on a subscription that was closed", and every rebuild of that view threw it again, on
  a downloaded reading too, until the app was opened again. It could not be made to happen in a test (five
  setups). Should it happen, the page's providers (`svgPageProvider`, `svgPageStoreProvider`,
  `printedEditionProvider`) are made anew, as a new start would, and the view built afresh: twice at most in five
  seconds, then an error whose *Retry* does the same. The error is reported whole, not fatal, and printed with its
  stack outside release builds.
- **Elsewhere:** under a page that cannot be had offline, the readings that have that page on the phone are offered,
  each opening it (`PrintedFallback.openReading`); when none has it, the nearest page this reading has. Turned to
  text offline (Hafs), the message names a reading that has the page and its short *Show it* opens it.


## D-061: The person can move the times, set summer time and height, and move the Hijri date

- **Decision:** A page of its own, *Adjust the times* (`PrayerTuningPage`, reached from the prayer times page), holds
  four choices, all kept with the prayer settings (`PrayerSettings`) and all applied in one place, `PrayerDay.compute`
  (through `PrayerTuning`), so the page, the alerts, the adhan, the reminders and the home-screen widgets show the
  same times.
  - **Minutes for each prayer**, up to 30 either way, one step at a time. They are the `adhan` library's own
    per-prayer adjustments, so a prayer moved by 3 minutes alerts and plays the adhan 3 minutes later. Sunrise is not a
    prayer and is not moved by hand.
  - **Summer time:** *follow the phone* (default), *summer* or *winter*. The times are on the phone's clock, which
    follows its own time zone, and the app has no map of time zones, so it cannot tell by itself when that clock is
    wrong for the place. The person says so; the page also says which the phone is on now. *Summer* adds an hour only
    when the phone is not on summer time already, and *winter* takes it off only when it is, so a right clock is never
    moved twice.
  - **Height above sea level:** the phone's GPS height when the place came from the device (kept with the place,
    read at no cost and with no new permission), or one the person types (0 to 9000 m). A typed height is dropped when
    the place moves more than a kilometre, but not for the few metres a GPS fix wanders. The height lowers the
    horizon, which brings sunrise earlier and sunset (and so Maghrib) later by `0.0347° × √metres`, the PrayTimes
    calculator's correction; Fajr, Dhuhr, Asr and Isha do not depend on the horizon and are not moved. The page says what
    it does to the day. No outside elevation service is used: it would send the person's coordinates to a third party.
  - **Hijri date:** moved by one or two days (`PrayerSettings.hijriShift`, `HijriDate.of(shift:)`), because the
    Umm al-Qura tables can differ from the moon sighting where the person is. It changes the date shown (widgets
    too) and the sunnah fasts' reminders (D-057), which are planned again when it changes. It is one setting for the
    whole app, not for the prayers only. It is the Hijri date that moves: the Gregorian one has nothing to correct.
- **Not done:** an automatic check of the phone's summer time against the place, for want of a time-zone map;
  the iqama and the sounds of the reminder before a prayer, which wait for recordings whose source and licence are
  recorded (see `docs/AUDIO_SOURCES.md`).

## D-062: Reminders are a page of their own, and the person can make their own

- **Decision:** The reminders sheet is a page (`RemindersPage`, `/reminders`), opened from Settings, the adhkar tab
  and a notification's settings button. Under *My reminders* the person makes reminders with their own title and
  note: **daily, weekly (chosen weekdays) or monthly (a day, 1 to 28)**, at **one to six times a day**
  (`CustomReminder`). The form (`ReminderEditorPage`) says when the reminder will first come before it is saved, why
  it cannot be saved when it cannot, and asks before deleting. The adhkar's daily and weekly reminders, the sunnah
  fasts' (D-057) and the one after each prayer keep their switches, each under its own heading.
- **Limits:** 20 reminders, and 14 moments (times over days) in each, because the system keeps each as a notification
  (iOS 64 in all, shared with the prayer alerts). The day of a monthly reminder stops at 28 so that every month has it.
- **How:** each moment is one recurring notification in its own channel (`custom_reminders`), with a stable id from
  the reminder and its place in the list; saving or deleting clears all its ids before setting the current ones, so
  nothing is left behind. A reminder saved without the notification permission is kept, off, and the page says why.
  Monthly repeats use the plugin's day-of-month match (`ReminderScheduler.schedule(dayOfMonth:)`).
- **Sunnah fasts:** each fast day already has its own notification the evening before (a run of three white days
  gives three), not one before the first (`FastingPlan`, D-057).

## D-063: The iqama, and the sound of the reminder before a prayer

- **Decision:** A page, *The iqama* (`IqamaPage`), sets a notice at each prayer's iqama: the words «قد قامت الصلاة،
  قد قامت الصلاة», not the whole iqama. It comes a number of minutes after the adhan that the person puts per prayer,
  5 to 60 (usual gaps until then: Fajr 20, Dhuhr 15, Asr 15, Maghrib 10, Isha 15), counted from the prayer's time as
  moved by D-061, and shows each prayer's resulting time. It is for the five prayers whether or not their alert is
  on. Its notice has a sound switch, and the reminder before a prayer has one too (`beforeSound`): off, the notice
  comes silent (`silent` on Android; no sound on iOS; the platform's own countdown notice follows it).
- **Sounds:** the iqama's notice plays the phrase «قد قامت الصلاة» twice (about nine seconds, the Grand Mosque's
  muezzin), and the reminder before each prayer a voice saying «اقتربت صلاة …» for that prayer (Fajr, Dhuhr, the
  Friday prayer, Asr, Maghrib, Isha), each in a notification channel of its own, because a channel keeps the sound it
  was made with. They are real recordings of people that people already use, not synthesised, bundled, and kept
  small (a few seconds each at 40 to 48 kb/s; iOS 16 kHz), so they cost the app a few hundred kilobytes at most. Source,
  licence and checksums are in `docs/AUDIO_SOURCES.md`; the rights are being asked for. iOS installs the sounds in
  `Library/Sounds`. They were checked by machine only: listen to each before a release. **Not proved human:** no page
  says who recorded the six «اقتربت صلاة …» clips (one voice, the owner's choice after hearing the Friday clip; an
  earlier set in Egyptian pronunciation was dropped); permission is asked for (`AUDIO_PENDING_LICENCES.md`, W6).
- **Limit:** with the iqama's notices Android is now given up to 300 notifications at once (it was 150), well below the
  alarms a phone allows an app; the plan still covers 30 days and is made again at each start.

## D-064: One dua after the adhan ships with the app; the other is downloaded

- **Decision:** Of the two voices of the dua after the adhan, Sheikh Mishary Alafasy's ships with the app (143 KB) and
  is the default; Sheikh Al-Shaarawy's (562 KB) is served from the media repository (`mre_quran_global`,
  `adhan/dua_after_adhan_shaarawy.m4a`, its archive.org original as the fallback) as a catalogue voice of kind `dua`.
  On the Adhan page, under the dua switch, each has a row: the bundled one is chosen with a tap; the other can be
  heard from the network, is downloaded with its button or by choosing it (and is chosen once it is on the phone),
  shows its progress and why a download failed, and can be deleted. The alert plays the downloaded file
  (`duaPath`); when it is missing, or another is chosen, the bundled one plays (`duaRecording`).
- **Why:** the owner asked for one of them inside the app and the other on demand, to keep the app light. The
  smaller one is the one bundled; a person who chose the other before this change keeps the bundled one playing
  until they download it.
- **Also:** each voice card on the Adhan page now watches only its own state, so a download's progress no longer
  rebuilds the whole page.

## D-065: Android keeps every prayer notice itself, handed over in one call

- **Decision:** On Android, every prayer notice (at the prayer time when the adhan does not play, before the prayer
  with or without its countdown, at the iqama, and the adhkar after a prayer) goes to the app's own scheduler
  (`PrayerSoonScheduler`, the one that already kept the countdown reminder) in one call: it stores the month's list
  and arms only the next alarm, as the adhan's scheduler does. A notice is shown as the plugin would show it, on the
  same channels, with the same importance, sound, silence, tap and settings button (`PrayerSoonNotice`), and is not
  shown once too late to help (the iqama's after 15 minutes, the prayer time's after 30, the adhkar's after an hour).
  iOS, and Android if the call fails, keep the notifications plugin as before. Both native schedulers cancel only the
  one alarm they armed, not one per stored alarm.
- **Why:** the app makes the plan again at each start. The plugin takes notices one at a time and rewrites its whole
  saved list for each, on the main thread, which also runs the app's UI: with up to 300 notices, the start was held
  for seconds. One call costs one write. The plugin's 300 limit no longer applies on Android, so the iqama and the
  adhkar after the prayers cover the whole month too.
