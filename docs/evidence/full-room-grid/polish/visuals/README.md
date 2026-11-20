# Full Room Grid polish in Godot

[Placement and room HUD video](grid-hud-polish.mp4) shows the native 1280×720 game at 24 fps. It has two chapters and no audio track. The isolated, seeded Endless fixture claims and sleeps in the room through normal actions. The harness stages credits and room levels, buys the dense layout through the match model, and advances normal gameplay ticks during the fight.

| Interaction | Checkpoint `90659d7` | Polished |
| --- | --- | --- |
| Clockwise rotation | [Rotated preview](checkpoint/01-rotated-preview-720.png) | [Rotated preview](01-rotated-preview-720.png) and [toolbar rotation](00a-toolbar-rotation-720.png) |
| Blocked placement | [Door obstruction](checkpoint/02-blocked-door-720.png) | [Door obstruction](02-blocked-door-720.png) and [machine overlap](04-blocked-overlap-720.png) |
| Dense placement | | [24 paid machines and floor plan](07-dense-grid-720.png) |
| Neighboring machines | [Native floor selection](checkpoint/08a-crowded-selection-720.png) | [Selected machine](08a-crowded-selection-720.png) and [selected neighbor](08b-neighbor-selection-720.png) |
| Machine picker | | [24-row list](08c-machines-list-720.png) and [selection from a visible row](08d-picker-selected-720.png) |
| Live door HP and room trait | [Same Stalker attack](checkpoint/09-door-hp-and-room-trait-720.png) | [Live Stalker attack, door HP and Fortified trait](09-door-hp-and-room-trait-720.png) |

The toolbar keeps the previous floor pointer and re-snaps the footprint on rotation. Shift+Q restores the earlier placement. Rejected placement and both selection methods preserve the wallet. Clicking a selected row again reopens its inspector. The matched runs have identical paid layouts, Dynamo purchase, ending wallet and combat. That fight applies 18.04 door damage on one Hunter attack with 15 weapon launches. The local `Fortified` card shows +15% door durability and −10% bed income. After paid repairs the lower HUD and the warning show 2068/2070 door HP. [Exact comparison](comparison.json) · [Polish run receipt](polish-capture.json) · [Engine log](engine.log)

## Reproduce

Run in a graphical session from the repository root with a new output directory.

```sh
NIGHTFALL_FULL_ROOM_GRID=1 NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_GRID_POLISH_FINAL=1 \
  godot --path . --audio-driver Dummy -s tools/capture_room_grid_polish.gd -- /tmp/nightfall-grid-polish
```

For the comparison, run the same harness on `90659d7` with `NIGHTFALL_GRID_POLISH_FINAL` unset. Set `NIGHTFALL_GRID_POLISH_STILLS=1` to capture lossless stills and the test receipt without the video frame sequence.
