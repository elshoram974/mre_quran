# Audio sources: the adhan

What plays at prayer time, in order (Android, `AdhanAudio.steps`):

1. **The announcement** of the prayer: "حان الآن موعد أذان الظهر" (`res/raw/announce_<prayer>.m4a`,
   `announce_jumuah` on Fridays). **No recording yet** (see the licence list below); until one is added
   the step is skipped, and nothing else changes.
2. **The adhan**: the chosen voice, and at Fajr the chosen *Fajr* voice, which says "الصلاة خير من النوم".
3. **The dua after the adhan**, "اللهم رب هذه الدعوة التامة…" (Bukhari 614), `res/raw/dua_after_adhan.m4a`.

Each part can be turned off on the Adhan page. iOS cannot play an adhan by itself; there the alert is a
notification (an iOS notification sound is 30 seconds at most).

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

The voices that are not bundled are downloaded on demand from the media repository, tagged and served by
jsDelivr: `https://cdn.jsdelivr.net/gh/elshoram974/mushafi-media@v1/adhan/<id>.m4a`. Publish it as
`app_assets/README.md` says. Until the tag exists, those downloads fail and the bundled voices still work.

## Voices

| id | Kind | Source | File SHA-256 | Bytes |
|---|---|---|---|---|
| `default` (bundled, `adhan_default.m4a`) | Adhan | Mishary Rashid Alafasy, [archive.org](https://archive.org/details/VeryBeautifulAdhaanByMisharyAlAfasy), up to 3:51 | `ab1ffab2…ff40f88` | 1,895,196 |
| `default_fajr` (bundled, `adhan_fajr.m4a`) | Fajr | Mishary Rashid Alafasy, Maqam Hijaz, [archive.org](https://archive.org/details/adhan-call-to-prayer-mishary-rashid-alafasy-fajr-maqam-hijaz-hd-320-kbps-1) | `12dc0334…50ffea2` | 1,818,143 |
| dua (bundled, `dua_after_adhan.m4a`) | Dua | The same Mishary recording as `default`, from 3:55 | `9fada8bd…f89647f4` | 143,511 |
| `egypt_harak` | Adhan | Abdulnasser Harak, Egypt, [archive.org](https://archive.org/details/adhan-from-egypt-abdulnasser-harak) | `8183c49c…c14590b` | 2,616,292 |
| `nasser_alqatami` | Adhan | Nasser Al-Qatami, [abodehq/Athan-MP3](https://github.com/abodehq/Athan-MP3/tree/cf1a9dd4f1e5e10009439099c5af74479ad332c0/Sounds) | `600b972b…580df97` | 1,697,947 |
| `makkah_ali_mullah_fajr` | Fajr | Ali Mullah, the Grand Mosque, 6 Sep 2013, [archive.org](https://archive.org/details/MakkahFajrAdhan6913SheikhAliMullah) | `644c3b8a…817c25d` | 2,936,610 |
| `mansoor_zahrani_fajr` | Fajr | Mansoor Az-Zahrani, [abodehq/Athan-MP3](https://github.com/abodehq/Athan-MP3/tree/cf1a9dd4f1e5e10009439099c5af74479ad332c0/Sounds) | `8c231212…ade6506` | 2,334,044 |
| `malek_chebae_fajr` | Fajr | Malek Chebae, [abodehq/Athan-MP3](https://github.com/abodehq/Athan-MP3/tree/cf1a9dd4f1e5e10009439099c5af74479ad332c0/Sounds) | `8df72cb6…d7ca603` | 3,047,630 |

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
| Mishary Alafasy: adhan, Fajr adhan, dua after the adhan (all three bundled) | Mishary Rashid Alafasy or his office (his recordings are published commercially) | Bundled in the app: the most important to settle first |
| Nasser Al-Qatami: adhan | Nasser Al-Qatami or his office | Downloadable |
| Mansoor Az-Zahrani: Fajr adhan | Mansoor Az-Zahrani or his office | Downloadable |
| Malek Chebae: Fajr adhan | Malek Chebae | Downloadable |
| Ali Mullah, live from the Grand Mosque | The General Authority for the Affairs of the Two Holy Mosques (it broadcasts the adhan), and the person who recorded it | Downloadable |
| Abdulnasser Harak | Abdulnasser Harak; confirm the Public Domain Mark | Downloadable |
| **Announcements** "حان الآن موعد أذان …" (fajr, dhuhr, asr, maghrib, isha, jumuah) | Whoever records them: best recorded for the app, by a voice artist who signs the rights over | Not found anywhere usable. Add as `res/raw/announce_<name>.m4a` through the build tool |
| **Sheikh Al-Shaarawy's dua after the adhan** | The rights holder of the recording (the broadcaster that produced it, or the Sheikh's heirs) | Not downloaded: it is only on video sites, whose terms forbid it. When permission and the file are in hand, add it as a second `dua` recording in the sources file |

When a licence arrives: put its name and link in the recording's entry in `tool/audio/adhan_sources.json`
(the build tool then writes it into the catalogue), and record the permission in `docs/PERMISSION_REQUESTS.md`.

## Other media made by the app's own code

- The home-screen widgets' preview images (`android/app/src/main/res/drawable-nodpi/*_preview.png` in
  English, `drawable-ar-nodpi/` in Arabic) are pictures of the widgets' own layouts, drawn by the app
  itself on an Android emulator with the layouts' sample text (`tool/capture_widget_previews.sh`, which
  runs the debug-only `WidgetPreviewCapture`). They contain no third-party artwork. Launchers that
  support it preview the widgets from their layouts directly.
