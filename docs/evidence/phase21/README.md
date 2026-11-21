# Phase 21 Tactical Interface verification

The Windows preview defaults to Low at 960×540 and uses a separate profile.
The known Performance launcher is bundled. The Phase 20 release remains
available. The export ran as an embedded Godot pack under Linux. Native
Windows and Intel UHD timing remain open.
[GitHub download](https://github.com/fahim23022003-ai/nightfall-dorm/releases/download/phase21-tactical-ui-preview/NightfallDorm-Phase21-Windows-x64.zip)

## What changed

- One tactical status bar, one labeled door meter and four main actions.
  More holds utilities. Selecting a new utility replaces the prior one.
- Placement groups the footprint, orientation, exact costs and obstruction
  reason with Rotate, Place and Cancel. The actual room grid admission,
  blocked access geometry, charges, move and refund rules are reused.
- The machine inspector reserves a scroll area above the action buttons.
  Item inspection keeps the explicit confirmation and live availability.
- Settings uses six categories and contained scrolling. The same stored
  preferences power the controls. Help and in-match Settings pause the
  simulation and return to its prior running state.
- Story prep, the offline lobby, inventory, Shop and results have the shared
  palette and navigation. Result amounts still come from settlement.
- Practice keeps its real three-lesson transactions. Its cue updates on
  target changes, duplicate controls are suppressed, and unused pad markers
  are skipped in vacant practice rooms. Normal Story keeps its rendering
  preset and combat simulation.

## Walkthroughs

- [Uncut 960×540 Low tutorial](tutorial-low.mp4)
- [Uncut 1280×720 Standard tutorial](tutorial-standard.mp4)
- [Real-input menu and match walkthrough](ui-walkthrough.mp4)

The recordings are from Linux Godot with the dummy audio driver. The two
tutorials use the real input path for movement, claiming, sleep, opening
Build, each purchase and Cancel. Each completed 46 checks. Needles fired a
real projectile and no permanent wallet or inventory change was awarded.

## Before and after

The [Phase 20 Low](before-low) and [Phase 20 Standard](before-standard)
folders show the old interface on the same capture route. The [Phase 21
Low](low) and [Phase 21 Standard](standard) folders cover the main menu,
Story prep, lobby, calm, siege and critical combat, Build, valid and blocked
placement, machine inspection, Items, inventory, Shop, six Settings pages,
Help, map and ranks. Separate result captures show a [settled
victory](victory.png), [defeat payout](defeat.png), and [match timeline](timeline.png).

## Tutorial timing

Godot 4.6.3 Compatibility with Mesa llvmpipe on Linux. Measurements below
use the live input walkthrough harness without recording overhead. Frame
timing is elapsed wall time between process frames. The old and new tutorial
use the same lessons, practice map, model rules and target graphics preset.

| Resolution and preset | Median, before → after | p95, before → after | p99, before → after | Median draws |
| --- | ---: | ---: | ---: | ---: |
| 960×540 Low | 32.57 → 23.51 ms | 84.25 → 49.54 ms | 100.03 → 74.93 ms | 407 → 307 |
| 1280×720 Standard | 41.26 → 36.82 ms | 121.07 → 84.48 ms | 140.08 → 95.55 ms | 418 → 316 |

The fixed-layout practice wasted draw work on empty legacy floor markers
in rooms unrelated to the current lesson. The old placement UI also kept
several labels and controls up to date while the pointer and lesson overlay
re-evaluated highlights. Phase 21 uses a single cue and one placement tool.
The table measures the net improvement. It does not isolate each change.

[Raw frame and interaction receipts](metrics.json)

## Matched desktop workloads

Each row measures 45 rendered frames after five warm-up frames. The
Story arms share the same map seed, occupied room, quality, paid Needle
and one actual combat shot. A fixed model tick and disabled adaptive
trimming keep the workload comparable. Values are p95 in milliseconds.

| Surface | Low before → after | Standard before → after |
| --- | ---: | ---: |
| Main menu | 23.26 → 19.31 | 30.80 → 33.55 |
| Graphics settings | 29.23 → 23.62 | 45.69 → 35.18 |
| Story prep | 24.48 → 24.08 | 44.09 → 41.18 |
| Offline lobby | 20.04 → 15.80 | 33.45 → 37.16 |
| Calm HUD | 20.23 → 18.91 | 31.59 → 32.92 |
| Turret combat | 21.42 → 23.06 | 41.24 → 45.21 |
| Build catalogue | 29.88 → 24.38 | 52.13 → 50.33 |
| Placement | 29.99 → 21.49 | 42.69 → 41.27 |
| Items | 31.61 → 20.74 | 58.95 → 41.36 |
| Paused Help | 28.82 → 21.34 | 48.45 → 49.51 |

The raw receipt contains median and p99 frame times, draw calls and
the synchronous game-process median. That process timing includes both
UI and simulation. It excludes the await for the rendered frame.

### Seven-machine combat retest

Both builds fired five shots and removed 140 Hunter HP. The larger
fixture measured 120 frames at the same quality and camera.

| Run | Median, before → after | p95, before → after |
| --- | ---: | ---: |
| Low | 27.84 → 26.34 ms | 36.56 → 34.57 ms |
| Standard | 54.68 → 62.49 ms | 75.10 → 78.04 ms |
| Standard, order reversed | 54.93 → 54.37 ms | 71.60 → 69.96 ms |

The short one-Needle test was slower in both presets. The longer test
improved in Low and produced opposite results across the Standard repeats.
The Linux evidence does not establish an active-combat speedup on Windows.

## Scope and test boundaries

Game rules, balance and save versions are inherited from Phase 20. Profile
and active-match tests use isolated data. The camera, map and tool checks
do not modify the protected access geometry.

The legacy scene smoke test targets the fallback's exact visible button names.
It passes on that layout. The Phase 21 interaction suite uses real controls in
the new layout at both sizes, with 101 checks per run. Older combat and
save fixtures were also run under their usual map and feature settings. Several
fail in the same way on both versions when every preview flag is forced on.
The embedded pack separately passed the Phase 21 lobby, settings, map and
Story startup checks under the bundled flags.

The regular suite and the default projectile, weapon feedback, Full Room
Grid save, procedural persistence, lobby and Story progress suites passed.
The longer default Endless retry completed 28,426 checks across 45
approaches and its checkpoint tests. The Phase 21 defeat journey verified
actual RM Cash settlement and item purchase in 87 rendered checks.

The UI-workload fixture covers steady-state render and game-process costs
for the major surfaces. It does not measure every transition or result
screen. Fullscreen keyboard behavior and Windows responsiveness need
target-device playtesting.

[Windows package receipt and SHA-256](windows-package.json)
