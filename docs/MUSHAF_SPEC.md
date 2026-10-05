# What makes a good digital Mushaf

A checklist for calling MRE Quran a trustworthy, complete Mushaf, with the app's status against each item.
Sources are listed at the end. Status: **done**, **partial**, **missing**, or **blocked** (waiting on a
permission or data source).

## 1. Authentic text

| Requirement | Why | Status |
|---|---|---|
| Riwayah of Hafs ʿan ʿĀṣim, the reading of the Madinah Mushaf | The edition readers expect | **done** (Tanzil Uthmani is the Madinah text, Hafs) |
| Kufic ayah count: 6,236 ayahs in 114 surahs | The counting system the Madinah Mushaf follows | **done** (tested) |
| Text from a verified source, never typed or edited | Any slip in Quran text is unacceptable | **done** (Tanzil, unmodified, SHA-256 checked at load and in tests) |
| Cross-checked against a second source | Catches a corrupted or wrong download | **done** (6,236 of 6,236 identical to Quran.com, `tool/verify_text_against_quran_com.py`) |
| Basmala handled correctly: ayah 1 of Al-Fatiha, absent from At-Tawba, a heading elsewhere | A common source of wrong ayah text and wrong search results | **done** (tested) |
| Attribution and licence shown in the app | Required by the text licence | **done** (About screen) |
| Review by the King Fahd Complex digital research centre | The Complex reviews digital Qurans on all platforms, can certify them, and can stop flawed texts | **missing**: apply before release (process to be confirmed with the Complex) |

## 2. Faithful to the printed Madinah Mushaf

| Requirement | Status |
|---|---|
| 604 pages, the same page breaks; every page starts at the start of an ayah | **done** (page starts from Tanzil metadata; tested) |
| 15 lines per page (pages 1 and 2 are decorated and shorter), the same line breaks | **done** in the printed reader (page images); **partial** in the typeset reader (page breaks only) |
| Uthman Taha's calligraphy (KFGQPC fonts or page images) | **partial**: printed reader shows page images rendered from the KFGQPC fonts (licence not declared, owner handling permission); typeset reader uses Amiri Quran |
| Surah headings and the basmala | **done** (drawn heading with name, order, ayah count, Meccan or Medinan) |
| Ayah-end markers with the ayah number | **done** |
| Waqf (pause) signs | **done** (kept in the text) |
| Sajdah signs at the 15 sajdah places | **done** (in the text; tested) |
| Rub' al-hizb sign (۞) at each quarter, hizb and juz shown at the top of the page | **done** (240 quarters from the metadata; each juz starts a hizb, tested) |
| Page number on each page | **done** |

## 3. Structure the app must agree with

| Count | Value | Checked |
|---|---|---|
| Surahs | 114 | yes |
| Ayahs (Kufic) | 6,236 | yes |
| Pages | 604 | yes |
| Juz | 30 | yes |
| Hizb / rub' | 60 / 240 | yes |
| Sajdah places | 15 | yes |
| Surahs opened by a basmala heading | 112 | yes |

Word and letter counts are not used as checks: classical counts differ (for example 77,439 or 77,449
words) depending on how words are counted.

## 4. Reading experience

| Feature | Status |
|---|---|
| Right-to-left page turns, saved position, open at the last page | **done** |
| Index by surah and juz, search by surah, ayah reference, and words without tashkeel | **done** |
| Night and sepia themes, text size | **done** |
| Immersive reading (tap to hide bars) | **done** |
| Two-page spread on wide windows (odd page on the right, page 1 alone) | **done** |
| Go to page, juz, hizb | **done** (search by number) |
| Bookmarks, listed newest first, swipe to remove, marked on the page | **done**; notes are **missing** |
| Long-press on an ayah: copy with reference, bookmark | **done**; share, tafsir, and listen are **blocked or missing** (share needs a plugin; tafsir and audio need licensed sources) |
| Tajweed colours | **blocked** (licensed data or fonts) |
| Tafsir, translations, recitations, downloaded on demand | **blocked** (licences per source) |

## 5. Quality

| Requirement | Status |
|---|---|
| Works fully offline | **done** for text, index, search; printed pages work offline once opened |
| Small install | **done** (text, metadata, and font add about 0.6 MB compressed) |
| Fast start and smooth page turns | **partial**: start-up improved and measured on an emulator; re-measure on a real phone |
| No ads, no tracking, crash reports only with consent | **done** |
| Accessible: screen readers, large text, reduced motion | **partial**: tested at large text; ayah semantics still to add |

## Priority to call it a good Mushaf

1. Exact pages: get permission for the KFGQPC fonts or page images and the line layout, then render them.
2. Share, tafsir, and listen in the ayah actions, once their sources are approved.
3. Bookmark notes, go to page, juz, or hizb.
4. Apply for the King Fahd Complex review before publishing.

## Sources

- Madinah Mushaf: 15 lines per page except pages 1 and 2, calligrapher Uthman Taha, Hafs ʿan ʿĀṣim, Kufic count of
  6,236, waqf, sajdah, hizb and rub' marks, reviewed by a committee for readings, orthography, vocalisation,
  verse endings, and pauses: [Wikipedia (Arabic)](https://ar.wikipedia.org/wiki/%D9%85%D8%B5%D8%AD%D9%81_%D8%A7%D9%84%D9%85%D8%AF%D9%8A%D9%86%D8%A9_%D8%A7%D9%84%D9%86%D8%A8%D9%88%D9%8A%D8%A9).
- King Fahd Complex digital review of Qurans on all platforms, certificates, and stopping flawed texts:
  [Saudipedia](https://saudipedia.com/en/article/450/religion/religious-affairs/king-fahd-glorious-quran-printing-complex),
  [King Fahd Complex](https://qurancomplex.gov.sa/).
- Word and letter counts vary by method: [IslamQA](https://islamqa.org/hanafi/tafseer-raheemi/51510/how-many-verses-are-there-in-the-holy-quraan/).
- No public certification process for Quran apps from Al-Azhar was found.
