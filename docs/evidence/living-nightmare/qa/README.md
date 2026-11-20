# Independent Living Nightmare QA

The Story catalog and state suite checks all 50 titles, five map themes,
all six Hunters, and all ten selected V2 topology families. It completes a
separate Story track through Level 50 to verify advancement, checkpoints,
retries, and one shared first-clear credit. This is a progression test.

The profile integration suite migrates an isolated old Campaign profile
with ordinary completed matches, a purchased repair kit, perk, rank XP,
RM and audio preferences. It compares the original backup byte for byte,
verifies that another profile write preserves it, exercises rollback on a
failed disk write, and tests read-only recovery for damaged Story data.
It also loads the existing earned Wave 45 checkpoint after migration,
checks the exact retained machine investments, and tests prevention of
an accidental Endless replacement.

The game integration loads the actual scene, opens the preview Story
preparation through the primary button flow, and starts the correct
mission. The prepared finale fixture sets historical clears and a
defended room. Actual Reaper transformation, Crimson Execution, terminal
victory, Story settlement and completion cap run through the game's
production methods. This fixture isolates result and persistence
behavior from economic reachability.

[Story state checks](living_story_progress.log) ·
[Profile and game integration](living_story_integration.log)

## Complete earned matches

A separate 18-match matrix tested both endpoints through actual
simulation with no extra starting resources or items. Each match began
occupying the bed with 25 Gold and 0 Electricity. The tested policies paid
for normal income upgrades, defenses, repairs and purchases every 0.90
simulated seconds. The profile seed base was 91737. Rooms and policies in
each difficulty were Room 1 balanced, Room 3 early bed, and Room 5 early
crossfire. The driver did not test the initial walk or modify enemy stats.

| Story Level | Normal | Long Night | Hell |
| --- | ---: | ---: | ---: |
| 1 · The Haunted Dorm | 3/3 | 2/3 | 0/3 |
| 50 · Dawn or Oblivion | 3/3 | 2/3 | 2/3 |

The seven final victories all defeated a transformed Reaper. The two
Hell wins used early bed and early crossfire and took 435.45 and 430.80
simulated seconds respectively. The balanced room lost on Hell before
transform. These fixtures demonstrate concrete winning configurations
and leave open the win rate over different profiles, seeds and strategies.
All 18 trials reached genuine terminal model states and passed the wallet
and setup checks.

The same Level 1 seed received nine further Hell runs. Needle-first at
all six rooms still lost with a 0.90-second decision cadence. Its Room 3
loss left 68.97 Hunter HP. Three more Room 3 runs called the usual combat
and economy commands every 0.30 seconds. Needle-first, early bed and
early crossfire then won in 379.65, 391.95 and 389.40 seconds. All runs
used standard match commands, the same economy and the same Hunter
configuration. The narrower fixture shows that
prompt decisions can matter on Hell and makes no claim about typical
manual win rates.

[Earliest mission match receipts](battles-1.json) ·
[Final mission match receipts](battles-50.json) ·
[Hell room sweep](battles-1-hell-openings.json) ·
[Hell Room 3 replay](battles-1-hell-room-three.json)

## Fallback regressions

| Suite | Checks | Failures |
| --- | ---: | ---: |
| Story state and catalog | 620 | 0 |
| Story integration and profile migration | 65 | 0 |
| Legacy Campaign profile | 89 | 0 |
| Legacy Campaign flow and cross-process save | 148 | 0 |
| Audio lifecycle | 13 | 0 |
| Boss mechanics | 153 | 0 |
| V2 map persistence | 62 | 0 |
| Full Room Grid save and earned migration | 61 | 0 |
| Scene smoke | 33 | 0 |
| Total | 1244 | 0 |

## Reproduce

Use Godot 4.6.3 in a writable, isolated profile directory. The graph and
combat receipts are Linux simulations. Human and Intel UHD approval remain
separate.

```sh
XDG_DATA_HOME=/tmp/nightfall-story-state godot --headless --script tests/living_story_progress.gd
XDG_DATA_HOME=/tmp/nightfall-story-user godot --headless --script tests/living_story_integration.gd
XDG_DATA_HOME=/tmp/nightfall-story-battles godot --headless --script tests/living_story_battles.gd -- /tmp/story-final.json 50
XDG_DATA_HOME=/tmp/nightfall-story-hell godot --headless --script tests/living_story_battles.gd -- /tmp/story-hell.json 1 --hell-room-three
```
