# Golden Quran competitive audit

## Scope

This is a public feature audit. It does not copy Golden Quran branding, assets,
Quran data, audio, source code, or interaction design.

## Publicly visible strengths

Golden Quran publicly advertises verse-level actions, tafsir and word meanings,
audio with many reciters, download-on-demand audio, bookmarks, search, dark
reading, athkar, prayer times, Qibla, khatma plans, and multiple languages.

Sources:

- Google Play: <https://play.google.com/store/apps/details?id=org.goldenquran.freesoft>
- App Store: <https://apps.apple.com/us/app/golden-quran-%D8%A7%D9%84%D9%85%D8%B5%D8%AD%D9%81-%D8%A7%D9%84%D8%B0%D9%87%D8%A8%D9%8A/id852497554>

## Golden Quran differentiators

1. Verifiable Quran pipeline: source, exact version, checksum, attribution, and
   integrity tests are visible to maintainers and users.
2. Lightweight default: font/text reader first; optional images, audio, tafsir,
   and translations download only with consent.
3. Privacy by default: no account, ads, analytics, or crash collection before
   clear user consent.
4. Adaptivity by constraints: one page on compact windows and a preserved-state
   spread on large windows, split view, iPhone Duo, and Android foldables.
5. Accessibility: semantic ayah actions, 200% text scaling, motion reduction,
   and full RTL/LTR directional layouts.
6. Restrained shader-based Liquid Glass for controls and navigation on iOS and
   Android. Quran content stays high-contrast.

## Delivery order

| Priority | Feature | Gate |
| --- | --- | --- |
| P0 | Exact offline reader, last read, bookmarks, index, search | Verified font/page-map/text sources |
| P1 | Ayah action sheet, licensed tafsir/translation downloads | Each source licence |
| P1 | Audio, background player, per-surah downloads | Recitation source terms |
| P2 | Khatma, wird, athkar, memorization planner | Notification consent |
| P2 | Prayer times, Qibla, Hijri, widget | Location/notification/sensor permissions |
| P3 | Tajweed, word-by-word, multiple riwayat, images mode | Verified matching data and asset terms |

## Update tracks

| Update | Feature set | Product edge |
| --- | --- | --- |
| 1.1 Study | Ayah sheet, bookmarks, tafsir/translation downloads | Provenance and offline asset management |
| 1.2 Listen | Reciters, repeat ranges, background player, resumable downloads | Per-surah storage limits and no bundled audio |
| 1.3 Worship | Khatma, wird, athkar, reminders, prayer, Qibla, Hijri | Local-first plans and permission only at point of use |
| 1.4 Mastery | Tajweed, memorization, word-by-word, other riwayat, images mode | Verified source matching and foldable-optimized study layouts |
