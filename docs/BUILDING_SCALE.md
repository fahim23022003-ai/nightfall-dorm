# Nightfall Dorm Building Scale Preview

Extract the Windows x64 ZIP and run **Play Building Scale Preview.cmd**.
This launcher uses its own test profile. **Play Close Quarters Preview.cmd**
uses the previous building sizes for fresh matches in the established
Living Nightmare profile. No existing floor plan is enlarged on load.

The grid retains 16-unit cells. Compact 3×3 footprints are used for Frost,
Economy, Enhancement and Decoy. Dynamo and Ward Antenna are 3×4. Repair,
Flame, Auto Repair and Plasma are 4×3. Needle, Shock and Shield are 4×4.
Arc uses 5×4 and Mirror Barrier uses 5×2. Rotation swaps the footprint
axes. Upright machinery is drawn from its ground anchor, with turret
barrels independently aiming toward their targets. Bed and Door keep
their established openings, access paths and reference proportions.

New grids write construction metadata version 2. Existing layouts use
the rules recorded in their saves. Geometric validation, the placement
ghost and weapon launch sockets consume the same versioned rules.
Prices, refunds and permanent currencies are unchanged. NPC builders
retain their authored pads and economic rules.

## Room capacity

All 300 sampled rooms fit a paid Needle, Dynamo and Repair Station
combination. The table shows the minimum, median and maximum legal
Needle counts in a greedy fill on 60 matched dorm rooms. Actual capacity
depends on layout, orientation, and machine mix.

| Room shape | Rooms | Original | Larger scale |
| --- | ---: | ---: | ---: |
| Rectangle | 11 | 77 / 95 / 116 | 15 / 20 / 23 |
| U | 14 | 65 / 80 / 106 | 11 / 14 / 19 |
| L | 11 | 52 / 68 / 84 | 8 / 11 / 16 |
| Long | 12 | 72 / 75 / 82 | 12 / 14 / 16 |
| Zigzag | 12 | 58 / 70 / 83 | 9 / 13 / 16 |

[Capacity and transaction tests](evidence/phase181/model/capacity.log)

## Corridor performance

The renderer composites corridor floors, trim and lamps into padded tiles
and draws visible tiles. Existing corridor geometry and navigation remain
authoritative. The equal-workload Godot test used the original grid for both
builds and matched map, camera, machines, and combat state at 1280×720.
Times are from Linux Mesa llvmpipe.

| Machines | Preset | Before median / p95 (ms) | After median / p95 (ms) |
| ---: | --- | ---: | ---: |
| 24 | Standard | 61.37 / 75.75 | 56.16 / 75.28 |
| 24 | Low | 43.98 / 54.15 | 38.03 / 48.76 |
| 40 | Standard | 72.48 / 89.05 | 71.85 / 96.83 |
| 40 | Low | 46.82 / 59.05 | 38.55 / 47.58 |
| 60 | Standard | 84.18 / 119.40 | 78.52 / 95.79 |
| 60 | Low | 49.64 / 58.56 | 43.99 / 50.72 |

Standard improved at all three medians, while p95 worsened by 8.7% in the
40-machine sample. Standard corridor submission and preparation fell from
0.405–0.416 ms to 0.060–0.061 ms. In the 60-machine Standard sample, median
draw calls fell from 638.5 to 436.5 with about 7.74 MiB of cached RGBA pixels.
[Raw frames, memory readings, fixture and matched screenshots](evidence/close-quarters/phase181/README.md)

The separate enlarged-grid test ran seven legally built machines during
active combat in Haunted Hospital, seed 10358. It used 120 rendered
frames per preset and recorded five shots and 140 real HP loss in each.
The measured Standard median/p95 was 39.20/49.99 ms (614 median draw
calls), and Low was 37.57/45.40 ms (607 median draw calls). Godot reported
about 146 MiB static memory and 118 MiB video memory in both runs.
[Standard receipt](evidence/phase181/visual/practical-standard.json) ·
[Low receipt](evidence/phase181/visual/practical-low.json)

## Fairness

The Standard Branching replay used seed 28520660 and Room 4. A vacant NPC
room caused the Witch to skip an initial siege under Close Quarters and
reach the player 35.7 seconds earlier. Allied damage fell from 2,376 to
1,458. The existing player defense lost, while two item-free Emergency Ward
and repair openings won under both footprint versions. The original
item-free Bed 3 and crossfire openings also still won on Hell Labyrinth
seed 10358, Room 2. Combat balance was left unchanged.
[Replays and event traces](evidence/phase18-1/fairness/README.md)

## Verification

The save tests reload existing and enlarged layouts with the opposite
launcher flags, preserve building identity and investments, and reject
unsupported future construction rules. The desktop Godot tutorial
completed all 19 steps under the enlarged rules.

- [Original save](evidence/phase181/model/save-0.log)
- [Enlarged save](evidence/phase181/model/save-1.log)
- [Tutorial run](evidence/phase181/model/tutorial.log)
- [Tutorial Needle placement](evidence/phase181/model/tutorial/10-place-needle.png)
- [Tutorial Dynamo placement](evidence/phase181/model/tutorial/14-place-dynamo.png)
- [Before/after visual gallery and combat recording](evidence/phase181/visual/README.md)
- [Regression logs](evidence/phase181/regressions)
- [Windows archive receipt and SHA-256](evidence/phase181/windows/README.md)
