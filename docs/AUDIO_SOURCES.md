# Audio sources: adhan voices

The app has no recording of its own. Each voice is a file from Wikimedia Commons. One is bundled as the default
(CC0). The rest are streamed for a preview **only when the person taps Play** and kept on the phone **only when
they tap Download**; each kept file is checked against its SHA-256 before it is saved. A preview is not checked (it is
never saved), so it can differ from the catalogue if Commons replaces the file; the download then fails the check.

The catalogue is `assets/adhan/voices.json` (schema 1). Adding or removing a voice never needs a code change. A test
fails when a voice has no licence, credit, source page, https URL or 64-character SHA-256.

## What the licences ask for

| Licence | What the app does about it |
|---|---|
| CC0 1.0 | Nothing is required. Credit is shown anyway. |
| CC BY 3.0 | The credit and the licence link are shown in the voice's information sheet. The file is not changed. |
| CC BY-SA 4.0 | Same. The file is passed on **unmodified**, so the share-alike condition does not reach the app. Do not trim or re-encode these files. |

## Voices

| id | Source page | File SHA-256 | Size | Licence | Credit |
|---|---|---|---|---|---|
| `default` (bundled as `android/app/src/main/res/raw/adhan_default.ogg`) | [Beautiful adhan.ogg](https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg) | `35fe06b0…f5b2a79` | 1,229,032 | CC0 1.0 | Adam-synagda |
| `makkah` | [Adhan, Great Mosque of Mecca, 21 Jan 2013](https://commons.wikimedia.org/wiki/File:Adhan,_Great_Mosque_of_Mecca_-_Jan_21,_2013.webm) | `f4acc1bc…91eb5f0` | 9,359,941 | CC BY 3.0 | Seyfula Islam |
| `madinah` | [Call to prayer from the Prophet's Mosque](https://commons.wikimedia.org/wiki/File:33937_ejaz215_call-to-prayer-from-the-prophet-s-mo.ogg) | `4d0fabe0…202d656` | 2,974,689 | CC BY 3.0 | ejaz215 (Freesound) |
| `aaqib_azeez` | [The Adhan, Aaqib Azeez](https://commons.wikimedia.org/wiki/File:The_Adhan_-_Muslim_Call_to_Prayer_-_Aaqib_Azeez.mp3) | `0faa59e2…99000c1b3` | 1,448,294 | CC BY-SA 4.0 | Atcovi |
| `azan_andrewler` | [Azan.ogg](https://commons.wikimedia.org/wiki/File:Azan.ogg) | `2163ceaf…b9b23c3` | 1,473,809 | CC BY-SA 4.0 | Andrewler |

Checked on 2026-10-09: the SHA-1 of each file I downloaded equals the SHA-1 Commons reports for it.
The full SHA-256 of every file is in `assets/adhan/voices.json`.

## Limits of this evidence (read before shipping)

- **The licence is the uploader's statement on Commons.** Commons does not prove that the person who uploaded a
  recording of a live adhan held every right in it. For the two mosque recordings (`makkah`, `madinah`) the licence
  was given by the person who filmed or recorded it; nothing here shows the mosque authority, a broadcaster or the
  muezzin agreed. If that matters to the store listing or to the community, ask first (template in
  `docs/PERMISSION_REQUESTS.md`, Request 3).
- `makkah` is the audio of a video file (WebM), 9 MB. The app plays only the sound.
- The muezzin is **not named** for any of these. The app does not claim a name it cannot show evidence for.
- Voices of well-known muezzins (for example the Haramain muezzins or famous reciters) were looked for and **not
  added**: none had a free licence. They can be added to the catalogue the day written permission exists, with the
  same fields. Meanwhile a person can pick any audio file from their own phone as the adhan (see the Adhan page).
- Considered and left out: "Call to prayer by Sabah Fakhry" (marked public domain on Commons; a 1985 recording, so
  that claim is doubtful), "Oración Al-Azzan" (30 s, public-domain claim by the uploader), "Llamada a oración Mezquita
  Hassan II" (31 MB WAV with street noise), and Cambridge's Cairo recordings (CC BY-NC-ND: no redistribution of
  changes, non-commercial only).

## Wikimedia's rules for downloads

Files are fetched from `upload.wikimedia.org` with a descriptive `User-Agent`, only after a tap, one at a time.
Previews stream the same URL. If
many people download, host the files yourself (same bytes, same SHA-256) and change the `url` fields.

## Other media made by the app's own code

- The two home-screen widget preview images (`android/app/src/main/res/drawable-nodpi/prayer_widget_preview.png`,
  `prayer_schedule_widget_preview.png`) are screenshots of the app's own widgets on an emulator. They contain no
  third-party artwork.
