# Close Quarters fairness and Building Scale replay

These earned-action Godot 4.6.3 traces start at the Phase 18 checkpoint
`af1a113431931c12b49c2dbfb4be0aaca57a5896` and compare V2, V3, and
V3 with substantial footprints. The source script instruments actual
Hunter decisions, Room Rush, attack and construction events. No match
health, currency, hostility or NPC ownership was staged.

## Standard Branching

The exact case was Story Level 33, Witch, seed 28520660, Room 4,
ordinary early Needle policy, with player spawn (2576, 912).
The original outcome reproduced in both arms. The new footprints
kept the same terminal time and removed 27 less Hunter HP in this case.

| Same policy | V2 | V3 | V3 + substantial footprints |
| --- | ---: | ---: | ---: |
| First Hunter encounter, any room | 55.20 s | 64.35 s | 64.35 s |
| First contact with Room 4 | 216.45 s | 180.75 s | 180.75 s |
| Hunter HP at that contact | 1,887.92 | 2,963.36 | See trace |
| Room 4 door breach | — | 207.75 s | 207.75 s |
| Terminal outcome and time | Victory 234.15 s | Defeat 210.60 s | Defeat 210.60 s |
| Hunter HP remaining | 0 | 528.92 | 555.92 |

In V2 the Witch chose rooms 1, 2, 6 and 4. In V3, Room 1 was still
vacant at the first Hunter decision (42.15 seconds), so the Witch chose
rooms 2, 6 and 4. The two initial graph costs were the same in both
versions (912 for Room 1, 1,600 for Room 2). The estimated final
Room 6 → Room 4 leg was about 592 units in both. The critical change was
the earlier dispatch to the player room, at 172.80 instead of 208.05
seconds. The altered NPC assignments in Rooms 1, 2 and 6 changed
the defenders and allied exposure. Allies dealt 2,376 Hunter HP damage
in V2 and 1,458 in V3. Neither case used a Haunted Hall. Both opened
with 4,532 Hunter HP and 135 door HP. [V2 timeline](branching-0.json) · [V3 timeline](branching-1.json) · [Substantial grid timeline](branching-scaled.json)

Four additional old-grid V3 item-free policies lost. The closest left
41.90 Hunter HP at 229.35 seconds. Two focused item-free counterplays
then won in the same V3 room and starting conditions with both footprint
sizes. Both used paid wards against imminent strikes and reserved manual
repairs for full healing windows. The reserve variant also stopped
other spending under direct attack. The substantial-grid wins took
269.55 and 270.90 seconds. Each blocked 120 damage with two paid wards,
and the player paid for 23 and 24 repairs, respectively. Actual Needle
and Heavy footprints in the successful scaled run were 64×64 and
80×64. The unchanged early-Needle script loses this matchup, which
remains winnable through existing defensive actions. [Exploratory alternatives](branching-alternates-results.json) · [Old-grid wins](branching-ward-0.json) · [Scaled wins](branching-ward-1.json)

## Hell Labyrinth opening

On seed 10358, Room 2, the player entered and reached bed in 3.00
seconds in all arms. The first Hell strike remained at 47.10 seconds
in V3 with new footprints (48.00 seconds in V2). Both previous
item-free winning openings won again. The two item-free losing
controls still lost. No scripted trial consumed an item.

| Hell opening | V2 | V3 | V3 + substantial footprints |
| --- | ---: | ---: | ---: |
| Early Bed 3 | Victory 435.60 s | Victory 381.90 s | Victory 357.15 s |
| Early crossfire | Victory 439.35 s | Victory 403.80 s | Victory 435.75 s |
| Approach fire | Defeat 63.00 s | Defeat 62.10 s | Defeat 62.10 s |
| Frost/Arc | Defeat 105.30 s | Defeat 104.40 s | Defeat 104.40 s |

The Standard and Hard Bed 3 controls won in all three arms. These
are deterministic policies and starting conditions, so the result
applies to the tested matches. [V2](labyrinth-0.json) · [V3](labyrinth-1.json) · [V3 substantial](labyrinth-scaled.json)

## Reproduce

Use an isolated XDG profile. Enable `NIGHTFALL_PHASE16=1`.
Set `NIGHTFALL_CLOSE_QUARTERS` to `0` or `1`, and
`NIGHTFALL_BUILDING_SCALE=1` to enable substantial footprints.

The Branching recorder uses the same stock source as the Phase 16
matrix, which can be generated with
`tools/nightmare_tactics/check_phase16_story_matrix.gd -- earn /tmp/nf-stock.json`.
The tested Branching policies unequip that stock. Pass an absolute
result and fixture path to the relevant headless script.

```sh
godot --headless --path . --audio-driver Dummy \
  -s tools/phase18/check_branching_timeline.gd -- \
  /tmp/branching.json /abs/branching-fixture.json /tmp/nf-stock.json 0 1
godot --headless --path . --audio-driver Dummy \
  -s tools/nightmare_tactics/check_starting_rooms.gd -- \
  /tmp/labyrinth.json v23 /abs/labyrinth-fixture.json
```
