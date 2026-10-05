# Quran content sources

Only the Tanzil metadata file (section 6) is bundled. Everything else here is research and
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
| QCF v4 | Madinah Mushaf (1441 H), one font per glyph group, about 47 files instead of 604 ([quran-qcf4](https://cdn.jsdelivr.net/npm/quran-qcf4@1.1.0/README.md)) | Lightest exact option, same licence question as above. |
| Fonts via Quran Foundation | [Developer terms](https://api-docs.quran.foundation/legal/mushaf-fonts-and-images/) allow bundling fonts and Mushaf images obtained through its APIs or documented CDN URLs if: you keep an active Developer Console account, credit Quran Foundation in the app, and ship them only as part of the app (no separate download or API). | Terms do not name QCF v1/v2/v4. Confirm with developers@quran.com. |

## 4. Recommended path

1. **Text:** Tanzil Uthmani, unmodified, with the required attribution.
2. **Layout and glyph fonts (QCF v4):** get written confirmation for one channel, in this order:
   Quran Foundation (they publish bundling terms), then written approval from KFGQPC.
3. **Light mode first:** font-rendered pages only. No images.
4. **Images later, one pack at a time:** same Quran Foundation terms, downloaded on demand, never bundled.
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
| Ayah text (Uthmani, Hafs) | [Tanzil text](https://tanzil.net/docs/quran_text_types), CC BY 3.0 | Not added yet. Clear licence; added with the reader, with its own checksum |
| Line-by-line page layout (which words on which line) | QUL or Quran Foundation | Blocked on the permission requests (`docs/PERMISSION_REQUESTS.md`) |
| Glyph fonts (QCF v4) | KFGQPC via Quran Foundation or direct approval | Blocked on the same requests |
| Search keys | derived at runtime from names | Computed, kept apart from verbatim text |

Rules that apply to every row: bundle the file unmodified, record its SHA-256 in code, fail a test if it
changes, and add attribution to the About screen.
