# Audio pending licences: the iqama reminder and the "prayer is near" sound

Two short recordings are wanted. **Nothing in this file is in the app yet**: no file is bundled, uploaded to
`mre_quran_global`, or listed in the catalogue.

1. **Iqama reminder voice.** Only «قد قامت الصلاة، قد قامت الصلاة» (the two-time line from the iqama, not the
   full iqama), male voice, mosque style, a few seconds. Played when the iqama time comes.
2. **"Prayer is near" sound.** Played with the reminder shown a few minutes before the adhan («اقتربت صلاة
   الظهر» and so on). Either a spoken line per prayer (fajr, dhuhr, asr, maghrib, isha) or one soft, plain
   tone (a gentle single bell or tone, no instruments, no music).

Searched on 2026-11-24: Wikimedia Commons, Openverse, Freesound, archive.org, and GitHub (the Athan-MP3
repository the adhan voices come from). Every licence quoted below was read on the page it names. Candidates were
downloaded only to hash and measure them, and the copies were deleted afterwards. "Checked by machine" means the
same Whisper `ggml-small` Arabic transcription used in `docs/AUDIO_SOURCES.md`: it is rough on a quiet or slow
recording, so **listen to each file once before anything is approved.**

**Result in one line.** No recording of the iqama phrase with an open licence was confirmed. No spoken
"اقتربت صلاة …" per-prayer recording with an open licence exists in what was searched. Soft single-tone chimes
under CC0 do exist.

## Usable once approved (explicit open licence)

All four entries below are CC0 1.0, so no credit is legally required; the suggested credit line is courtesy.
"Approved" here means the owner has listened to the file and accepted it.

### Iqama phrase: Commons `Iqamah.ogg` (content not confirmed)

| Field | Value |
|---|---|
| What | Possibly the iqama; **the page only says "Iqamah is the second call to prayer in islam"** |
| Title | `File:Iqamah.ogg` |
| Author | Aishatu98 ("own work", uploaded 15 July 2026; the user page says "I am Aishatu Abdulraheed") |
| Page | https://commons.wikimedia.org/wiki/File:Iqamah.ogg |
| Direct file | https://upload.wikimedia.org/wikipedia/commons/0/00/Iqamah.ogg |
| Licence | Creative Commons CC0 1.0 Universal Public Domain Dedication, https://creativecommons.org/publicdomain/zero/1.0/deed.en ("This file is made available under the Creative Commons CC0 1.0 Universal Public Domain Dedication") |
| Suggested credit | "Iqamah.ogg, Aishatu98, Wikimedia Commons, CC0 1.0" |
| Duration, format | 93.0 s, Ogg Vorbis, mono, 44.1 kHz, 64 kbps |
| Size | 748,447 bytes |
| SHA-256 | `7d59b950c0eeecfb56add706644ce2506c3c484a5fc3635a18db1b7b1a3721af` |
| Caveats | The machine transcript did **not** recognise «قد قامت الصلاة»: it heard only «الله … أشهد» repeated, with a phrase every 6 to 10 s, which sounds more like a slow adhan than an iqama. Very quiet (-30.1 LUFS). The reciter, the place and the original source are not stated, and "own work" cannot be checked, so the uploader may not hold the rights of the voice (see W3). Would need trimming and normalising even if it is an iqama. |

### Near-prayer sound, spoken: Commons `Adhan.ogg` (content not confirmed)

| Field | Value |
|---|---|
| What | Described as "Adhan announcement that prayer is about to start". Not per prayer; it may simply be an adhan |
| Title | `File:Adhan.ogg` |
| Author | Aishatu98 (same uploader and date as the file above) |
| Page | https://commons.wikimedia.org/wiki/File:Adhan.ogg |
| Direct file | https://upload.wikimedia.org/wikipedia/commons/e/e7/Adhan.ogg |
| Licence | Creative Commons CC0 1.0 Universal Public Domain Dedication, http://creativecommons.org/publicdomain/zero/1.0/deed.en |
| Suggested credit | "Adhan.ogg, Aishatu98, Wikimedia Commons, CC0 1.0" |
| Duration, format | 42.1 s, Ogg Vorbis, mono, 44.1 kHz, 64 kbps |
| Size | 338,741 bytes |
| SHA-256 | `faeb03e4338554fb8b54dba98ed4949648615b58e991bbd560a89f4837dde413` |
| Caveats | The machine transcript was unintelligible. 42 s is too long for a "prayer is near" cue, and it names no prayer. Same provenance doubt as above (W3). Do not use it unless listening shows it is a clean spoken or sung reminder. |

### Near-prayer sound, tone: Freesound "Soft-Notifications - Bell - LowDing.mp3"

