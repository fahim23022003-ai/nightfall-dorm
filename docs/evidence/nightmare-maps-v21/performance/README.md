# V2.1 active combat performance

These serial Godot 4.6.3 runs used the same 1280×720 Linux Mesa llvmpipe
compatibility renderer, separate test profiles and the same map, staged
siege and 24 legally placed paid machines. The fixture uses Hell Campaign
Stage 5 on Cursed Mansion seed 73. It stages the economy, allied sleep
state, Hunter approach, siege progress and counters. The normal game
update then advances 24 warmup frames and 150 measured frames at one
model step per frame and 24 steps per model second.

The baseline disables the tactical siege gate in the **same source
commit** `9bc53ea`. Candidate uses the gate as shipped. All six runs
passed 102 checks. Geometry and sampled initial, warmup and final
gameplay hashes matched. Each timed window contained three real Hunter
strikes and six machine shots. Candidate recorded one live productive
commitment event in every window. The fixture covers continued siege
and its cue. Switching travel is covered by the separate simulation
and capture runs.

## Median / p95 milliseconds

| Preset | Baseline frame | Candidate frame | Baseline CPU update | Candidate CPU update |
| --- | ---: | ---: | ---: | ---: |
| Standard | 39.05 / 56.72 | 40.61 / 57.30 | 5.33 / 7.11 | 5.55 / 8.27 |
| Low | 34.90 / 43.32 | 36.60 / 52.85 | 5.33 / 6.87 | 5.48 / 8.96 |
| Low repeat, candidate timed first | 36.44 / 45.47 | 34.49 / 42.31 | 5.41 / 6.83 | 5.28 / 6.55 |

Frame time includes drawing and frame waits. CPU update is the measured
full game update before rendering. The first Low pass had a higher
candidate p95. Its reverse-order repeat had a lower candidate p95.
Drawing command counts matched within each pair, and neither run order
advanced the cgroup throttling counter. These samples show run variance
and leave native Windows and Intel UHD unmeasured.

[Standard baseline trace](final-medium-baseline/benchmark.json) ·
[Standard candidate trace](final-medium-candidate/benchmark.json) ·
[Low baseline trace](final-low-baseline/benchmark.json) ·
[Low candidate trace](final-low-candidate/benchmark.json) ·
[Low repeat baseline](repeat-low-baseline/benchmark.json) ·
[Low repeat candidate](repeat-low-candidate/benchmark.json) ·
[Combat viewport](final-medium-candidate/active-combat-720.png)

## Reproduce

Run with an available graphical display. Select `medium` for Standard or
`low` for Low, and use separate output directories and fresh profiles for
`baseline` and `candidate`. Run the cases serially.

```sh
export NIGHTFALL_PROCEDURAL_MAPS_V2=1 NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_FULL_ROOM_GRID=1
XDG_DATA_HOME="$(mktemp -d)" godot --path . --resolution 1280x720 \
  --audio-driver Dummy --disable-vsync \
  --script tools/nightmare_maps/measure_hell_tactics.gd \
  -- /tmp/nightfall-v21-candidate medium candidate
```
