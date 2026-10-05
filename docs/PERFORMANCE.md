# Performance

How the app is measured, what was found, and what changed. Numbers come from a Pixel 3 emulator
(API 28, host GPU). Treat them as relative: compare before and after on the same device, and re-check on
a real phone before release.

## How to measure

Startup, in profile mode (three runs, take the spread):

```
fvm flutter run --profile --trace-startup -d DEVICE_ID
cat build/start_up_info.json
```

Frame timing for tabs, sheets, and the index, one report per phase (the first pass only warms up):

```
fvm flutter drive --no-dds --profile \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/perf_test.dart -d DEVICE_ID
```

Reports land in `build/*.timeline_summary.json`. Debug builds and Device Preview are always slower than
the app a reader gets, so never judge speed from them.

## Findings

- **Start-up was serial.** `main` awaited Firebase, then Crashlytics, then six settings reads one after
  another, then the last tab, before the first frame. The first frame also used default settings and
  switched to the saved theme later.
- **Theme changes waited for storage.** `save()` put settings into a loading state and applied the new
  value only after the write finished.
- **Glass shaders were never pre-warmed.** `LiquidGlassWidgets.initialize()` was not called.
- **Scrolling and tabs are cheap.** In the traced scroll phase, `BUILD` was about 42 ms in total over
  141 builds; most of each frame was the emulator's buffer swap. Tab switches built in about 2 ms.
- **Search typing churned memory.** Every keystroke re-folded all names. Garbage collection showed in the
  search phase.

## Changes

- Firebase, settings, last tab, and glass pre-warm now run in parallel (`lib/main.dart`). Settings reads
  inside the repository are parallel too.
- The saved settings are passed to the app before the first frame (`initialSettingsProvider`), so there is
  no default-theme flash.
- Settings apply at once and persist in the background, with rollback on failure.
- Index search keys are computed once (`IndexSearcher`), not per keystroke.
- Device Preview is only enabled in debug builds. In profile and release it adds nothing.

## Results

First frame rasterized after engine start, profile build, three runs each:

| Version | Runs (ms) | Average |
|---|---|---|
| Serial start-up | 829, 834, 725 | about 796 ms |
| Parallel start-up | 442, 703, 649 | about 598 ms |

Time after framework init: about 361 ms before, about 234 ms after. Three runs per version is a small
sample, so read it as "clearly not slower and probably 150 to 250 ms faster".

Frame timing after warm-up, per phase (build / raster, milliseconds):

| Phase | Frames | Build avg / worst | Raster avg / worst |
|---|---|---|---|
| Tabs | 28 | 2.3 / 11.6 | 6.7 / 17.4 |
| Open sheet | 23 | 14.4 / 161.9 | 28.6 / 117.3 |
| Open index | 2 | 45.4 / 87.1 | 14.0 / 14.0 |
| Scroll index | 64 | 25.0 / 121.7 | 39.9 / 157.0 |
| Search index | 9 | 74.5 / 280.2 | 108.4 / 275.2 |
| Close index | 2 | 16.1 / 29.8 | 15.9 / 15.9 |

These were taken before the search-key change and include emulator buffer-swap cost, so the raster
columns overstate what a phone will show. Re-run on a real device before trusting any single number.

## Rules

- Do not await independent work one after another before `runApp`. Run it in parallel.
- Never block the first frame on something the first frame does not need.
- Apply user changes first, persist after.
- Keep shimmer and glass off hot lists; use the minimal glass quality on repeated cards.
- Re-run the perf scenario after changing the shell, the index, sheets, or start-up.
