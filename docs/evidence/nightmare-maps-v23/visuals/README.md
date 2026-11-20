# Hell Labyrinth opening in Godot

The captured match is Hell Stage 2, **Labyrinth seed 10358, Room 02**.
It starts at the ordinary survivor spawn and uses the **early Bed 3**
opening. Real Godot input inspects the map and claims the room, while
the automated driver sends movement through the production collision
checks and transactions through the regular purchase methods. The
test begins with 25 gold and zero Electricity. The item-free game
uses earned income and runs through the actual victory condition.

| Moment | What the capture shows | Godot viewport |
|---|---|---|
| Before claim | **Fast Hunter route** on vacant Room 02, with about 3s to the entry and 7s for the Hunter if it targets this door first. | [Opening forecast](labyrinth-room-02-opening-forecast.png) |
| Claimed at 2.4s, asleep at 3s | Real walk through the room doorway and to within sleep range of the bed. | [Bed entry](normal-bed-entry.png) |
| About 31s | Save for Bed 3 and pay its 85 gold cost after buying Bed 2. | [Earned Bed 3](earned-bed-three.png) |
| About 36s and 39s | Pay 35 gold for Door 2, then 20 gold for the first Needle placed to cover the approach. | [Paid setup](earned-bed-door-and-needle.png) |
| 48s, then about 51s | First real strike on the player door, followed by a 14-gold repair that restores 66.18 HP. Three purchased Needles cover the approach by first contact. | [First strike](first-live-door-strike.png) · [First paid repair](first-earned-repair.png) |
| 435.60s | Clear Stage 2 in the exact model run after the early defense opening. | [Result](real-run-outcome.png) |

The 1280×720 film is silent. It shows the pre-claim forecast, movement,
the early purchase sequence, live contact and the final result. The walk
and combat highlights show one real 0.15s simulation step per frame and
play at 1.8× speed. The result still uses an identical rerun and waits
for the game's victory panel to finish appearing. [Film](hell-labyrinth-opening.mp4) ·
[Timed game events and route samples](capture.json) · [Capture log](engine.log) ·
[Result rerun log](result-engine.log)

## Reproduce

Use Godot 4.6.3 in a graphical session with an isolated test directory.

```sh
NIGHTFALL_PROCEDURAL_MAPS_V2=1 NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_FULL_ROOM_GRID=1 \
  godot --path . --resolution 1280x720 --audio-driver Dummy --disable-vsync \
  --script tools/capture_fair_start.gd -- /tmp/nightfall-labyrinth-opening
```