| Field | Value |
|---|---|
| What | One short soft bell strike, a plain single tone (the uploader: "sounds like an oldschool elevator arrival bell ding") |
| Title | Soft-Notifications - Bell - LowDing.mp3 |
| Author | LegitCheese (uploaded 16 May 2021) |
| Page | https://freesound.org/people/LegitCheese/sounds/571511/ |
| Direct file | Freesound serves the original only after a login. The public preview (a re-encode, not the original) is https://cdn.freesound.org/previews/571/571511_2226836-hq.mp3 |
| Licence | "Creative Commons 0", http://creativecommons.org/publicdomain/zero/1.0/ |
| Suggested credit | "Soft-Notifications - Bell - LowDing, LegitCheese, freesound.org, CC0 1.0" |
| Duration, format | 0.68 s; page: MP3, 24 kHz, 102 kbps, stereo, 8.6 KB |
| Size and SHA-256 | Preview file, 11,880 bytes, `b148e9cee83f5b56628db9846b49bcb4a8b5b18de455637338a5014f879ab443`. **The original differs: download it while logged in and hash that one.** |
| Caveats | Very quiet (preview -40.9 LUFS, peak -29.9 dBFS), so it needs gain. Low sample rate. The most "plain" of the candidates, but it sounds like a lift bell, not a religious tone. |

### Near-prayer sound, tone: Freesound "Bell rings timidly.wav"

