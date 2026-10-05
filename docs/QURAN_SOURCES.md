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

No source chosen. Candidates need their own licence check (Hisn al-Muslim text, translations, audio). The Duas tab
exists as an empty state until a licensed source is approved.

## 6. Data files: what we have and what is missing

| Data | Source | Status |
|---|---|---|
| Surah names, ayah counts, revelation place, ruku counts | [Tanzil `quran-data.xml`](https://tanzil.net/res/text/metadata/quran-data.xml), licence `cc-by` declared in the file | **Bundled**, unmodified, SHA-256 `8867c1d8…c5c7a`, verified at load and in tests |
| Juz, hizb, manzil, sajda starts | same file | **Bundled** (only surahs, juz, and page starts are read so far) |
| First ayah of each of the 604 Madinah pages | same file | **Bundled**. Page 42 starts at 2:253 and holds Ayat al-Kursi (checked by a test) |
| Surah start page, juz start page | derived at load from the page starts | Computed, never hand-typed |
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
