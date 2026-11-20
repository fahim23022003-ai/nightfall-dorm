# Procedural Nightmare Maps V2 in Godot

The comparison uses 12 native Godot viewport captures across all ten
families. Every image uses the same camera scale of **71.02 screen
pixels per 1,000 world units**. The contact sheet crops the same viewport
region in every image and retains its original scale. The main game uses
an adaptive fit for each map and keeps the strategic view separate from
the detailed room. [Contact sheet](macro-layout-comparison.png)

| Family | Theme | Seed | Native 1280×720 viewport |
|---|---|---:|---|
| Ring Courtyard | Abandoned Dorm | 21 | [Screenshot](01-ring-21.png) |
| Branching Fork | Haunted Hospital | 54 | [Screenshot](02-branching-54.png) |
| Scattered Asymmetric | Forgotten Hotel | 111 | [Screenshot](03-scattered-111.png) |
| Long Spine | Underground Lab | 134 | [Screenshot](04-spine-134.png) |
| Zigzag Staircase | Cursed Mansion | 161 | [Screenshot](05-zigzag-161.png) |
| Radial Spokes | Abandoned Dorm | 197 | [Screenshot](06-radial-197.png) |
| Twin Wings | Haunted Hospital | 218 | [Screenshot](07-twin_wings-218.png) |
| Labyrinth | Forgotten Hotel | 263 | [Screenshot](08-labyrinth-263.png) |
| Asymmetric Courtyards | Underground Lab | 284 | [Screenshot](09-courtyards-284.png) |
| Mixed Hybrid | Cursed Mansion | 316 | [Screenshot](10-hybrid-316.png) |
| Ring Courtyard | Abandoned Dorm | 351 | [Screenshot](11-ring-351.png) |
| Mixed Hybrid | Haunted Hospital | 388 | [Screenshot](12-hybrid-388.png) |

## Real Hunter routes

The 1280×720 film follows five production Hunter approaches. Each isolated
fixture stages a starting point and target. Godot then advances the existing
Hunter update through normal model ticks. The gold trail records the
Hunter's actual position after each simulation step. Route geometry,
step distance and arrival at the legal door approach are checked in
every chapter. The film uses five simulation ticks per recorded frame
and has no audio track. [Film](hunter-routes.mp4) ·
[Sampled positions and engine receipt](capture.json)

| Route | Actual travel | Straight-line distance | Arrival frame |
|---|---:|---:|---|
| Ring Courtyard | 661 units | 545 units | [Screenshot](hunter-route-ring.png) |
| Branching Fork | 1,423 units | 1,227 units | [Screenshot](hunter-route-branching.png) |
| Scattered Asymmetric | 973 units | 801 units | [Screenshot](hunter-route-scattered.png) |
| Zigzag Staircase | 736 units | 603 units | [Screenshot](hunter-route-zigzag.png) |
| Labyrinth | 1,304 units | 812 units | [Screenshot](hunter-route-labyrinth.png) |

Native input checks covered inspecting a room without spending, mouse-wheel
zoom, middle-button drag, and restoring the adaptive fit with **0**. The
Endless setup verified that three blank seeds selected different recent
families and that typing the same explicit seed twice reproduced the same
geometry hash. [Reset to fit](overview-input-reset.png) ·
[Engine log](engine.log)

## Reproduce

Run Godot 4.6.3 with a display and isolated writable data directory. Add
`--stills` after the output directory to skip route sequences. Raw route
frame sequences use 20 frames per second.

```sh
NIGHTFALL_PROCEDURAL_MAPS_V2=1 NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_FULL_ROOM_GRID=1 \
  godot --path . --resolution 1280x720 --audio-driver Dummy --disable-vsync \
  --script tools/capture_nightmare_maps_v2.gd -- /tmp/nightfall-macro-capture
```
