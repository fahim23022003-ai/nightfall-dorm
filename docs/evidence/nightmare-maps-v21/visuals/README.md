# Hell Campaign siege tactics in Godot

The 1280×720, 12.5-second film shows two controlled encounters in the
same Ring Courtyard map from Abandoned Dorm seed 21. The fixture prepares
room levels, available funds and the observed siege interval. It buys
machines through the regular Full Room Grid transaction and advances
Godot's game loop for every tell, strike and movement sample. The
playback is silent. [Three-chapter film](hell-tactics.mp4)

| Decision | What the capture verifies | Real viewport evidence |
|---|---|---|
| Stay in a productive siege | The Hunter sees 765.55 net damage in the staged siege window and commits. A native **R** press pays 20 gold and restores 70 HP. The Hunter delivers four further strikes at that door. | [Commit tell](hell-commit-warning.png) · [Paid repair](hell-paid-repair.png) |
| Change a stalled approach | The current breach estimate is 55.56 seconds and the alternate route is scored at 23.45. The incoming tell appears for the player. The Hunter covers 2,157 world units around the map and reaches the player's door in the Attack state. | [Inbound tell](hell-switch-warning.png) · [Arrival and route](hell-switch-arrival.png) |

The video shows commitment and counterplay at real simulated pace. The
last chapter advances five fixed simulation steps per recorded frame.
Its gold trail contains actual sampled positions from the first movement
tick. The test verifies every movement sample against walkable geometry
and the Hunter's movement budget. [Event and movement receipt](capture.json) ·
[Engine log](engine.log)

## Reproduce

Use Godot 4.6.3 in a graphical session with an isolated test profile.

```sh
NIGHTFALL_PROCEDURAL_MAPS_V2=1 NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_FULL_ROOM_GRID=1 \
  godot --path . --resolution 1280x720 --audio-driver Dummy --disable-vsync \
  --script tools/capture_hell_tactics.gd -- /tmp/hell-tactics-capture
```
