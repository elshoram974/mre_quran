# Audio sources: the adhan

What plays at prayer time, in order (Android, `AdhanAudio.steps`):

1. **The announcement** of the prayer: "حان الآن موعد أذان الظهر" (`res/raw/announce_<prayer>.m4a`,
   `announce_jumuah` on Fridays). **No recording yet** (see the licence list below). The Adhan page offers the
   choice only once all six are in the app; until then the step is skipped.
2. **The adhan**: the chosen voice, and at Fajr the chosen *Fajr* voice, which says "الصلاة خير من النوم".
3. **The dua after the adhan**, "اللهم رب هذه الدعوة التامة…" (Bukhari 614), in Sheikh Mishary Alafasy's voice
   (`res/raw/dua_after_adhan_mishary.m4a`, bundled, the default) or Sheikh Al-Shaarawy's
   (`dua_after_adhan_shaarawy`, downloaded from the media repository when it is chosen, `docs/DECISIONS.md` D-064).
   Each can be heard on the Adhan page, the second from the network before it is downloaded. If the chosen one's
   file is gone, the bundled one plays.

Each part can be turned off on the Adhan page. iOS cannot play an adhan by itself: there the alert at prayer
time rings with the first 29.5 seconds of the bundled adhan (`assets/adhan/ios/adhan_regular.caf`), or of the
Fajr adhan at Fajr (`adhan_fajr.caf`), cut by the same build tool and bundled for iOS only (`docs/DECISIONS.md`
D-039).

## How the files are made

`tool/audio/adhan_sources.json` lists every recording: where it is downloaded from, its SHA-256, and
which part of it is used. `tool/audio/build_adhan_audio.py` downloads each once, refuses one whose SHA-256
differs, and then cuts and cleans every one the same way: rumble below 80 Hz removed, silence at both ends
removed (the adhan starts at once), loudness set to -16 LUFS with a true peak of -1.5 dBTP (measured, then
applied linearly), a short fade at each end, mono AAC without the source's tags. It writes the bundled
files to `android/app/src/main/res/raw` and the others to the media repository (`--media`), then
`assets/adhan/voices.json` with each file's size and SHA-256. Never edit those outputs by hand.

