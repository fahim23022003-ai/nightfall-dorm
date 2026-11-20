# Survivor Room Rush verification

The opening puts the human and five NPCs at the same legal exterior
coordinate. Map seed and saved attempt ID determine that coordinate
without advancing combat RNG. Candidate spawns must connect to all six
rooms and offer at least one legal approach within twelve seconds at
human walking speed. The human retains 180 world units/s and the new NPCs
walk at 90 world units/s. Destination scoring uses path length, approach
exposure, bot preferences, and a bounded traffic penalty of 220 units per
approaching opponent with a two-opponent cap. A destination remains vacant
and claimable until the survivor actually arrives and claims it.

Player and NPC claims share one model transaction. The focused rules
test also verifies the human's claim when both sides are at the room in
the same simulation step. A runner already inside the room can leave
through the doorway if the rival claims and shuts it. New Endless
checkpoints store pending NPC positions, targets, spawn, and attempt ID.
An earlier checkpoint still resumes from its saved positions with legacy
opening behavior.

The model suite completed **507 checks** across five fixed, five V1,
five V2, and one legacy map. It covers physical arrival, exact movement
speed, finish-to-bed paths, legal egress, and old and new save restores.
The broad run emitted a Godot ObjectDB warning during exit. The focused
tie and checkpoint rerun completed 44 checks and exited without that warning.
[Model gates](model-gates.log) · [Focused rerun](tie-and-save-rerun.log)

## V2 opening samples

The 35-seed sample covered all ten macro families and all five themes.
Every sampled shared location was valid, and every NPC completed its
physical claim. The harness advances the opening in quarter-second steps
with the human idle and the Hunter and economy absent. It measures route
completion, leaving combat balance for a separate check.

| Measurement | Median | Maximum |
| --- | ---: | ---: |
| First NPC claim (s) | 3.50 | 18.50 |
| Third NPC claim (s) | 39.25 | 63.50 |
| Fifth NPC claim (s) | 75.75 | 156.25 |
| Shortest human room approach (s) | 1.66 | 9.22 |
| Shared spawn and initial paths (ms) | 7.38 | 46.60 |

The widest sampled spine race finished its fifth claim at 156.25 seconds.
The last NPC rerouted across distant rooms with the human idle. The spawn
still gave the human a 5.04-second route to a valid room. These times
describe the race-only Linux fixtures. [Raw seed matrix](v2-seed-matrix.log)

## Reproduce

Use Godot 4.6.3 with an isolated profile and both commands from the
repository root.

```sh
godot --headless --path . --script tests/survivor_room_rush.gd
godot --headless --path . --script tools/nightmare_maps/measure_room_rush.gd
```
