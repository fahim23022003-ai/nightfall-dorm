# Nightmare Maps V2 performance

These matched **1280×720** Godot 4.6.3 runs used the compatibility renderer on
Linux Mesa llvmpipe. Standard and Low ran serially with separate test profiles.
Each viewport scene records 120 actual rendered frames after 24 warmup frames.
The overview and planning grid advance presentation while holding the gameplay
state fixed. The combat trace runs the full game process at a fixed 24 model
steps per second. The runs used the dummy audio driver.

The fixture uses Cursed Mansion seed 73, a Mixed Hybrid layout with a U-shaped
player room and 24 legally placed and paid buildings. It stages the wallet,
room levels, allied sleep state and the Hunter's first contact at the door.
Real attacks, damage, building effects and AI run during the timed combat
window. The geometry digest and sampled gameplay digests match between
presets.

## Frame timing

All values are in milliseconds. The active sample recorded 5 Hunter
strikes and 5 weapon shots for both presets.

| Scene | Standard median / p95 | Low median / p95 |
| --- | ---: | ---: |
| Map overview | 20.46 / 26.93 | 16.73 / 22.90 |
| 24-building room with planning grid | 32.07 / 36.25 | 31.20 / 42.28 |
| Active combat | 36.03 / 44.38 | 33.74 / 39.59 |
| Active combat CPU update | 5.64 / 6.90 | 5.59 / 6.52 |

The overview submitted a median of 554
draw calls on Standard and 452 on Low.
Each run passed 105 checks. [Standard raw traces](medium/benchmark.json) ·
[Low raw traces](low/benchmark.json) · [Overview screenshot](medium/overview-720.png) ·
[Crowded room screenshot](medium/crowded-room-720.png) · [Combat screenshot](medium/active-combat-720.png)

## Navigation timing

The fixture has 49 exterior navigation points and 51 links. Each
preset ran 132 legal routes and 132 alternate requests. 56
alternate requests returned an actually different route.

| Query | Standard median / p95 | Low median / p95 |
| --- | ---: | ---: |
| Primary route | 0.35 / 0.51 | 0.36 / 0.54 |
| Alternate route request | 0.46 / 0.80 | 0.48 / 0.79 |
| Score all six rooms from one origin | 0.48 / 0.56 | 0.38 / 0.60 |

Route samples time the real single-threaded model APIs without rendering
between queries. The benchmark checks all ordered destinations across the
spawn sites, six doors and four Hall centers, and repeats each with the
alternate route option. It also times the Hunter's six-room route scoring
from each site. The comparison keeps the same route sites and graph across
presets. CPU timings for active combat include the simulation, UI update and
presentation update before the frame is submitted.

The full combat frame took about six times as long as its measured CPU
update at the median. That gap includes rendering and frame waits. Route
queries remained under 1 ms at p95 in this fixture. Low improved every
median and both overview and combat p95. Its planning-grid p95 was higher
in this sample. Native Windows, Intel UHD and human playtesting remain
unverified.

## Reproduce

Run these two commands serially on a real display. Replace
`/tmp/nightmare-v2-standard` with `/tmp/nightmare-v2-low` and `medium`
with `low` for the second run.

```sh
export NIGHTFALL_PROCEDURAL_MAPS_V2=1
export NIGHTFALL_VISUAL_REBIRTH=1
export NIGHTFALL_FULL_ROOM_GRID=1
XDG_DATA_HOME="$(mktemp -d)" godot --path . --resolution 1280x720 \
  --audio-driver Dummy --disable-vsync \
  --script tools/nightmare_maps/measure_nightmare_maps_v2.gd \
  -- /tmp/nightmare-v2-standard medium 73
```
