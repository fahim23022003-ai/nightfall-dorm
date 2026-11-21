# Phase 23 performance

## Isolated release comparison

Godot 4.6.3 ran the Phase 22.1 baseline (`3f9ec28`) and Phase 23 Story rules (`7bbb2ea`) on Linux X11 with Mesa 25.0.7 llvmpipe and the Dummy audio driver. Each resolution ran in **baseline → candidate → candidate → baseline** order after the export, match simulations and video encoding had finished. The shared AMD EPYC 9V74 VM exposed five virtual CPUs with a four-CPU cgroup quota. Game processes ran on CPUs 0–1 with two llvmpipe worker threads. The game rendered both quality presets without adaptive downscaling. Native Windows and Intel UHD frame times remain unmeasured.

Each process started a fresh Long Night Story Level 1 attempt at seed 1527566656, a Ring layout with the Crusher. Scripted controls walked from the shared spawn, claimed Room 4, slept and bought defenses using earned income. All five AI teammates played normally. The Hunter chose Room 1 at 48.05 seconds and reached its door at 61.30 in both builds. The siege camera observed that ally through the regular spectator function. Nine buildings were present across six rooms. The first five seconds of siege included two strikes and five weapon launches. This fixture isolates cost when the decision and its consequences match. The Campaign cohort covers changed targets and outcomes.

Each launch measured 100 consecutive frames during the opening choice and another 100 at first contact. One fixed 50 ms model step advanced per rendered frame. A rendering-only warmup preceded each window. Wall time covers the actual game update through the Godot post-draw signal. Model timing wraps the production `MatchModel.tick()` call separately. The three values in each cell are **median / p95 / p99**, in milliseconds, pooled over the two launches for each arm. The raw receipt retains every sample. Across the eight processes, 0/484 shared cgroup CPU periods reported throttling during measurement.

| Setting and window | Phase 22.1 frame | Phase 23 frame | Model tick, Phase 22.1 → Phase 23 |
| --- | --- | --- | --- |
| Low 960×540, opening choice | 22.43 / 29.69 / 33.39 | 21.80 / 29.68 / 34.63 | 0.76 / 1.07 / 2.01 → 0.82 / 1.04 / 1.19 |
| Low 960×540, first contact | 20.20 / 24.46 / 27.99 | 18.66 / 25.02 / 35.99 | 0.75 / 1.07 / 1.23 → 0.78 / 1.01 / 1.32 |
| Standard 1280×720, opening choice | 41.33 / 54.15 / 56.44 | 39.67 / 52.15 / 56.40 | 0.87 / 1.24 / 2.09 → 0.87 / 1.13 / 2.64 |
| Standard 1280×720, first contact | 36.60 / 45.18 / 47.03 | 36.46 / 44.68 / 47.05 | 0.84 / 1.15 / 2.10 → 0.87 / 1.12 / 1.21 |

On Low, the median siege frame improved by 1.54 ms. The p95 grew by 0.56 ms and p99 grew by 8.00 ms. Two launches per arm give limited evidence about rare hitches. Standard siege pacing was similar across both revisions.

The actual opening target selection occupied one model tick in each 100-frame opening window. Across four launches per revision that entire tick took 2.01–2.26 ms on the baseline and 2.10–2.32 ms on the candidate. Median draw counts matched. Low used 148 at opening and 114 in combat. Standard used 177 and 207. Godot reported approximately 151.0 MiB static memory and 100.9 MiB renderer memory on Low, and 152.4 MiB and 110.9 MiB on Standard.

## Shared-host controls

During the initial concurrent run, Standard opening median wall time rose from 43.33 to 59.27 ms. We repeated the measurement with the calibrated code and captured CPU scheduling counters. During simultaneous regression, recording and simulation jobs, the cgroup throttled during 957/957 sampled periods across both settings. Results changed with machine contention. These timings remain in the raw file. Use the isolated comparison above to assess this fixture.

## Decision cost with dense defenses

A separate, single-CPU headless stress fixture funded six occupied rooms and bought real Needle turrets on valid placements. The test repeatedly assessed all six rooms at one frozen Hunter position on the same graph. Five warm-up calls and 100 measured calls per density isolate the CPU cost of a full comparison. The game performs such comparisons at decisions. The diagnostic deliberately invokes them repeatedly. Its prepared economy contributes no match outcomes.

| Total weapons | Phase 22.1 median / p95 / p99 (ms) | Phase 23 median / p95 / p99 (ms) |
| ---: | ---: | ---: |
| 0 | 0.36 / 0.46 / 0.65 | 0.37 / 0.44 / 0.52 |
| 12 | 0.52 / 0.64 / 0.72 | 0.69 / 0.79 / 0.87 |
| 24 | 0.74 / 3.58 / 15.82 | 1.06 / 1.21 / 1.28 |
| 40 | 1.08 / 1.30 / 2.54 | 1.65 / 2.02 / 2.18 |
| 60 | 1.67 / 1.91 / 1.97 | 2.49 / 3.16 / 4.22 |

## Reproduction

Launch `res://tools/phase23_bench.gd` through Godot with the preview launcher's environment, a disposable profile, an X11 display and matching window resolution. Pass an absolute output JSON path followed by `low` or `medium` after `--`. Set `LIBGL_ALWAYS_SOFTWARE=1` and `LP_NUM_THREADS=2` for the software-rendered workload. Run `res://tools/phase23_bench_decision.gd` with `--headless` and one absolute output JSON path for the six-room dense fixture. Use `NIGHTFALL_HUNTER_INTELLIGENCE=1` for the Phase 23 Story rules and zero for the baseline. The Windows package includes `Record Phase 23 Diagnostic.cmd` for capturing local frame times on the target laptop.

[Summary, percentiles and scheduling counters](perf-results.json) · [Raw frames and dense-decision samples](perf-raw.json.gz)
