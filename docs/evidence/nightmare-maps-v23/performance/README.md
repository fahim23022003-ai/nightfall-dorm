# V2.3 active combat performance

The serial runs compare V2.2 and V2.3 on the same Godot 4.6.3 source
with the `starting_room_review_enabled` test switch. Both keep V2.2
fair-siege tactics active. All four runs used 1280×720 Linux Mesa llvmpipe.
The V2.2 runs passed 104 checks each. The V2.3 runs passed
105 checks each.

The fixture uses Hell Campaign Stage 5, Cursed Mansion seed 73 and
a 24-machine room built through legal paid placements. Both cases start
during the same second siege. The Hunter's previously defended room has
its normal low-level door, the other allied doors are staged at high
levels, and the prior attack history, door HP and reassessment clock are
prepared. Combat, route selection and the subsequent actions use the
production update loop.

Map, staged siege, initial and warmup hashes matched across all cases.
Each trace runs 24 warmup and 150 measured frames with fixed 1/24-second
simulation steps. Both graphical presets produce the same result within
each version. V2.2 switched from room 2 back to
room 5 at 62.79 model seconds,
then spent 108 of the measured frames traveling.
V2.3 applied the memory and continued attacking room 2
for 150 of the measured frames. V2.2 saw
2 Hunter strikes and 6 machine shots. V2.3 saw
3 and 6.

## Timings

Values are median / p95 milliseconds. Frame timing includes drawing and
frame waits. CPU update measures the full game update before drawing.

| Preset | V2.2 frame | V2.3 frame | V2.2 CPU update | V2.3 CPU update |
| --- | ---: | ---: | ---: | ---: |
| Standard | 39.88 / 56.01 | 38.00 / 50.17 | 5.41 / 8.17 | 5.29 / 6.83 |
| Low | 37.87 / 47.20 | 37.76 / 48.38 | 5.62 / 7.53 | 5.66 / 6.87 |

The policies change the workload at reassessment. V2.3 stays under attack
effects while V2.2 moves away. These figures describe the two real scene
outcomes. They leave isolated rule costs, native Windows and Intel UHD
unmeasured.

[Standard V2.2 trace](medium-baseline/benchmark.json) ·
[Standard V2.3 trace](medium-candidate/benchmark.json) ·
[Low V2.2 trace](low-baseline/benchmark.json) ·
[Low V2.3 trace](low-candidate/benchmark.json) ·
[Exact measured source hashes](source.sha256)

## Reproduce

Use a graphical display and a fresh profile for each serial run. Pass
`medium` for Standard or `low` for Low, and `baseline` for V2.2 or
`candidate` for V2.3.

```sh
export NIGHTFALL_PROCEDURAL_MAPS_V2=1 NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_FULL_ROOM_GRID=1
XDG_DATA_HOME="$(mktemp -d)" godot --path . --resolution 1280x720 \
  --audio-driver Dummy --disable-vsync \
  --script tools/nightmare_maps/measure_starting_room_review.gd \
  -- /tmp/nightfall-v23-candidate medium candidate
```