| Field | Value |
|---|---|
| What | A small bronze bell rings softly, three times (the uploader's description); use the first strike only, with its decay |
| Title | Bell rings timidly.wav |
| Author | Fenodyrie (uploaded 18 August 2021; "Recorded on Zoom H2, Stereo, 48.000 Hz, 24bit") |
| Page | https://freesound.org/people/Fenodyrie/sounds/583947/ |
| Direct file | Original only after a Freesound login. Public preview (a re-encode): https://cdn.freesound.org/previews/583/583947_6371307-hq.mp3 |
| Licence | "Creative Commons 0", http://creativecommons.org/publicdomain/zero/1.0/ |
| Suggested credit | "Bell rings timidly, Fenodyrie, freesound.org, CC0 1.0" |
| Duration, format | 11.3 s; page: WAV, 48 kHz, 24 bit, stereo, 3.1 MB |
| Size and SHA-256 | Preview file, 242,208 bytes, `418dd2a73f5cac030d9ae8e8dd1250a6c5c215e4614b130dbb9d9ad11ec1f57d`. **Hash the original once downloaded.** |
| Caveats | Needs cutting to one strike (about 2 to 3 s) and a fade. Better quality and warmer than the one above; still a bell, so confirm the owner finds it appropriate. |

## Waiting for the owner's permission

The adhan, dua and announcement items already pending are in `docs/AUDIO_SOURCES.md`, section "Licences to
obtain before a release"; they are not repeated here. When a reply arrives, record it in
`docs/PERMISSION_REQUESTS.md` as that section says.

| # | What | Who to ask | Record once granted |
|---|---|---|---|
| W1 | **Best real-mosque match for the iqama phrase.** Archive.org item `IqamaMakkahIsha3111434SheikhMajedAbbas`, "Iqama - Makkah Isha [3-11-1434] Sheikh Majed Abbas" (the Grand Mosque, 2013). The machine transcript recognises «حي على الصلاة، حي على الفلاح، قد قامت الصلاة، قد قامت الصلاة، الله أكبر …»; the two «قد قامت الصلاة» lines fall at about 25.5 to 34.2 s of 46.6 s. 746,496 bytes, MP3, SHA-256 `f520980cfcf218b3ffd54a3bf45331cef0dae874d22a36faee207f634caf46b4`. Page: https://archive.org/details/IqamaMakkahIsha3111434SheikhMajedAbbas . The page shows **no licence**. Same family (Makkah, 2013; the archive.org metadata of each shows no licence, their pages were not opened): `IqamaMakkahIsha1111434SheikhFaroukHadrawi`, `IqamaMakkahFajr3111434SheikhAhmadBasnawi`. | The General Authority for the Affairs of the Two Holy Mosques (it broadcasts the iqama) and the muezzin, Sheikh Majed Abbas or his office; the archive.org uploader ("the way of happiness", creator tag HalawatAlIman) only for where the recording came from | Permission text and date, who granted it, the credit wording they want, the cut used (start and end seconds), SHA-256 of the cut file |
| W2 | **Best technical match, but share-alike.** Commons `File:Iqama during Ramadan.wav` (see "Not recommended"). Ask the uploader to dual-license it CC0 or CC BY 4.0, and say where and who recorded it | The uploader, DaSupremo, on the Commons talk page `User_talk:DaSupremo` | Link to the reply, the new licence name and URL, the muezzin's name or "unknown" |
| W3 | **Provenance of `Iqamah.ogg` and `Adhan.ogg`** (CC0 above): who recorded them, where, in which words, and whether the reciter or mosque agrees to a CC0 release | The uploader, Aishatu98, on the Commons talk page `User_talk:Aishatu98` | Link to the reply; the names of the reciter and the place |
| W4 | A 2 s «اقتربت الصلاة» tone (`eqtrabt_elsalat_2.mp3`, 48,992 bytes, SHA-256 `169c77e1749bf89c22719ee3846b25dbe580a0e2d55923a1689a88f85cc391fd`) and a 15 s «حان الآن وقت الصلاة» clip (`eqtrabt_elsalat_1_01.mp3`, 401,971 bytes, not downloaded) in archive.org item `eqtrabt_elsalat_2_202508`, uploaded 8 Aug 2025, described as "نغمة صوتية اقتربت الصلاة" (a ringtone). **No licence, and the voice is not named.** Machine transcript of the 2 s file was unintelligible, so its wording is unconfirmed. Page: https://archive.org/details/eqtrabt_elsalat_2_202508 | The uploader (shown as Al3osemy) for the licence and for who the voice is; then that voice | Licence, voice's name, credit wording |
| W5 | **Record both for the app** (the fallback that settles everything): the iqama phrase and the five «اقتربت صلاة …» lines | A voice artist (a muezzin or reciter) with a signed rights assignment; best done in the same session as the announcements «حان الآن موعد أذان …» already listed in `docs/AUDIO_SOURCES.md` | Contract or signed release, the artist's name and credit wording, SHA-256 of the delivered masters |

Ready-to-send wording. Fill the `[brackets]`; keep every reply.

**W1.** "Assalamu alaykum. I develop [app name], an Arabic Quran and prayer-times app for Android and iOS. I would
like to use about nine seconds of the iqama recording «Iqama - Makkah Isha [3-11-1434] Sheikh Majed Abbas»
(https://archive.org/details/IqamaMakkahIsha3111434SheikhMajedAbbas): only the two phrases «قد قامت الصلاة،
قد قامت الصلاة», as a reminder sound when the iqama time comes. The words would not be changed; I would only trim
the clip and level its volume, and the app would credit the muezzin and the Authority as you ask. May I have your
written permission to reproduce and distribute this clip inside the app, worldwide, including on app stores,
and the wording of the credit you want? If you prefer that it is not used, I will not use it. [Name, contact]"

**W2.** "Hello, and thank you for recording «Iqama during Ramadan» (Commons, CC BY-SA 4.0). I develop [app name], an
Arabic prayer-times app for Android and iOS, and would like to use about four seconds of it (the two «قد قامت
الصلاة» phrases). Share-alike makes that hard to ship in an app. Would you be willing to release this recording
under CC0 1.0 (or CC BY 4.0) instead? Could you also tell me where it was recorded and who the muezzin is, and
confirm that you and he agree? I will credit you as you wish. [Name, contact]"

**W3.** "Hello, and thank you for uploading «Iqamah.ogg» and «Adhan.ogg» under CC0. Before I use them in [app name],
an Arabic prayer-times app, could you tell me who recorded them, where, and which words they contain, and confirm
that the reciter (and the mosque, if it was recorded there) agrees to a CC0 release? [Name, contact]"

**W4.** "Assalamu alaykum. I would like to use your audio «اقتربت الصلاة» (archive.org item eqtrabt_elsalat_2_202508)
in [app name], an Arabic prayer-times app, as the sound shown a few minutes before the adhan. The page shows no
licence. May I have your written permission to reproduce and distribute it in the app, including on app stores?
Whose voice is it, and did he agree to this use? What credit would you like? [Name, contact]"

**W5.** "We need two short recordings for [app name], an Arabic prayer-times app: (1) «قد قامت الصلاة، قد قامت
الصلاة», male voice, mosque style, about 4 to 6 seconds; (2) «اقتربت صلاة الفجر / الظهر / العصر / المغرب /
العشاء», one file per prayer, calm voice, about 3 seconds each. We ask for a signed, perpetual, worldwide,
all-media assignment or a CC0 release, including app stores, with the right to trim, level and re-encode. Please
confirm the voice is yours and that the recording is not taken from a broadcast or another recording, and tell us
the credit line you want, if any. [Name, contact]"

## Not recommended

| Candidate | Licence as shown on its page | Why not |
|---|---|---|
| Commons `File:Iqama during Ramadan.wav`, DaSupremo, 5 Mar 2026, https://commons.wikimedia.org/wiki/File:Iqama_during_Ramadan.wav , direct https://upload.wikimedia.org/wikipedia/commons/4/43/Iqama_during_Ramadan.wav , WAV 48 kHz stereo, 19.7 s, 3,784,782 bytes, SHA-256 `3738674b648655b8c1d6d8f754a2e4cfac7ea6ba3599aa943d6851bebd64a0b4` | "This file is licensed under the Creative Commons Attribution-Share Alike 4.0 International license." https://creativecommons.org/licenses/by-sa/4.0 | **Share-alike.** A trimmed clip is an adaptation, which BY-SA requires to be shared under BY-SA; awkward for an app on Google Play and the App Store. Technically it is the best open match: the machine transcript recognises «حي على الصلاة، حي على الفلاح، قد قامت الصلاة (twice), الله أكبر الله أكبر لا إله إلا الله», with the two phrases at about 6.3 to 10.6 s, at -22.0 LUFS (peak -8.0 dBFS). Fixing the licence is W2. |
| Commons `Athan in Ramadan.wav` (DaSupremo) and `The Adhan - Muslim Call to Prayer - Aaqib Azeez.mp3` (Atcovi) | Both pages: "This file is licensed under the Creative Commons Attribution-Share Alike 4.0 International license." | Adhans, not the wanted recordings, and share-alike. |
| archive.org `IqamatInTongiIjtema2015_201501` (49.7 s, 1,197,781 bytes, SHA-256 `ecac06382e55fd9df581c1b0b614f2cadd0595ca27340c36745b3ee44b3534fc`, https://archive.org/details/IqamatInTongiIjtema2015_201501) and `CopyOfRaiwindIqamat` (99.7 s, 1,596,416 bytes, SHA-256 `240a5a987b3af4e63f0d7590efa7621b91050af8156908c327ae719f326820b6`, https://archive.org/details/CopyOfRaiwindIqamat) | Both pages: "Usage: Public Domain Mark 1.0" | The mark was set by the uploader on a recording of a living muezzin at a Tablighi gathering, the same weakness as `egypt_harak` in `docs/AUDIO_SOURCES.md` (it does not prove the muezzin agreed). Also 50 to 100 s long. Their machine transcripts did not show «قد قامت الصلاة». |
| archive.org `iqamah_athan` / `iqamah.mp3` (51.1 s, 306,886 bytes, SHA-256 `47b9845868dd25a80664238ba5380656e99c644a640ae22d53767499bfaaada3`, "اقامة الصلاة في الحرم المكي") | Page shows no licence | No licence, and the machine transcript was unintelligible. W1 is the better Makkah file. |
| GitHub `abodehq/Athan-MP3` | The page shows no LICENSE file or licence entry | It has no iqama recording (the adhan voices only). |
| Freesound and Openverse search for "iqama" / "iqamah" | n/a | Freesound shows "0 sounds" for "iqama" and "iqamah". Openverse returns only the Commons file above and a one-second Lingua Libre recording of the word "iqama" (not opened). No usable iqama or spoken near-prayer recording exists there. |

## If nothing suitable exists

Plainly: **no open-licence recording of the iqama phrase was verified, and none of the spoken per-prayer
announcements exists**, so the options are:

- (a) Commission or record a short phrase and release it CC0 (W5). This is the clean answer for both kinds and
  matches the plan already written for the announcements in `docs/AUDIO_SOURCES.md`.
- (b) Use a synthesised voice only if the tool's licence allows redistributing its output inside an app and
  states that in writing; keep the licence text and the tool and version beside the file. A synthesised voice
  for «قد قامت الصلاة» will not sound like a muezzin.
- (c) Ship a plain system notification sound (no file added, nothing to license). For the "prayer is near" cue, the
  CC0 chime above is the only addition that is clearly licensed today.

## Checklist before adding any of these to the app

1. Listen to the file once; confirm the words, the voice and the loudness.
2. Get the licence or permission in writing (links, screenshots or the reply); record it in
   `docs/PERMISSION_REQUESTS.md`.
3. Record source, licence name and URL, author, attribution text and the SHA-256 of the source file in
   `docs/AUDIO_SOURCES.md`, and in `tool/audio/adhan_sources.json` if the build tool makes the file.
4. Cut and clean it the same way as the other recordings (trim, level, mono AAC) and compute the SHA-256 of the
   result.
5. Upload the cleaned file to `mre_quran_global` (branch `global`; update its `README.md` and `LINKS.md`), then
   add its SHA-256 to the app catalogue. Keep the original source only as a fallback.
6. Show the attribution in the app, where the other audio credits are shown, even for CC0.
7. Keep every outside address in `lib/core/config/app_config.dart`; add no hard-coded URL.