**Checked by listening by machine.** Each recording was transcribed with Whisper (`ggml-small`, Arabic) to
confirm what it says: every Fajr recording says "الصلاة خير من النوم" and no other one does, and the dua
clip is the dua. (This caught one: Mansoor Az-Zahrani's file is named as a plain adhan but is a Fajr adhan.)
**Listen to each once before a release.**

## The iqama phrase, and the voices of the reminders before a prayer

Short sounds, bundled (not downloaded), for the notice of the iqama and for the reminder before each prayer
(`docs/DECISIONS.md` D-063). They are made by the same tool and list (`tool/audio/adhan_sources.json`, kinds
`iqama` and `nearPrayer`), kept light (a few seconds each, 40 to 48 kb/s mono AAC; iOS 16 kHz), and are not in the voices
catalogue. They are real recordings of people, chosen because people already use them for this; none is synthesised.

| id | Bundled as | Source | Licence | Source SHA-256 | Used |
|---|---|---|---|---|---|
| `iqama_phrase` | `res/raw/iqama_phrase.m4a` (49,153 B, 9.1 s, SHA-256 `9bd53d3f…1e4de`); iOS `assets/adhan/ios/iqama_phrase.caf` (77,308 B) | Sheikh Majed Abbas, the iqama of Isha at the Grand Mosque in Makkah, 3 Dhu al-Qi'dah 1434 AH, [archive.org](https://archive.org/details/IqamaMakkahIsha3111434SheikhMajedAbbas) (uploaded by "the way of happiness") | **Permission pending** (the page shows none) | `f520980c…caf46b4` (746,496 B) | «قد قامت الصلاة» twice, 24.92 to 34.0 s of the source |

- **Checked by machine.** Whisper `ggml-small` with word times placed «قد قامت الصلاة» twice between «حي على الفلاح»
  and «الله أكبر»; on the cut itself it hears «قد قامة الصلاة» twice and nothing else. **Listen once before a
  release.** The permission to ask for is W1 in `docs/AUDIO_PENDING_LICENCES.md`.

### «اقتربت صلاة …»: one clip for each prayer

What the owner asked for: a real voice saying «اقتربت صلاة الفجر / الظهر / الجمعة / العصر / المغرب / العشاء», as
people already use it, in one voice. All six come from one zip on archive.org,
[item `20260909_20260909_2244`](https://archive.org/details/20260909_20260909_2244) («تنبيه قبل الصلاة», uploaded by
`aymangacem.k`, SHA-256 of the zip `eff9fa0b…85c1a7`), whose author is not named and which shows no licence:
**Permission pending**. Each clip is read out of the zip by its name (`zipEntry`) and checked by its own SHA-256
(`tool/audio/adhan_sources.json`, kind `nearPrayer`). The owner chose this voice after hearing the Friday clip; an
earlier set by another author (Egyptian pronunciation) was dropped.

| id | Bundled as | File in the zip | Its SHA-256 | Cut |
|---|---|---|---|---|
| `near_fajr` (Fajr) | `res/raw/prayer_near_fajr.m4a` (17,860 B, SHA-256 `6f1e9df5…c210da7`) | `fajrsoon.wav` | `4363b709…deced5d` | 1.17 to 4.65 s |
| `near_dhuhr` (Dhuhr) | `res/raw/prayer_near_dhuhr.m4a` (19,259 B, SHA-256 `9f734593…02567bc`) | `zohrsoon.wav` | `3cfcf25f…dbf4e5c` | 0.93 to 4.7 s |
| `near_jumuah` (Friday prayer) | `res/raw/prayer_near_jumuah.m4a` (18,253 B, SHA-256 `a6516aaa…77addbb`) | `gom3asoon.wav` | `5dfa7e62…4046a5f` | 0.0 to 3.55 s |
| `near_asr` (Asr) | `res/raw/prayer_near_asr.m4a` (18,495 B, SHA-256 `e18d1c7b…8f677d7`) | `asrsoon.wav` | `db6472ee…1ac866a` | 0.78 to 4.45 s |
| `near_maghrib` (Maghrib) | `res/raw/prayer_near_maghrib.m4a` (19,377 B, SHA-256 `50658bc5…a786d23`) | `maghribsoon.wav` | `f02f21dc…49c478b` | 0.77 to 4.5 s |
| `near_isha` (Isha) | `res/raw/prayer_near_isha.m4a` (18,599 B, SHA-256 `b212eddc…63108fd`) | `eshasoon.wav` | `a0ce9ede…8e63b56` | 0.67 to 4.15 s |

- **Checked by machine.** Whisper heard «اقتربت صلاة الفجر / العصر / المغرب / العشاء» exactly, Dhuhr's first word
  as «اختربت» in some runs, and the Friday prayer's only after loudness normalisation. **Listen to each once before a
  release.** No page says who the voice is: ask the uploader (W6 in `docs/AUDIO_PENDING_LICENCES.md`).
- **Size.** About 18 KB each at 40 kb/s mono AAC (3.3 to 3.5 s), 28 to 30 KB as an iOS sound at 16 kHz; with the
  iqama, about 160 KB on Android. All six are evened out to -21 LUFS. **Android.** Each notification channel plays its
  own sound (`ReminderChannel.sound`): the iqama's, and one for each of the six prayers; a channel keeps the sound it
  was made with, so the old `prayer_soon` channel is removed at start-up. **iOS.** The sounds are installed in
  `Library/Sounds` with the adhan's.

## Where the downloads are served from

The voices that are not bundled are downloaded, and previewed, from the media repository
(`https://elshoram974.github.io/mre_quran_global/adhan/<id>.m4a`, GitHub Pages, the cleaned files;
`AppConfig.mediaBase`), and from
**where each recording was found** (archive.org, or GitHub at a pinned commit) when that cannot be had. Each
file is checked against its own SHA-256. The media repository is the folder `mre_quran_global` beside this
repository (branch `global`); every new media file goes there; see its `README.md` and `LINKS.md`. Rebuild with `python3 tool/audio/build_adhan_audio.py
--cache <folder> --media ../mre_quran_global` (`--serve global` is the default).

## Voices

| id | Kind | Source | File SHA-256 | Bytes |
|---|---|---|---|---|
| `default` (bundled, `adhan_default.m4a`) | Adhan | Nasser Al-Qatami, [abodehq/Athan-MP3](https://github.com/abodehq/Athan-MP3/tree/cf1a9dd4f1e5e10009439099c5af74479ad332c0/Sounds); original `b30f4e2c…6b92fbe` | `d275029f…74cad298` | 1,080,038 |
| `default_fajr` (bundled, `adhan_fajr.m4a`) | Fajr | Mishary Rashid Alafasy, Maqam Hijaz, [archive.org](https://archive.org/details/adhan-call-to-prayer-mishary-rashid-alafasy-fajr-maqam-hijaz-hd-320-kbps-1) | `12dc0334…50ffea2` | 1,818,143 |
| dua (bundled, `dua_after_adhan_mishary.m4a`) | Dua | The same Mishary recording as `mishary_alafasy`, from 3:55 | `9fada8bd…f89647f4` | 143,511 |
| `dua_after_adhan_shaarawy` (downloaded) | Dua | Sheikh Al-Shaarawy, the whole first file of [his duas on archive.org](https://archive.org/details/AD3YA---SHEKH---METOLLYAL---SHA3RAWY---MP3---Qass--nabwy--MP3) (68 s, kept at 64 kb/s) | `d03e57bf…e268bc2` (562,360 B, cleaned); original `e23caaf9…bbaefb49` | 1,092,127 |
| `egypt_harak` | Adhan | Abdulnasser Harak, Egypt, [archive.org](https://archive.org/details/adhan-from-egypt-abdulnasser-harak) | `8183c49c…c14590b` (2,616,292 B, cleaned); original `38a60f60…0d4c648` | 4,323,885 |
| `mishary_alafasy` | Adhan | Mishary Rashid Alafasy, [archive.org](https://archive.org/details/VeryBeautifulAdhaanByMisharyAlAfasy), up to 3:51 | `fbacac1c…c889ca6` (2,828,271 B, cleaned); original `abba1e6a…b086a627` | 4,124,871 |
| `makkah_ali_mullah_fajr` | Fajr | Ali Mullah, the Grand Mosque, 6 Sep 2013, [archive.org](https://archive.org/details/MakkahFajrAdhan6913SheikhAliMullah) | `644c3b8a…817c25d` (2,936,610 B, cleaned); original `da68a481…b67a9ec` | 2,911,537 |
| `mansoor_zahrani_fajr` | Fajr | Mansoor Az-Zahrani, [abodehq/Athan-MP3](https://github.com/abodehq/Athan-MP3/tree/cf1a9dd4f1e5e10009439099c5af74479ad332c0/Sounds) | `b9cafb1b…848f764f` (2,245,065 B, cleaned); original `b4d596a8…f2a14f2` | 1,532,448 |
| `malek_chebae_fajr` | Fajr | Malek Chebae, [abodehq/Athan-MP3](https://github.com/abodehq/Athan-MP3/tree/cf1a9dd4f1e5e10009439099c5af74479ad332c0/Sounds) | `4e62f7e2…711c7b80` (2,960,608 B, cleaned); original `89580ee0…da318c6` | 2,008,922 |

The TVQuran.com spoken credit follows the closing shahada in the Al-Qatami, Az-Zahrani and Malek recordings. Their source cuts end in the intervening silence at 131.85, 183.55 and 243.00 seconds respectively. TVQuran.com remains in each in-app recording credit. Cropped voices play only their edited file, including Mishary’s regular adhan whose source continues into a separate dua.

The source files' own SHA-256 are in `tool/audio/adhan_sources.json`.

Looked at and left out: Mohammad Refaat and Abed Albase6 in Athan-MP3 (16 kb/s, too poor to use), the Wikimedia
Commons voices used before (uneven loudness and long silences; the old default was at -8.8 LUFS, close to
clipping), and "Adhan-Fajr-Afasy" on archive.org (19 seconds of silence before it starts).

## Licences to obtain before a release (the owner is handling them)

**None of these recordings has a licence yet.** Their catalogue entries say "Permission pending" and link the
page they came from. Uploaders on archive.org and GitHub gave no licence (except `egypt_harak`, marked Public
Domain Mark 1.0 by its uploader, which does not prove the muezzin agreed).

| What | Whose permission | Why |
|---|---|---|
| Nasser Al-Qatami: adhan (the bundled default) | Nasser Al-Qatami or his office | Bundled in the app: settle first |
| Mishary Alafasy: Fajr adhan and dua after the adhan (bundled), adhan (downloadable) | Mishary Rashid Alafasy or his office (his recordings are published commercially) | Bundled in the app: settle first |
| Mansoor Az-Zahrani: Fajr adhan | Mansoor Az-Zahrani or his office | Downloadable |
| Malek Chebae: Fajr adhan | Malek Chebae | Downloadable |
| Ali Mullah, live from the Grand Mosque | The General Authority for the Affairs of the Two Holy Mosques (it broadcasts the adhan), and the person who recorded it | Downloadable |
| Abdulnasser Harak | Abdulnasser Harak; confirm the Public Domain Mark | Downloadable |
| **Announcements** "حان الآن موعد أذان …" (fajr, dhuhr, asr, maghrib, isha, jumuah) | Whoever records them: best recorded for the app, by a voice artist who signs the rights over | Not found anywhere usable. Add as `res/raw/announce_<name>.m4a` through the build tool |
| **Sheikh Al-Shaarawy's dua after the adhan** (downloadable) | The rights holder of the recording (the broadcaster that produced it, or the Sheikh's heirs) | Taken from an archive.org upload with no licence. Its wording adds «والدرجة الرفيعة», which is not in Bukhari 614 |

When a licence arrives: put its name and link in the recording's entry in `tool/audio/adhan_sources.json`
(the build tool then writes it into the catalogue), and record the permission in `docs/PERMISSION_REQUESTS.md`.

## Other media made by the app's own code

- The home-screen widgets' preview images (`android/app/src/main/res/drawable-nodpi/*_preview.png` in
  English, `drawable-ar-nodpi/` in Arabic) are pictures of the widgets' own layouts, drawn by the app
  itself on an Android emulator with the layouts' sample text (`tool/capture_widget_previews.sh`, which
  runs the debug-only `WidgetPreviewCapture`). They contain no third-party artwork. Launchers that
  support it preview the widgets from their layouts directly.
