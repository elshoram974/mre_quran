# app_assets

Source material for the app that is **not** bundled as-is: the icon's
masters and store graphics. Nothing here is listed in `pubspec.yaml`.

| Folder | What |
|---|---|
| `icon/` | The icon's masters (SVG) once the design is agreed. Today the icon is drawn by `tool/app_icon/render_app_icon_test.dart`. |
| `store/` | Play and App Store graphics and screenshots. |
| `brand/fonts/` | The fonts of the launch screen's "made by MRECode" (drawn by `tool/app_icon/render_splash_brand_test.dart`; only the pictures ship). |

## Brand fonts

From `google/fonts` at commit `7af0d90b4d532ffa4b041937b560c6df4e7b1e95`, SIL Open Font License 1.1 (each
licence beside its font):

| File | Font | SHA-256 |
|---|---|---|
| `Marcellus-Regular.ttf` | Marcellus, Brian J. Bonislawsky (Astigmatic), `ofl/marcellus` | `1cf0cd10b17d35e852729962cc1ffaffed94514895972458345e2df34abb2f81` |
| `CormorantGaramond-Italic[wght].ttf` | Cormorant Garamond Italic, the Cormorant Project, `ofl/cormorantgaramond` | `0f48ea6abb2084537854f7174c470991a463b13036309e3b50a81511611c530d` |

The files the app downloads (adhan recordings, and any new media) and the
privacy policy live in the folder `mre_quran_global` beside this repository,
published from its branch `global` with GitHub Pages
(`https://elshoram974.github.io/mre_quran_global/`); see its `README.md` and
`LINKS.md`.
