# Matched 720p active-combat benchmark

The baseline was `da4ef63`. The candidate was `2b302a0`. Each run
used the real Godot 4.6.3 Campaign renderer under Linux X11 and Mesa
llvmpipe. The paired arms used the same 24-building fixture, seed,
camera, quality and active rig. The benchmark used two llvmpipe
workers and CPU affinity 0–3. It excluded other capture workloads.
After warmup, each arm sampled 150 gameplay and render frames at
1280×720. All paired gameplay digests, strike counts, shot counts and
damage totals matched.

| Fixture | Paired runs | Before median / p95 ms | After median / p95 ms | Median draw calls |
| --- | ---: | ---: | ---: | ---: |
| Stalker Standard | 1 | 58.37 / 77.07 | 56.80 / 77.08 | 384 → 384 |
| Stalker Low | 1 | 50.80 / 76.94 | 51.12 / 72.48 | 379 → 379 |
| Transformed Reaper Standard | 1 | 58.31 / 82.73 | 59.64 / 86.76 | 584.5 → 585.5 |
| Transformed Reaper Low | 3 | 54.01 / 76.42 | 53.19 / 73.26 | 555.5 → 542.5 |

Reaper Low used the median of the three run medians and p95s.
Its p95 fell in two pairs and rose in one. Low saved 13 median
draw calls in all three pairs. The software renderer reported
about 17.5 MiB less video memory after the preview stopped eagerly
loading unused fallback SVGs. It also reuses per-atlas UVs and
triangle indices. A three-sprite haze replaces the old circles and
arcs on Reaper Low, with the same telegraphs and weapon animation.

The measured Low improvement is small relative to the run-to-run
spread. Standard Reaper was slower in its one pair. The prior
50.77 → 57.46 ms Low p95 comparison used a different session
and is retained as historical evidence. Native Intel UHD and
Windows timings remain unmeasured.

[Summary and method metadata](summary.json) · [Earlier checkpoint](../../hunter-articulation/performance/)

## Reproduce

Run the same command in each source snapshot with its own imported
project cache and fresh test profile, one at a time. Set the two
script arguments to either `medium reaper`, `low reaper`, `medium stalker`
or `low stalker`.

```sh
NIGHTFALL_LIVING_NIGHTMARE=1 NIGHTFALL_VISUAL_REBIRTH=1 \
NIGHTFALL_PROCEDURAL_MAPS_V2=1 NIGHTFALL_FULL_ROOM_GRID=1 \
LP_NUM_THREADS=2 XDG_DATA_HOME=/tmp/nightfall-profile \
taskset -c 0-3 godot --path . --resolution 1280x720 --audio-driver Dummy \
  --disable-vsync --quit-after 1400 \
  --script tools/nightmare_maps/measure_living_nightmare.gd -- /tmp/nightfall-bench low reaper
```
