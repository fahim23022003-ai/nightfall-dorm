# Native room-grid visuals

[Grid controls and live combat video](grid-input-and-combat.mp4) contains 233
native Godot frames at 1280×720 and 24 fps, for 9.71 seconds. It has two
chapters and no audio track. The first chapter uses scripted native input to
rotate and buy a Dynamo, reject door obstruction and overlap, move the same
instance and undo the move. The second chapter opens the planning view with
24 paid structures from all 15 placeable families, then advances live combat
against the Phase 14F Stalker at evolution 10.

- [Rotated footprint preview](01-rotated-preview-720.png) and [committed placement](03-rotated-placement-720.png)
- [Door obstruction](02-blocked-door-720.png) and [structure overlap](04-blocked-overlap-720.png)
- [Move preview](05a-safe-move-preview-720.png), [safe move](05-safe-move-720.png), and [undo](06-undo-720.png)
- [24-structure grid](07-dense-grid-720.png) and [live dense combat](08-dense-phase14f-combat-720.png)

The capture passed 209 checks. Both rejected clicks preserved the wallet.
Moving and undoing restored the original rotation and snapped center while
preserving the exact purchased instance. The live section recorded 15 launches
and a Stalker door strike applying 18.04 damage. Paid repairs restored most of
that damage. The HP bar and urgent warning are visible. At this density some
placed buildings overlap the room's small secondary trait text.

The isolated legacy-balance Endless fixture stages the wallet and the bed and
door levels. The dense layout is bought and upgraded through the model between
chapters. [Capture metadata](grid-capture.json) records the test conditions and
observed combat, and [the engine log](final.log) records the check count.

## Reproduce

Run in a graphical session from the repository root. Use a fresh capture
directory.

```sh
NIGHTFALL_FULL_ROOM_GRID=1 NIGHTFALL_VISUAL_REBIRTH=1 \
  godot --path . --audio-driver Dummy -s tools/capture_room_grid.gd -- /tmp/nightfall-room-grid
```
