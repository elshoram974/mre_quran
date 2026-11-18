# Audio sources: the adhan

What plays at prayer time, in order (Android, `AdhanAudio.steps`):

1. **The announcement** of the prayer: "حان الآن موعد أذان الظهر" (`res/raw/announce_<prayer>.m4a`,
   `announce_jumuah` on Fridays). **No recording yet** (see the licence list below). The Adhan page offers the
   choice only once all six are in the app; until then the step is skipped.
2. **The adhan**: the chosen voice, and at Fajr the chosen *Fajr* voice, which says "الصلاة خير من النوم".
3. **The dua after the adhan**, "اللهم رب هذه الدعوة التامة…" (Bukhari 614), in Sheikh Al-Shaarawy's voice
   (`res/raw/dua_after_adhan_shaarawy.m4a`, the default) or Sheikh Mishary Alafasy's
   (`res/raw/dua_after_adhan_mishary.m4a`). Each can be heard on the Adhan page.

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
files to `android/app/src/main/res/raw` and the others to `app_assets/media`, then
`assets/adhan/voices.json` with each file's size and SHA-256. Never edit those outputs by hand.

**Checked by listening by machine.** Each recording was transcribed with Whisper (`ggml-small`, Arabic) to
confirm what it says: every Fajr recording says "الصلاة خير من النوم" and no other one does, and the dua
clip is the dua. (This caught one: Mansoor Az-Zahrani's file is named as a plain adhan but is a Fajr adhan.)
**Listen to each once before a release.**

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
| `default` (bundled, `adhan_default.m4a`) | Adhan | Nasser Al-Qatami, [abodehq/Athan-MP3](https://github.com/abodehq/Athan-MP3/tree/cf1a9dd4f1e5e10009439099c5af74479ad332c0/Sounds); original `b30f4e2c…6b92fbe` | `3e5c8af7…1364273` | 1,138,523 |
| `default_fajr` (bundled, `adhan_fajr.m4a`) | Fajr | Mishary Rashid Alafasy, Maqam Hijaz, [archive.org](https://archive.org/details/adhan-call-to-prayer-mishary-rashid-alafasy-fajr-maqam-hijaz-hd-320-kbps-1) | `12dc0334…50ffea2` | 1,818,143 |
| dua (bundled, `dua_after_adhan_mishary.m4a`) | Dua | The same Mishary recording as `mishary_alafasy`, from 3:55 | `9fada8bd…f89647f4` | 143,511 |
| dua (bundled, `dua_after_adhan_shaarawy.m4a`) | Dua | Sheikh Al-Shaarawy, the whole first file of [his duas on archive.org](https://archive.org/details/AD3YA---SHEKH---METOLLYAL---SHA3RAWY---MP3---Qass--nabwy--MP3) (68 s) | `d03e57bf…e268bc2` | 562,360 |
| `egypt_harak` | Adhan | Abdulnasser Harak, Egypt, [archive.org](https://archive.org/details/adhan-from-egypt-abdulnasser-harak) | `8183c49c…c14590b` (2,616,292 B, cleaned); original `38a60f60…0d4c648` | 4,323,885 |
| `mishary_alafasy` | Adhan | Mishary Rashid Alafasy, [archive.org](https://archive.org/details/VeryBeautifulAdhaanByMisharyAlAfasy), up to 3:51 | `fbacac1c…c889ca6` (2,828,271 B, cleaned); original `abba1e6a…b086a627` | 4,124,871 |
| `makkah_ali_mullah_fajr` | Fajr | Ali Mullah, the Grand Mosque, 6 Sep 2013, [archive.org](https://archive.org/details/MakkahFajrAdhan6913SheikhAliMullah) | `644c3b8a…817c25d` (2,936,610 B, cleaned); original `da68a481…b67a9ec` | 2,911,537 |
| `mansoor_zahrani_fajr` | Fajr | Mansoor Az-Zahrani, [abodehq/Athan-MP3](https://github.com/abodehq/Athan-MP3/tree/cf1a9dd4f1e5e10009439099c5af74479ad332c0/Sounds) | `8c231212…ade6506` (2,334,044 B, cleaned); original `b4d596a8…f2a14f2` | 1,532,448 |
| `malek_chebae_fajr` | Fajr | Malek Chebae, [abodehq/Athan-MP3](https://github.com/abodehq/Athan-MP3/tree/cf1a9dd4f1e5e10009439099c5af74479ad332c0/Sounds) | `8df72cb6…d7ca603` (3,047,630 B, cleaned); original `89580ee0…da318c6` | 2,008,922 |

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
| **Sheikh Al-Shaarawy's dua after the adhan** (bundled) | The rights holder of the recording (the broadcaster that produced it, or the Sheikh's heirs) | Taken from an archive.org upload with no licence. Its wording adds «والدرجة الرفيعة», which is not in Bukhari 614 |

When a licence arrives: put its name and link in the recording's entry in `tool/audio/adhan_sources.json`
(the build tool then writes it into the catalogue), and record the permission in `docs/PERMISSION_REQUESTS.md`.

## Other media made by the app's own code

- The home-screen widgets' preview images (`android/app/src/main/res/drawable-nodpi/*_preview.png` in
  English, `drawable-ar-nodpi/` in Arabic) are pictures of the widgets' own layouts, drawn by the app
  itself on an Android emulator with the layouts' sample text (`tool/capture_widget_previews.sh`, which
  runs the debug-only `WidgetPreviewCapture`). They contain no third-party artwork. Launchers that
  support it preview the widgets from their layouts directly.
