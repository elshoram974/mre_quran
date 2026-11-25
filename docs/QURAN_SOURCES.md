# Quran content sources

Only the Tanzil files in section 6 are bundled. Everything else here is research and
stays out of the repo. Each source needs the owner's approval, a recorded
licence, and a SHA-256 before it enters the repo (see `AGENTS.md`, "Quran content").

## 1. Quran text

| Option | Terms found | Verdict |
|---|---|---|
| [Tanzil](https://tanzil.net/docs/quran_text_types) Uthmani (Medina Mushaf, Hafs) | CC BY 3.0. Copy and distribute verbatim only, no changes. Credit Tanzil.net and link to tanzil.net. Keep the copyright notice in every copy. | **Clear. Use it.** |

Tanzil's [Medina Mushaf page](https://tanzil.net/docs/medina_mushaf) states the text follows the Medina Mushaf (Hafs) but says
nothing about page or line layout. I did not confirm whether its metadata file carries page breaks.

## 2. Page layout (which words sit on which page and line)

Exact Madinah layout needs line-by-line data. Tanzil text alone cannot give it.

| Option | What it offers | Open question |
|---|---|---|
| [QUL by Tarteel](https://qul.tarteel.ai/resources/quran-script/47) | Downloadable JSON/SQLite: Madinah Mushaf (1441 H) V4 glyph text with page, juz, hizb data and layouts | The resource page links "Terms of use" but states no licence. Read and record them first. |
| [Quran Foundation API](https://api-docs.quran.foundation/legal/mushaf-fonts-and-images/) | Mushaf fonts and page images through its API and CDN | Needs a Developer Console account. See section 3. |

## 3. Mushaf fonts (for the light, no-image mode)

| Option | Terms found | Verdict |
|---|---|---|
| KFGQPC fonts from [fonts.qurancomplex.gov.sa](https://fonts.qurancomplex.gov.sa/wp02/en/?p=19) (Uthmanic Hafs, QCF v1/v2/v4) | [Licence text](https://scancode-licensedb.aboutcode.org/kfgqpc-uthmanic-script-hafs.LICENSE): property of King Fahd Glorious Quran Printing Complex, "may not be reproduced, modified without the express written approval". | **Bundling is not clearly allowed.** Needs written approval from KFGQPC. |
| QCF v4 (third-party package) | Madinah Mushaf (1441 H), grouped into about 47 files ([quran-qcf4](https://cdn.jsdelivr.net/npm/quran-qcf4@1.1.0/README.md)). Quran Foundation's own V4 Tajweed is per-page (604 fonts), not 47. | Same licence question as above. Not the same thing as Quran Foundation's V4. |
| QCF V1 / V2 per-page fonts | One TTF per page. Sample sizes from HEAD requests: V1 about 90 KB per page (about 55 MB total), V2 about 370 KB per page (about 220 MB total) | Too heavy to bundle. Possible on-demand download pack. |
| QPC Hafs / Uthmani (Unicode) | One font for the whole Quran, [recommended by Quran Foundation for mobile](https://api-docs.quran.foundation/docs/tutorials/fonts/font-rendering/) | **Default light mode.** Needs bundling permission. |
| Fonts via Quran Foundation | [Developer terms](https://api-docs.quran.foundation/legal/mushaf-fonts-and-images/) allow bundling fonts and Mushaf images obtained through its APIs or documented CDN URLs if: you keep an active Developer Console account, credit Quran Foundation in the app, and ship them only as part of the app (no separate download or API). | Terms do not name QCF v1/v2/v4. Confirm with developers@quran.com. |

## 4. Recommended path

1. **Text:** Tanzil Uthmani, unmodified, with the required attribution.
2. **Layout and fonts:** get written confirmation for one channel, in this order:
   Quran Foundation (they publish bundling terms), then written approval from KFGQPC.
3. **Light mode first:** one bundled Unicode font (QPC Hafs) with line breaks from the layout data. No images.
4. **Optional pack:** QCF V1 page fonts (about 90 KB per page) downloaded on demand, never bundled.
5. **Images later, one pack at a time:** same Quran Foundation terms, downloaded on demand, never bundled.
5. **Fallback if neither approves:** render Tanzil text with a single KFGQPC Hafs font and our own pagination.
   This is not the exact Madinah page layout, and it still needs KFGQPC's permission to bundle.

Decisions needed from the project owner:

- Which channel to ask first (Quran Foundation or KFGQPC), and who sends the request.
- Approval to read and record QUL's terms.
- Whether the fallback layout is acceptable if exact layout is not approved.

## 5. Duas and adhkar

Morning and evening adhkar come from an MIT dataset; sleep, waking, and after-prayer adhkar are built from
hadith-api (The Unlicense) with Quran passages drawn from the Tanzil text above. Sources, checksums, the entries a
scholar should still review, and the open question about the Hisn al-Muslim text rights are in
`docs/ADHKAR_SOURCES.md`.

## 6. Data files: what we have and what is missing

| Data | Source | Status |
|---|---|---|
| Surah names, ayah counts, revelation place, ruku counts | [Tanzil `quran-data.xml`](https://tanzil.net/res/text/metadata/quran-data.xml), licence `cc-by` declared in the file | **Bundled**, unmodified, SHA-256 `8867c1d8…c5c7a`, verified at load and in tests |
| Juz, hizb, manzil, sajda starts | same file | **Bundled** (only surahs, juz, and page starts are read so far) |
| First ayah of each of the 604 Madinah pages | same file | **Bundled**. Page 42 starts at 2:253 and holds Ayat al-Kursi (checked by a test) |
| Surah start page, juz start page | derived at load from the page starts | Computed, never hand-typed |
| Order of revelation of each surah | same file, its `order` attribute | **Bundled**, read at load (`Surah.revelationOrder`). Approximate: scholars differ, and the app says so |
| Occasions of revelation (asbab al-nuzul) | Al-Wahidi's «أسباب نزول القرآن» (d. 468 AH), from [Quranpedia](https://quranpedia.net)'s dump `asbab-book-2919.json.gz`, version 2026-08-10, SHA-256 `d1831b1e…7486f7c9`, under the [Quranpedia data licence](https://quranpedia.net/dumps/LICENSE.md) (version 2026-11-24): free to use inside apps, no attribution required; republishing the data as a dataset needs a credit with a link and the dump's version | **Bundled** as `assets/quran/asbab/wahidi.json.gz` (233,863 bytes, SHA-256 `62ca0e9e…eba31010`, checked at load), built by `tool/build_asbab.py`: the text word for word, only its markup removed; 564 ayahs, 446 passages. The dump names no printed edition (its wording matches Zaghloul's, Dar al-Kutub al-Ilmiyya, 1411 AH); the editor's footnotes are not in it. Quranpedia corrects its data over time: rebuild from a newer dump before a release (`/api/v1/changes?since=2026-08-10`) |
| Ayah text with tashkeel (Uthmani, Hafs) | [Tanzil text](https://tanzil.net/docs/quran_text_types) v1.1, CC BY 3.0, with Tanzil's default options (pause marks, sajdah signs, alef, tatweel) | **Bundled**, unmodified with its copyright block, SHA-256 `6933e133…ec5f`, verified at load and in tests |
| Ayah text without tashkeel | Tanzil Simple Clean v1.1, CC BY 3.0 | **Bundled**, unmodified, SHA-256 `228df2a7…7610`. Used only for search |
| Line-by-line page layout (which words on which line) | QUL or Quran Foundation | Blocked on the permission requests (`docs/PERMISSION_REQUESTS.md`) |
| Fonts: QPC Hafs (default), QCF V1 pack (optional) | KFGQPC via Quran Foundation or direct approval | Blocked on the same requests |
| Search keys | derived at runtime from the two texts and the surah names | Computed off the main isolate, kept apart from verbatim text |

Rules that apply to every row: bundle the file unmodified, record its SHA-256 in code, fail a test if it
changes, and add attribution to the About screen.

## 7. What to get for each need

| Need | Best source | Licence status | Notes |
|---|---|---|---|
| Ayahs with full tashkeel, to display | [Tanzil](https://tanzil.net/docs/quran_text_types) **Uthmani**, `txt-2` (`surah\|ayah\|text`), default options | CC BY 3.0, clear | **Bundled.** 6,236 ayahs, 1.40 MB raw. Tanzil puts the basmala in front of the first ayah of 112 surahs; the app separates it (section 8). |
| Ayahs without tashkeel, for search | Tanzil **Simple Clean**, same format | CC BY 3.0, clear | Tanzil describes it as "without any diacritics or symbols, suitable for easy search". Checked: 6,236 ayahs, 0.78 MB raw, SHA-256 `228df2a717671aeb9d2ff573002bd28d6b3f973f4bc7153554e3a81663d67610`. Kept as its own file, never mixed with the display text. |
| Which page an ayah is on | Tanzil `quran-data.xml` page starts | CC BY, clear | Already bundled. `QuranMetadata.pageOf(surah, ayah)` answers it. |
| The 60 hizb of the index | Tanzil `quran-data.xml` quarters (rub') | CC BY, clear | Already bundled. A hizb is four quarters, so hizb *n* begins at quarter 4(*n*−1)+1 (`QuranMetadata.hizbs`, derived, not listed by hand). Checked: every odd hizb begins exactly where its juz does (test). |
| Where on the page (line and word of each ayah) | QUL Mushaf layouts, or Quran Foundation `verses/by_page` (needs API credentials; returns `page_number`, `line_number`, `position` per word) | Not confirmed for either | Blocked on the permission requests. In font mode no pixel coordinates are needed: we lay out the words ourselves, so we know where each one is. |
| Page images | Quran Foundation Content API (Uthmani Tajweed and black images) | Same bundling terms as fonts, to be confirmed | Format, resolution, and size per page are unknown; asked in the email. |
| Tap and highlight areas on images | Needs word boxes that match the exact image set. A third-party project (`qurancoor`) publishes boxes for 77,320 words derived from the quran.com images | Not checked | Only needed for image mode. Ask Quran Foundation whether they publish boxes with the images. |
| Tafsir | QUL lists 14 Arabic tafsirs as JSON/SQLite: Ibn Kathir, Al-Qurtubi, Al-Tabari, Al-Baghawi, Al-Wasit, Muyassar, Al-Razi, Ibn Juzay, Al-Nasafi, Jalalayn, Al-Kashshaf, Al-Baydawi, Al-Tahrir wa al-Tanwir, and the Mawsoo'at al-Tafsir al-Ma'thoor | **Not stated per tafsir** | Classical works can still carry rights in a given digitised edition. Ask Tarteel which tafsirs are redistributable and under what terms. Ship them as on-demand downloads, never bundled. |
| Translations | Tanzil translations | Each one has its own licence, listed on tanzil.net | Later, on demand. |

Not verified: the size of each tafsir, whether Quran Foundation's API serves tafsir under bundling terms, and QUL's
terms of use (the terms page returned 404 and the resource pages state no licence).

### Bundled text: size and cost

| File | Raw | Gzip estimate |
|---|---|---|
| `quran-uthmani.txt` | 1.40 MB | about 290 KB |
| `quran-simple-clean.txt` | 0.78 MB | about 206 KB |
| `quran-data.xml` | 77 KB | about 13 KB |

About half a megabyte added to the install. Parsing both files plus building the search keys took 33 ms and
83 ms in a desktop test run; the app does this in a background isolate.

The Uthmani and Simple Clean spellings differ beyond diacritics: Uthmani writes some alefs as dagger alefs
(for example "العٰلمين" against "العالمين"), so the two files do not fold to the same string. Search keeps one
folded key per spelling, and a query typed either way matches.

## 8. How the bundled text was obtained and checked

Download URLs (Tanzil's form, read on 2026-10-05):

- Uthmani, with Tanzil's default options:
  `https://tanzil.net/pub/download/index.php?quranType=uthmani&marks=true&sajdah=true&alef=true&tatweel=true&outType=txt-2&agree=true`
- Simple Clean, no options (no pause marks, no signs, as Tanzil describes it for search):
  `https://tanzil.net/pub/download/index.php?quranType=simple-clean&outType=txt-2&agree=true`

An earlier download of the Uthmani file had no options set and so had no pause marks or sajdah signs. It
was replaced; the current file has more than a thousand pause marks and exactly 15 sajdah signs (tested).

Checks, all reproducible:

| Check | Result |
|---|---|
| Ayah count, per-surah counts against `quran-data.xml` | 6,236; every surah matches (test) |
| Cross-check against Quran.com's `text_uthmani` (`tool/verify_text_against_quran_com.py`) | **6,236 of 6,236 identical**, after two documented differences: Tanzil's basmala prefix, and Quran.com's rub-el-hizb sign in the text |
| Basmala | 112 first ayahs carry it as a prefix (all but Al-Fatiha and At-Tawba). Searching the basmala then finds exactly 1:1 and 27:30 (test) |
| Checksums | Recorded in code; any change to a file fails loading and the tests |

Whether Quran.com's text is independent of Tanzil is not established, so the cross-check shows agreement,
not two independent proofs. Tanzil states its text is verified against the Madinah Mushaf.

**Basmala.** The app shows the basmala from ayah 1:1 above each surah that has one, and the ayah text without
the prefix. Nothing is typed: the prefix is recognised by folding the first four words of each first ayah
and comparing them with 1:1, and what remains is a verbatim tail of the source line.

## 9. Tajweed colours

| Option | What it is | Status |
|---|---|---|
| Quran Foundation `text_uthmani_tajweed` | Uthmani text with markup such as `<tajweed class=ghunnah>…</tajweed>`, 17 rule classes (hamzat al-wasl, lam shamsiyya, four madd kinds, ghunnah, qalqala, ikhfa, ikhfa shafawi, iqlab, idgham with and without ghunnah, idgham shafawi, mutajanisayn, mutaqaribayn, silent letters) | Uses its own encoding (for example U+0672, U+066E, zero-width non-joiners), so it does **not** line up character by character with the Tanzil text. It needs its own matching font. Licence to be confirmed. |
| QCF V4 Tajweed page fonts | Colours built into the font (COLRv1), matching the printed tajweed Mushaf | Per-page fonts; Flutter COLRv1 support unverified on device. Licence to be confirmed. |
| [cpfair/quran-tajweed](https://github.com/cpfair/quran-tajweed) | Rule positions by character index on Tanzil Uthmani, CC BY 4.0 | Built on an older Tanzil encoding, not maintained. Not reliable for the current file. |

Decision: no tajweed colouring until one of the first two is approved and verified on a device. The app never
computes tajweed rules itself.

## 10. Tafsir and ayah positions on page images

| Need | Option | Status |
|---|---|---|
| Tafsir | QUL (14 Arabic tafsirs, JSON/SQLite) | Licence per tafsir not stated; ask Tarteel |
| Tafsir | [spa5k/tafsir_api](https://github.com/spa5k/tafsir_api): repository MIT, data mostly exported from QUL | The MIT licence covers the code, not the tafsir texts. Al-Jami' Al-Wajiz is CC BY-ND 4.0 (unchanged wording only). Others follow their original rights |
| Ayah and word positions on page images | Must match the exact image set used. A third-party project (`qurancoor`) derives 77,320 word boxes from the quran.com images | Licence not checked. Ask Quran Foundation whether boxes ship with their images |
| Word positions in font mode | Not needed: the app lays out every word, so it knows where each one is | Needs line layout data (section 2) |

## 11. Bundled Quran font (provisional)

| Font | Source | Licence | Checksum |
|---|---|---|---|
| Amiri Quran 1.003 (`AmiriQuran-Regular.ttf`, 137 KB) | [google/fonts `ofl/amiriquran`](https://github.com/google/fonts/tree/main/ofl/amiriquran), built from [aliftype/amiri](https://github.com/aliftype/amiri) release 1.003 | SIL Open Font License 1.1 (`OFL.txt` bundled and shown on the licence page) | SHA-256 `e2a47644762d16bdfb6d33e0d8db8c6ff30beae84150ef5a705316bbd829455c` |

Amiri Quran is a Naskh font made for Quran text and renders the Tanzil Uthmani encoding, including the
ayah-end sign with its number. It is not the Madinah calligraphy. It stays until the KFGQPC fonts are
approved (`docs/PERMISSION_REQUESTS.md`).

## 12. Page images: downloaded on demand or as an offline pack, never bundled

> **Replaced on 2026-11-15.** The three image editions described in this section (Quran.com Madinah
> PNGs, Sakina tajweed, Sakina Madinah HD) and the glyph database were removed from the app. The
> printed Mushaf is now the vector pages of section 14. This section is kept as a record only.

Checked with HEAD requests on 2026-10-05 and again on 2026-10-06. **No WebP source was found**; every image
source below is PNG. None of the repositories declares a licence (GitHub reports none), and the images are
rendered from the KFGQPC fonts, so they carry the same permission question as the fonts.

| What | URL pattern | Format | Notes |
|---|---|---|---|
| Madinah pages, Quran.com (default edition) | `https://files.quran.app/hafs/madani/width_{480\|800\|1024\|1260\|1280\|1920}/page{001..604}.png` (`android.quran.com/data/width_N/` redirects here) | PNG, 4-bit palette, ink on a transparent sheet, 1260×2038 about 120 KB | Data set of the open-source Quran for Android app. No licence stated for the images |
| Glyph positions for the Quran.com pages | `https://files.quran.app/hafs/madani/width_1024/ayahinfo_1024.zip` | Zip with SQLite `ayahinfo_1024.db`, table `glyphs` (page, line, sura, ayah, position, min/max x/y in 1024×1656 pixels), 88,246 rows | Zip SHA-256 `b36fce9dab5275a0324b9cf78f67e6b6167cb68661ee53c64861217135b8eaa1`, database SHA-256 `30fa152370e19097ad1b4ddac2ea59a05f7ad0a4aa932b427ed87047c75cef69`, both checked by the app. 2,190 rows have their x or y edges swapped; the app reads them either way round |
| Madinah pages, plain (KFGQPC V4 rendering) | `https://cdn.jsdelivr.net/gh/SakinaDevGroup/mushaf-madani-cdn@main/{light\|dark}/p{1..604}.png` | PNG, 8-bit palette, 1080×2160, about 205 KB | [repo](https://github.com/SakinaDevGroup/mushaf-madani-cdn). No licence file |
| Madinah pages, tajweed colours | `https://cdn.jsdelivr.net/gh/SakinaDevGroup/mushaf-tajweed-cdn@main/{light\|dark}/p{1..604}.png` | PNG, 1080×2160, about 200 KB | [repo](https://github.com/SakinaDevGroup/mushaf-tajweed-cdn). Same pages, size, and line positions as the plain set |
| Official images | Quran Foundation Content API, Mushaf 10 (Uthmani Tajweed images) and 12 (black images) | Not documented publicly | Needs a developer account; bundling terms in `docs/PERMISSION_REQUESTS.md` |

### How the app uses them

The printed-Mushaf reader (`ReaderMode.printed`) offers three editions (`MushafStyle`, defined in
`lib/features/mushaf/domain/mushaf_edition.dart`): Quran.com Madinah pages (default), Sakina tajweed pages,
and Sakina plain pages. A page image (light or dark by theme, for the Sakina pages) is downloaded the first
time it is opened, checked to be really a PNG or a WebP (a CDN sometimes answers 200 with an error page), and
kept in the app support directory under `mushaf/images/{edition}/{light|dark}/`. The next 8 and previous 2
pages are fetched in the background so turning never waits on the network.

**Offline packs.** Settings, "Offline Mushaf", downloads a whole edition: 604 images, light and dark when the
edition has both (about 80 MB for Quran.com, about 250 MB for each Sakina edition, measured on sample pages),
plus the glyph database for Quran.com. Several editions can be kept and switched between. The files go to the
same paths the reader uses, so a downloaded page opens at once. The download is handed to the operating
system: a background `URLSession` on iOS and WorkManager on Android (package `background_downloader`), so it
continues when the app is closed, with one progress notification for the whole pack. The notification
permission is asked for when the person starts a download, never at launch. No foreground service is used.

### Where ayah positions come from

- **Quran.com pages:** the glyph database above, exact.
- **Sakina pages:** the ayah markers (rosettes filled with the colour `0xD8E9D8`, the same in both sets and
  both themes) are found on the light image, row by row, right to left. The markers close the ayahs of the
  page one by one, so each ayah gets its part of each line, cut at the marker that ends it
  (`measurePageGeometry` in `lib/features/mushaf/domain/page_geometry.dart`). Checked by overlay on pages 1,
  2, 50, 120, 187, 591, and 602, and by counting the markers on all 604 pages. A page whose markers cannot be
  counted has no ayah selection.
- **Which ayahs are on a Sakina page.** The Sakina images follow the 1441 H print, not the 1405 H page map of
  Tanzil and Quran.com. About 35 pages differ (page 120 ends with ayah 5:77, where the 1405 H page 120 ends
  with 5:76), and the line breaks differ on most pages. So `sakinaAyahsEndingOnPage`
  (`lib/features/mushaf/domain/sakina_pages.dart`) holds how many ayahs end on each page, and a page's ayahs
  follow from the pages before it. The counts were derived on 2026-10-06 by running the marker finder over the
  604 light images of `mushaf-madani-cdn` (the tajweed set has the same layout). They add up to 6,236, and
  each page is within one ayah of an independent count taken from the word ids of
  [KFGQPC_V4_layout](https://github.com/SakinaDevGroup/KFGQPC_V4_tajweed)'s `quran_pages.json`. A test checks
  the total and that pages follow one another. **Review the table against a printed 1441 H Mushaf before
  release.** The earlier approach, a line-and-word layout JSON from another project, was removed: its line
  breaks do not match these images.

### WebP

Lossless WebP is only 2 to 12% smaller than these PNGs, because the PNGs are already palette images, and
lossy WebP is larger (page 42, Sakina plain: PNG 209 KB; lossless WebP 185 KB; near-lossless 160 KB;
lossy q80 195 KB, q90 241 KB; Quran.com page 42: PNG 120 KB, lossless 117 KB, lossy q80 301 KB). Converting
on the device would need a native encoder and cannot be lossless on iOS, so it is not done. The store reads and
keeps whatever format the source serves (PNG or WebP, by header), so serving WebP needs only a host:
`tool/mushaf_pages_to_webp.sh OUT_DIR [light|dark|both] [FIRST] [LAST]` downloads the Sakina plain PNGs and
writes near-lossless WebP (about 23% smaller) with a `SHA256SUMS` file. Upload the output and change the URL
patterns in `MushafEdition`. Settle the licence first.

## 13. King Fahd Complex Mushaf script and font (bundled, owner-approved 2026-11-15)

The text reader draws the ayahs in the Complex's own script with its own font, and
search gains the Complex's plain spelling as a third key. Tanzil stays the text for
copying, sharing, adhkar passages, and the other two search keys.

| File in the repo | Taken from | SHA-256 |
|---|---|---|
| `assets/quran/kfgqpc/tafseerMouaser_v03.txt` | `hafs_tafseerMouaser_v3.zip` → `hafs_tafseerMouaser_v3_data/` (KFGQPC Tafseer Mouaser Data, version 3.0, updated 2023-01-08) | `df92e4e2c86b0a57cf67c31e710b55db00f04ba0ee6f18c497bb5f8b1b1be0cc` |
| `assets/quran/kfgqpc/read.me` | same folder; the Complex's own description of the columns | `0c9b42837edf0b138816193552a290fbdd85b727d4ff1bc278e9e40fbf2a3a54` |
| `assets/fonts/kfgqpc_hafs/uthmanic_hafs_v20.ttf` | same zip → `hafs_tafseerMouaser_v3_fonts/` (KFGQPC Uthmanic Script Hafs, version 2.0) | `d560bbbc7a90a4f4d416d206a5ac48bd8a1ad00273d64d232f16ca54941bd041` |

The zip itself: SHA-256 `443a6927dbbf9df0fb63792dc83b83511f7d308f3ec322c9230fbebfe3c69c86`, supplied by
the project owner from <https://qurancomplex.gov.sa>.

- **Unmodified.** All three files are byte-for-byte as in the zip. The data file's checksum is
  verified at load (`QuranTextSource.mushafSha256`) and in tests; the font's in tests.
- **What is read.** Columns `sura_no`, `aya_no`, `aya_text`, `aya_text_emlaey`. The ayah text is
  only separated from its trailing ayah-number glyph at the no-break space the source puts
  there (`KfgqpcHafsParser`); a test compares the two halves against the raw rows. The
  `aya_tafseer` column is Al-Tafsir Al-Muyassar, shown from an ayah's actions (`docs/DECISIONS.md` D-037),
  unchanged except for the markup that marks its quotes from the Quran.
- **Licence and the owner's decision.** The font's embedded notice says it "may not be
  reproduced, modified without the express written approval" of the Complex (see section 3).
  The Complex also publishes its digital Mushaf, font included, as free to use in "websites,
  software, and other similar intermediates" (quoted in the `NOTICE.md` of
  <https://github.com/quran-ws/quran-svg>). The project owner approved bundling on that
  basis on 2026-11-15. The files are not modified, and the About screen credits the Complex
  and states that all rights remain with it. If the Complex objects, remove the three files
  and the reader falls back to the Tanzil text with Amiri Quran (`QuranText.hasMushafScript`).
- **Not used.** `kfgqpc_hafs_smart_4.zip` (Hafs Smart font, version 0.8): its text is in
  private glyph codes, not Unicode, so it cannot be searched, copied, or read by a screen
  reader. Nothing from it is bundled.

## 14. Printed Mushaf pages: vector (SVG), downloaded on demand, never bundled (owner-approved 2026-11-15)

| | |
|---|---|
| Source | <https://github.com/elshoram974/quran-svg> (fork of `quran-ws/quran-svg`), commit `b4155f07e4aea087d2c458069acff9f7c7e749f6`, folder `mushafs/hafs/kfqc` |
| Served from | The owner's fork, at that commit, straight from GitHub: `https://raw.githubusercontent.com/elshoram974/quran-svg/b4155f07…/mushafs/hafs/kfqc/svg/NNN.svg` and `…/json/NNN.json` (owner's decision, 2026-11-19; it used to be `cdn.quran.ws`). Immutable while the fork keeps that commit. Sample pages of all five readings were fetched and match the manifests' SHA-256. jsDelivr was tried and refused: the repository is over its 50 MB limit and it answers 403 for most files |
| Artwork | Traced from the King Fahd Complex's digital Madinah Mushaf master files, Hafs, 1441 AH (`1441-AI-hafs.zip`, SHA-256 `280c5d71…9eef`, recorded in the source's `docs/PROVENANCE.md`). Rights remain with the Complex, which publishes it as free for "websites, software, and other similar intermediates"; only printing for commercial sale is reserved (source `NOTICE.md`) |
| Ayah polygons (JSON) | Quran.ws, CC BY 4.0, attribution waived for use inside a product. The app credits it anyway on the About screen |
| Size | 604 pages, 374 MB as served, about 91 MB on the device (kept gzip-compressed) |

**Integrity.** Nothing is bundled except `assets/quran/svg/hafs_kfqc_manifest.json`: the SHA-256 of all
1,208 page files and of the two release archives, generated by `tool/build_svg_manifest.py` from the
archives and never edited by hand. Its content hash is recorded in `SvgManifest.contentSha256` and checked by a test. A page file
is used only after it matches its SHA-256: on download, when the offline pack's files are taken in,
and again each time a page is read from the device. A file that fails is deleted and fetched again.

**What the app does to the artwork.** Nothing is redrawn. Each page's SVG is divided into its script
and its ayah-number ornaments (`<g id="ayah_markers">`) so each takes a theme colour, the invisible
polygon paths are dropped from the drawn copy (their data comes from the JSON), and the `viewBox` is
set to the visible part of the page. A one-off check over all 604 real pages confirmed: every path is
kept exactly once, 6,236 ornaments match 6,236 ayah regions, each ayah lies on exactly one page, and
only pages 1 and 2 need cropping (they fill about a fifth of their declared box).

**Format notes** (from the source's `docs/FORMAT.md`): a polygon is SVG path data with one `M … Z`
subpath per printed line, except on pages 1–2, where it is a bare `x,y x,y …` point list; the opening
pages declare a view box with a negative origin. `SvgPageParser` handles both and is tested on the
real polygon files of pages 1 and 3 (`test/fixtures/svg`).

**Offline download.** The whole Mushaf is fetched as the two assets of the `v1.1.1` release of the owner's
fork, <https://github.com/elshoram974/quran-svg/releases/tag/v1.1.1> (a mirror of the upstream release, the
same bytes; the ten archives of the five readings, uploaded by the owner on 2026-11-19; it used to be
`quran-ws/quran-svg`). For the Hafs reading: `hafs-kfqc-svg.zip` (121,647,518 bytes, SHA-256 `5d5e29ea…fc91`)
and `hafs-kfqc-json.zip` (492,327 bytes, SHA-256 `27dd192c…6c13`). Every uploaded asset's size and SHA-256
(as GitHub reports it) was compared with the manifests' and all ten match; a real download of one was
checked too. All 604 pages inside were checked against the per-page checksums. The system downloader fetches them
(a data-sync foreground service on Android, a background `URLSession` on iOS), so the download
carries on when the app is closed, and its notification can pause or cancel it. An archive is used
only if it matches its SHA-256; each page inside is then checked against its own SHA-256 before it
is kept. Two files replace the 1,208 small downloads tried first, which stopped when the app was
closed because their queue lived in the app's memory.

### Spreading the lines to fill a tall screen

A phone screen is taller than the printed page (345 × 550). The single-page
reader moves the printed lines apart until the page fills the height, up to
1.4 times the printed height (`AppTokens.readerMaxLineSpread`). Nothing is
scaled: every line keeps its drawn shape and moves as a whole, to where a
page that much taller would have it. The ayah regions stretch by the same
factor, so highlights and long-press still match.

How lines are told apart (`lib/features/mushaf/data/svg_line_splitter.dart`):

- A page's script is one SVG path. Its contours are drawn line by line, each
  line from edge to edge, so a wide jump of the pen marks a new line.
- The path is cut only between two whole contours. Only the opening move of
  each piece is rewritten, from relative to absolute; every other character
  of the path data is the source's.
- Pause signs, a basmala and a surah title come from other fonts and are
  drawn apart from their lines. Each is placed by where it lies, and only
  when it lies on one line beyond doubt. Across all pages such signs sit
  between 0.009 of the page height above their line's middle and 0.024
  below it; nothing else drawn apart is nearer than 0.058.
- Each ayah-number ornament moves with the line it sits on.

When the drawing order leaves something in doubt (a contour between two
lines, a surah title drawn in the same run as its basmala), the page is
split in three ways, surest first (`SvgLineSplitter.split`):

1. **By the drawing order, strictly**, as above.
2. **By the drawing order, leniently.** The script's lines still come from
   the drawing order. A contour it does not place beyond doubt is put on the
   nearer of the two lines it lies between: the one whose already placed
   outlines come closest to it. Bands of a title found on no line become
   their own line, and two lines closer than two lines can be are one. Kept
   only when it finds the page's 15 lines.
3. **By where each contour lies**, for an edition whose files do not draw
   line by line (`MushafEdition.linesInDrawingOrder` false) and for any page
   the first two cannot split. The page's 15 lines are found where its
   contours gather. A contour within 0.022 of the page height of a line's
   middle goes with it. Every other one goes to the nearer of its two lines,
   clearest first, by its distance to the nearest point of each line's
   outlines plus a quarter of its distance to each line's middle. The parts
   of one sign (overlapping boxes) go together: a sign of three or more
   parts to the line nearest its middle.

Checked against Hafs, whose strictly split pages give the right line of
every contour (each page split both ways and compared contour by contour,
2026-11-17), way 3 alone puts 216 of 776,653 contours (0.028%) on the wrong
line:
on 109 of those pages, one to four small marks or pause-sign parts each.
Spread to 1.4, such a mark sits a fifth of a line from its word. Ways 1 and 2
are used wherever they work for that reason.

The script may be one path, many paths (Hafs 17 and 144, Qalun 580, Al-Duri
92), a bare path, or a path under a matrix that only scales and moves it
(Shu'bah 313). A path is cut only between two of its own contours. The two
cropped opening pages are never spread; any page that still cannot be split
(a path command the scanner does not read, a page group that turns the page)
stays at its printed height, centred.

Check, over the two release archives unpacked (add `--unordered` for
Shu'bah, Qalun and Al-Duri):

```
dart run tool/check_svg_lines.dart <svg folder> <json folder> [--unordered]
```

Result on v1.1.1 (2026-11-17): every page but the two opening ones is
spread, with exactly 15 lines, in every edition.

| Edition | By drawing order | Leniently | By where contours lie |
| --- | --- | --- | --- |
| Hafs | 591 (17 and 144 by place, being many paths) | 11: 3, 45, 126, 294, 414, 458, 467, 496, 499, 515, 602 | 0 |
| Warsh | 469 | 114 | 19 |
| Shu'bah, Qalun, Al-Duri | — | — | 602 each |

Run the tool again after any change to the splitter; no page may stop being
spread and every spread page must still report 15 lines. The Hafs pages
split leniently were drawn spread at 1.4 and compared by eye: titles,
basmalas, marks and pause signs are each on their own line.

Pages 78 and 50 were also drawn spread at 1.25 and compared by eye with the
source: every letter, mark, pause sign and ornament is on its own line.

### Other readings (riwayat) of the printed Mushaf (owner-requested 2026-11-16)

The same quran-svg release (v1.1.1, commit b4155f07) carries four more King
Fahd Complex Mushafs. The app offers all five; the reader picks one in the
display options or in "Mushaf offline". Same source, licence and terms as
the Hafs pages above.

| Reading | Edition id | SVG archive SHA-256 | JSON archive SHA-256 |
| --- | --- | --- | --- |
| Hafs from Asim | `hafs-kfqc` | `5d5e29eae66d9353dd8e0e51af4274c7768f81f722414b538dfd7c8de014fc91` | `27dd192cec6b5f919ffd6e7df5216464aa57a671e326fc1a37a9d82dee3f6c13` |
| Shu'bah from Asim | `shubah-kfqc` | `1b37e01d3b3e605aec3c253ec3122970255ed5c05c3e9f6158811e63378e37ed` | `5e9d8f1a4e261261ca7c192511dcd3f99df2352d30aaa0818935faf6e8c68651` |
| Warsh from Nafi' | `warsh-kfqc` | `bee1286ad1993e7c9feb835c2ab3018454bcb5915c48ec19f6073f70921280f2` | `7afc9145135a2571d225bc4c70c949f8e6266a48405ba6cafbc083ffcb300ff4` |
| Qalun from Nafi' | `qalon-kfqc` | `4f6b42a9247048addeeca498bf69c789a730dc503fc372324b1114f03e0d7b3b` | `c175a217a96c0a0ee3a2a722fd43ecef7a50e89b4b5b452f3cb234240c838796` |
| Al-Duri from Abu Amr | `douri-kfqc` | `1460746a114a4f797a67ad8aa34e95680b0b025e1c5bad0113a100396764c945` | `76ad9de9636dfe6225a4d05240e1a4235e2f41cfbedce1ffee427ffd69e19008` |

- Each edition has its own manifest, `assets/quran/svg/<edition>_manifest.json`,
  built by `python3 tool/build_svg_manifest.py <edition> <svg zip> <json zip>`.
  Its content hash is in `SvgManifest.contentSha256` and a test checks it.
  A test also checks that no two editions share a page file.
- The four JSON archives match the `.sha256` files the release publishes. A
  page fetched from the CDN (Warsh, page 300) matched its manifest entry.
- All five have 604 pages and every surah starts on the same page, so page,
  surah and juz navigation is shared. The wording differs, and Warsh, Qalun
  and Al-Duri number some ayahs differently (6,218, 6,218 and 6,223 ayahs
  against 6,236).

What a reading other than Hafs does not get, and why:

- **No ayah actions, ayah highlights, or text standing in for a page.** The
  app's text, search, tafsir and ayah numbers are Hafs. Tying them to a page
  of another reading would show or copy words that are not on that page.
  `MushafEdition.matchesAppText` guards this.
- **Spreading of lines.** Every edition's lines are spread to fill a tall
  screen (owner's decision, 2026-11-17: the page must fill the height).
  Shu'bah, Qalun and Al-Duri do not draw their script line by line, so
  their contours are placed by where they lie (way 3 above), which is wrong
  for about 3 contours in 10,000.

Source quirks handled, not edited: these editions list the ayah polygons
before the artwork, and a few Qalun pages (141, 381, 589) carry an ornament
whose number group is empty and self-closed. The parser reads both; the page
is drawn as shipped.

### Adding a Mushaf

Every printed Mushaf is one entry in `MushafEditions`
(`lib/features/mushaf/domain/mushaf_edition.dart`) and one bundled manifest.
The reader, the edition chooser, the offline tile and its download all read
the list; nothing else changes.

1. Take the edition's two archives from the quran-ws/quran-svg release:
   `<edition>-svg.zip` and `<edition>-json.zip`. Record their source and
   licence here, as for the five above.
2. Build its manifest. The tool prints the entry to paste, with the
   manifest's content hash:

   ```
   python3 tool/build_svg_manifest.py <edition> <svg zip> <json zip>
   ```

3. Add the printed entry to `MushafEditions` and to `MushafEditions.all`,
   with its names. Add the manifest to the assets in `pubspec.yaml`.
4. Decide its two switches, never by default:
   - `matchesAppText`: only when its words and ayah numbers are exactly the
     app's text (Hafs). Otherwise its pages show without ayah actions.
   - `linesInDrawingOrder`: true only when `dart run
     tool/check_svg_lines.dart` (without `--unordered`) splits nearly every
     page by the drawing order, strictly, with exactly 15 lines.
5. Run the tests: they check every entry's manifest hash, that its manifest
   is bundled, and that no two editions share a page file.

`MushafPageKind` names how pages are drawn. Only `svg` exists; another kind
of page (images, say) needs its own renderer before an edition can use it.

## 15. Texts and fonts of the other readings (owner-approved 2026-11-17)

The quran-svg pages of Shu'bah, Warsh, Qalun and Al-Duri carry no text. To
copy and share their ayahs, the app bundles each reading's own text and font
from the King Fahd Glorious Quran Printing Complex (KFGQPC), as published on
its developer page (`https://qurancomplex.gov.sa/techquran/dev/`). That page
is rendered by script and offers no direct links, so the files were taken
from the mirror `github.com/thetruetruth/quran-data-kfgqpc`, commit
`281dbbe8eed1370daa5a023b6cd81655cbfd6473` (2022-02-15), which states the
developer page as its source. Licence: the Complex's terms, as for Hafs
(section 13): free for digital use, republished with credit and version.

| Reading | Source file (version) | Source SHA-256 | Font (SHA-256) |
| --- | --- | --- | --- |
| Warsh | `warsh/data/warshData_v10.json` (10) | `f05d0dc652fd46b38563cacb13242f76f80db4cc64d25873da0bce157253872f` | `warsh.10.ttf` (`e6347a1b4cf0ca32e9cb187a7db8c9ecee0d5e384269ca6a943373a34ff747fb`) |
| Qalun | `qaloon/data/QaloonData_v10.json` (10) | `18465c40ebeec40a92eb98745c9b89796ac6e31f6e93988883dfb6602faaea95` | `qaloon.10.ttf` (`95e7f9268fd4ab9f8b79d2ed3827e0c8a78f80195c02c6cbadb97c90d837b1e3`) |
| Al-Duri | `doori/data/DooriData_v09.json` (9) | `169b949d6cedd93ddb21728c16057d5ac7faf673ac10e0f213bb5dec1dc90d7d` | `doori.9.ttf` (`8a3c14c522ba4ef99d2ece6711ea45c5d7994568d98cf862c448e025592bf746`) |
| Shu'bah | `shouba/data/ShoubaData08.json` (8) | `f105da3949e0b8092e3abcd23a539c9bef4c9b7474f15d29848471f150ade667` | `shouba.8.ttf` (`9d13404a4a309f2d08501a15fed39d05baf83d3fa5e77bf43f0aac8c8614e118`) |

`tool/build_riwaya_text.py` turns each JSON file into
`assets/quran/riwayat/<edition>.txt`, one ayah per line
(`surah|ayah|page|text|mark`). The words are kept byte for byte; only the
number after the last no-break space is set apart (a plain space in Warsh
17:110 and 28:88). The output's SHA-256 is in `MushafEditions` and a test
checks it. Fonts are in `assets/fonts/kfgqpc_riwayat/`, unchanged.

Checked against the quran-svg pages of each reading (2026-11-17): Warsh,
Qalun and Shu'bah have the same ayahs (6,214, 6,214 and 6,236) on the same
pages as their polygons, every one. Al-Duri's text counts Al-Mulk (67) as
30 ayahs where its pages have 31, a known open question of counting noted in
the quran-svg repository; that surah gives no text, so no ayah is ever tied
to the wrong words. Everywhere else Al-Duri matches.

What each reading offers: select an ayah on its page, copy it with its
number, surah and page, and share it as text or as a picture set in its own
font. Bookmarks stay Hafs-only, since they hold the app's (Hafs) numbering.

Line spreading: every reading is spread (section 14). Warsh draws its
script line by line on 469 of 604 pages. Shu'bah, Qalun and Al-Duri draw
words and their marks in no line order, so each contour is placed by where
it lies; checked against Hafs's verified split, that is wrong for 0.028% of
contours.
