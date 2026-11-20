# Full Room Grid polish frame timing

The reference is commit `90659d7c514006666f31552fa7875e3325d58e1f`. Four physically legal grid rooms contain 24, 40, 60 and 82 machines. Each has all 15 placeable machine families at Level 10, one Level 1 Needle and as many Level 1 Decoys as the target count needs. A prepared budget buys and upgrades the machines through the normal model. The same exact coordinates, IDs, levels, branches and turns are replayed for every matching case.

The previews run at 1280×720 with the planning overlay open. Each trace records 180 real rendered frames after a 30-frame warmup. The pinned Hunter and room use the same seed-67 Endless model. The fixture advances presentation and freezes combat and economy simulation. No cursor moves, open machine lists, or image readbacks occur during timing. The benchmark also measures the portion of time spent in presentation update and records Godot draw statistics.

Godot 4.6.3 uses Mesa llvmpipe with the OpenGL Compatibility renderer and a Linux Xorg dummy display. Frame times characterize this software-rendered host. The fixtures sample a dense room and planning overlay and leave native Windows and Intel UHD timing open.

## Results

| Machines | Standard before | Standard after | Low before | Low after |
| ---: | ---: | ---: | ---: | ---: |
| 24 | 41.52 / 48.91 ms | 40.98 / 50.41 ms | 42.93 / 54.35 ms | 38.72 / 47.19 ms |
| 40 | 50.12 / 66.37 ms | 47.50 / 63.23 ms | 50.50 / 66.76 ms | 44.06 / 53.47 ms |
| 60 | 62.38 / 76.23 ms | 56.22 / 66.03 ms | 60.58 / 76.72 ms | 54.64 / 65.11 ms |
| 82 | 66.07 / 79.71 ms | 66.54 / 82.22 ms | 68.86 / 94.16 ms | 62.75 / 74.42 ms |

Values are median / p95 frame times. Low improved at all four densities in this sample. Standard improved both measures at 40 and 60; at 24 and 82 its p95 rose slightly. The trace set uses one sample per configuration and density. Minor differences can reflect host variation.

At 82, Standard draw calls fell from 1,075 to 820 and Low from 1,068 to 811. Standard primitives fell from 39,520 to 29,804. The directly timed presentation update remained near half a millisecond. The baseline's terrain draw path rebuilt and sorted machine geometry on every redraw, and its plan placed a fill and an outline for each footprint. The candidate caches layout geometry and batches occupancy outlines. These tests measure the whole scene, so they do not allocate frame time to individual draw operations. Estimated rendering memory at 82 increased from 147.15 MB to 153.28 MB on Standard.

All 16 traces had matching layout and sampled model hashes for each density. The two candidate sessions each passed 995 checks. The production script fingerprint was stable throughout both candidate sessions. The [raw comparison](comparison.json) includes cgroup CPU counters and the exact source fingerprint. See the same [82-machine layout before](checkpoint-82-standard-720.png) and [after](final-82-standard-720.png).

## Reproduce

Reproduce with an available display and a fresh profile for each process. With both previews enabled, collect the baseline Standard run using the archived checkpoint and the absolute path to the shared test script. Pass its output directory as the third argument to replay the same paid layouts in every subsequent process.

```sh
export NIGHTFALL_FULL_ROOM_GRID=1
export NIGHTFALL_VISUAL_REBIRTH=1
export XDG_DATA_HOME="$(mktemp -d)"
godot --path . --resolution 1280x720 --audio-driver Dummy --disable-vsync \
  -s tools/full_room_grid/measure_grid_polish.gd -- /tmp/grid-low low /tmp/checkpoint-standard
```

Use `medium` to select Standard. Run the four processes serially.
