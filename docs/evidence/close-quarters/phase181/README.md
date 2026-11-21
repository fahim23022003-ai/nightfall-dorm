# Phase 18.1 Close Quarters corridor rendering

The renderer composites V3 corridor floors, wall trim, and lamps into padded 256-pixel chunks and submits one retained texture per visible chunk. It builds chunks on demand as the camera moves and keeps at most 32 recent chunks outside the case where more than 32 are on screen at once. Floor texture follows world coordinates across joins. The trim still follows the authoritative map rectangles, and Standard and Low retain their own lamp spacing and treatment.

The performance fixture uses the Cursed Mansion Campaign on Hell Stage 5, seed 73, and follows 120 actual native 1280×720 frames after 24 warm-up frames. Each paired scene starts with the same 24, 40, or 60 legally placed buildings on the original grid sizing. All building centers are visible at the start and at the end. An active Stalker attacks while weapons fire and land damage. Exact initial and final gameplay hashes, map hash, and camera agree for each pair. The candidate contains only the corridor renderer from `c9a5cc0cc4604eeec0fb1e444af96e3beebf74ea` on top of baseline `af1a113431931c12b49c2dbfb4be0aaca57a5896`. The building-scale flag is off in both, isolating the rendering gain from the change in building counts.

The Linux run uses Godot 4.6.3 Compatibility, Mesa 25.0.7 llvmpipe on an Xorg dummy display, CPU affinity 0–3, and two raster workers. One process runs per case in an isolated profile with VSync disabled. Each density and preset has one before/after pair. Pair launch order alternates to reduce run-order bias. Intel UHD and native Windows frame times were unmeasured.

## Native results

| Buildings | Preset | Median frame (ms) | p95 frame (ms) | Median draw calls | Median corridor CPU (ms) |
| ---: | --- | ---: | ---: | ---: | ---: |
| 24 | Standard | 61.37 → 56.16 | 75.75 → 75.28 | 566.5 → 364.5 | 0.416 → 0.060 |
| 24 | Low | 43.98 → 38.03 | 54.15 → 48.76 | 409.0 → 336.0 | 0.172 → 0.060 |
| 40 | Standard | 72.48 → 71.85 | 89.05 → 96.83 | 598.5 → 396.5 | 0.405 → 0.061 |
| 40 | Low | 46.82 → 38.55 | 59.05 → 47.58 | 410.0 → 337.0 | 0.181 → 0.059 |
| 60 | Standard | 84.18 → 78.52 | 119.40 → 95.79 | 638.5 → 436.5 | 0.411 → 0.060 |
| 60 | Low | 49.64 → 43.99 | 58.56 → 50.72 | 410.0 → 337.0 | 0.175 → 0.059 |

The 40-building Standard p95 rose 8.7% in this sample. Five other p95 values and all six medians fell. Draw submissions fell by 202 on Standard and 73 on Low. Each optimized fixture allocated 7.74 MiB of corridor texture payload. Godot's software-renderer video memory monitor rose by 10.23–10.30 MiB and static memory rose by 0.41–0.44 MiB. The first native view frame included cold engine and renderer costs and varied from 385–531 ms with the cache and 407–590 ms before. It rose roughly 28–30 ms in both 40-building runs.

Thirty navigation queries in each run targeted the same door from spawn, the Hunter's start, and the Hall entrances. Both builds have the same 97 nodes, 124 corridors, and route distance statistics. Observed median queries ranged from 0.560–0.661 ms. The measured change affects drawing only.

## Reproduce

From the repository root, create detached source archives, install the benchmark and its receipt flush in the baseline archive, then apply only the candidate’s corridor cache and its two map renderer hunks to the other archive.

```sh
scratch=$(mktemp -d)
mkdir "$scratch/before" "$scratch/after"
for variant in before after; do
  git archive af1a113 project.godot assets scenes scripts tests tools | tar -x -C "$scratch/$variant"
  mkdir -p "$scratch/$variant/tools/phase181"
  cp tools/phase181/measure_equal_workload.gd "$scratch/$variant/tools/phase181/"
  cp tools/phase18/measure_close_quarters.gd "$scratch/$variant/tools/phase18/"
done
printf '%s\n' af1a113431931c12b49c2dbfb4be0aaca57a5896 > "$scratch/before/source-sha.txt"
printf '%s\n' 'af1a113 + scoped corridor render cache only' > "$scratch/after/source-sha.txt"
git show c9a5cc0:scripts/close_quarters_draw_cache.gd > "$scratch/after/scripts/close_quarters_draw_cache.gd"
git diff af1a113 c9a5cc0 -- scripts/map_presentation.gd | sed '/^@@ -367/,$d' > "$scratch/map-cache.patch"
git -C "$scratch/after" apply "$scratch/map-cache.patch"
for variant in before after; do
  python tools/phase181/instrument_corridors.py "$scratch/$variant"
  godot --headless --path "$scratch/$variant" --editor --import --quit
done

# Set DISPLAY to an existing isolated Xorg framebuffer before running.
taskset -c 0-3 python tools/phase181/run_equal_workload.py \
  "$scratch/before" "$scratch/after" "$scratch/paired" --display "$DISPLAY"
```

The [raw receipts](measurements/) contain frame and CPU samples, draw calls, events, digest checks, route query times, and the renderer memory monitors. [Matched Hospital views](visuals/) are from seed 10358, Room 2, both at camera scale 0.88. Their capture receipts match byte for byte and both pass all 12 checks.
