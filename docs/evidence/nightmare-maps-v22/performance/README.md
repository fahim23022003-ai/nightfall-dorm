# V2.2 active combat performance

The serial runs compare the rendered V2.1 and V2.2 siege policies in the
same Godot 4.6.3 source by toggling `fair_siege_enabled`. Both keep V2.1
tactics enabled. All four runs used 1280×720 Linux Mesa llvmpipe and passed
103 checks. The benchmark uses Cursed Mansion seed 73 in Hell Campaign,
with a 24-machine room built through legal paid placements. It stages the
wallet, mid-siege door health, landed damage and the normal reassessment
clock. The subsequent fight runs in the real game update loop.

Map, staged siege, initial and warmup hashes matched across all cases.
Each trace runs 24 warmup and 150 measured frames with fixed 1/24-second
simulation steps. Both presets produce the same outcome within each
policy. V2.1 stayed at the first door with 3 strikes and
6 machine shots. V2.2 struck 2 times and
triggered 6 machine shots before and during the reroute.
The candidate recorded `defense_delays_breach` at 62.79
model seconds. It switched from room 2 to room
5 with breach costs 61.18
and 11.49, then spent 108
of the measured frames traveling.

## Timings

Values are median / p95 milliseconds. Frame timing includes drawing and
frame waits. CPU update measures the game update before drawing.

| Preset | V2.1 frame | V2.2 frame | V2.1 CPU update | V2.2 CPU update |
| --- | ---: | ---: | ---: | ---: |
| Standard | 39.50 / 47.63 | 39.06 / 48.33 | 5.49 / 6.82 | 5.33 / 7.06 |
| Low | 36.46 / 44.60 | 35.75 / 45.70 | 5.45 / 6.55 | 5.35 / 6.16 |

The initial scene matches but the policies generate different play after
reassessment. These measurements characterize continued siege versus a
live reroute, so individual rendering and pathfinding costs are unisolated.
Native Windows and Intel UHD remain untested.

[Standard V2.1 trace](medium-baseline/benchmark.json) ·
[Standard V2.2 trace](medium-candidate/benchmark.json) ·
[Low V2.1 trace](low-baseline/benchmark.json) ·
[Low V2.2 trace](low-candidate/benchmark.json) ·
[Exact measured source hashes](source.sha256)

## Reproduce

Use an available graphical display and a fresh profile for each serial
run. Pass `medium` for Standard or `low` for Low, and `baseline`
for V2.1 or `candidate` for V2.2.

```sh
export NIGHTFALL_PROCEDURAL_MAPS_V2=1 NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_FULL_ROOM_GRID=1
XDG_DATA_HOME="$(mktemp -d)" godot --path . --resolution 1280x720 \
  --audio-driver Dummy --disable-vsync \
  --script tools/nightmare_maps/measure_fair_siege.gd \
  -- /tmp/nightfall-v22-candidate medium candidate
```
