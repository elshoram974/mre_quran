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
- All 15 independent settings reads now start together, including the six
  display and haptic settings that were still read one after another. A unit
  test holds storage reads open and checks that all have started.
- Index search keys are computed once (`IndexSearcher`), not per keystroke.

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

In a later profile run on the API 28 emulator with software rendering, the first
frame rasterized in 612, 978 and 989 ms after the settings-read change. The
earlier three runs on the same emulator were 751, 946 and 1,043 ms, but the
reader's saved page and settings changed between the runs. They do not prove a
speedup; the concurrency test proves only that the six extra serial waits were
removed. Repeat with the same saved state and on a physical phone to compare.
The warm profile scenario after that change completed on the same emulator:
tabs averaged 2.2 ms build / 13.4 ms raster, the sheet 1.5 / 12.6 ms, and
index scrolling 0.9 / 15.1 ms. Index close had a worst raster frame of 72.8 ms;
these software-rendered emulator figures do not establish physical-device
performance or a regression against the earlier host-GPU measurements.
The same run measured six verified page turns per phase after warm-up: sliding
forward/back averaged 1.2 ms build and 15.3 ms raster; realistic forward
averaged 1.2 / 22.8 ms and realistic back 1.5 / 29.3 ms. Worst raster frames
were 35.8, 29.1, 63.8 and 110.4 ms respectively. This uses the emulator's
software renderer; check realistic turning on a real device before attributing
the cost to a specific effect or changing its appearance.

The draggable index was profiled on the API 28 emulator with software rendering
after its sheet change. The warm index-open, scroll, search, and close phases
averaged 10.0, 5.7, 9.6, and 29.6 ms build time and 29.9, 39.2, 47.6, and
34.2 ms raster time respectively. The close phase had only four frames and a
108 ms worst build. Tests were running on the host during this run, so these
figures expose a possible slow path but are not a controlled comparison with
the earlier results. Repeat on an idle host and a physical device before
concluding whether the sheet regressed.

## Rules

- Do not await independent work one after another before `runApp`. Run it in parallel.
- Never block the first frame on something the first frame does not need.
- Apply user changes first, persist after.
- Keep shimmer and glass off hot lists; use the minimal glass quality on repeated cards.
- Re-run the perf scenario after changing the shell, the index, sheets, or start-up.
