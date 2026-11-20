# V2.2 opening estimates and siege counterplay in Godot

The native 1280×720 capture uses the **Ring Courtyard** family in
Abandoned Dorm, seed **21**. The forecast stills show a native map
selection before claiming a room. The siege chapters use matched Hell
fixtures with identical starting HP, paid towers and goals. The fixture
sets the encounter clock and the elapsed reassessment window. Normal
game ticks produce the strikes, decisions and movement.

| Moment | Verified behavior | Godot capture |
|---|---|---|
| Hard opening | Inspecting vacant Room 01 displays approximately 3s of survivor travel and 12s of Hunter travel if targeted first. | [Hard estimate](vacant-room-opening-hard.png) |
| Hell opening | The same room shows the same survivor route and approximately 11s of Hunter travel if targeted first. | [Hell estimate](vacant-room-opening-hell.png) |
| Ordinary siege | Six strikes deal 113.99 HP. The Hunter keeps attacking the productive door and shows **HUNTER COMMITS · HOLD THE DOOR**. | [Commit tell](ordinary-siege-commit-tell.png) |
| Paid repair | A native **R** press spends 20 gold and restores 70 HP. The door still loses a net 43.99 HP in the reassessment window. | [Paid repair](paid-repair.png) |
| Defense-driven reroute | The Hunter estimates its defended door at 55.00s and the alternative at 23.46s. **DEFENSE HELD · HUNTER REROUTING** appears. The Hunter then reaches Room 02 in the Attack state. | [Reroute tell](paid-defense-reroute-tell.png) · [Alternate door](alternate-door-arrival.png) |

The 11.55-second film starts with the two opening estimates, shows the
decisions at normal simulated pace, and advances five simulation ticks
per frame for the travel segment. The gold trace contains actual
positions from the moment the map opened. The Hunter moves 2,059 world
units during that recorded route and each step stays within the
walkable surfaces and movement budget. The film is silent. [Film](siege-counterplay.mp4) ·
[Engine log](engine.log) · [Model events and route samples](capture.json)

## Reproduce

Use Godot 4.6.3 in a graphical session with an isolated test directory.

```sh
NIGHTFALL_PROCEDURAL_MAPS_V2=1 NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_FULL_ROOM_GRID=1 \
  godot --path . --resolution 1280x720 --audio-driver Dummy --disable-vsync \
  --script tools/capture_siege_counterplay.gd -- /tmp/nightfall-counterplay
```
