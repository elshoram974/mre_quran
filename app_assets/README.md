# app_assets

Source material for the app that is **not** bundled as-is: the icon's
masters, store graphics, and the media served to the app from its own
repository. Nothing here is listed in `pubspec.yaml`.

| Folder | What | In git |
|---|---|---|
| `icon/` | The icon's masters (SVG) once the design is agreed. Today the icon is drawn by `tool/app_icon/render_app_icon_test.dart`. | yes |
| `store/` | Play and App Store graphics and screenshots. | yes |
| `media/` | The files of the media repository (`mushafi-media`): adhan recordings the app downloads on demand. Built by `tool/audio/build_adhan_audio.py`; never edited by hand. | no, it is its own repository |

## media/: publishing

1. Build: `python3 tool/audio/build_adhan_audio.py --cache <folder> --media app_assets/media --base https://cdn.jsdelivr.net/gh/elshoram974/mushafi-media@v1`
2. Push the contents of `media/` to the `mushafi-media` repository and tag it `v1`.
   A tag is immutable, so the SHA-256 in `assets/adhan/voices.json` keeps
   matching what jsDelivr serves.
3. A changed file needs a new tag (`v2`) and a new `--base`: never move a tag.
