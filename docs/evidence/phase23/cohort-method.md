# Story match protocol

## Matches and pairing

The Phase 22.1 reference uses game sources at `3f9ec286`. The candidate uses the same executable model entry points and preview configuration, enabling `NIGHTFALL_HUNTER_INTELLIGENCE=1`. The Phase 22.1 launcher enables Living Dorm, Player First, Full Room Grid, V2 Close Quarters, Room Rush and Story chapter encounters. Mini-Hunters are off. Tests run in isolated profile directories under Godot 4.6.3.

Each split covers Levels 1, 6, 11, 17, 23, 27, 32, 36, 44 and 50. The authored missions cover all ten chapters and all six ordinary archetypes. Each mission has the same map, profile, spawn nonce and room preference across seven policies and three difficulties. The independent split uses a second seed family and a different preferred route-distance rank in the room race. There are **20 different mission maps**, with many intentional repeated comparisons on each. The 420 cases per arm are not 420 independent map seeds. The generator and Story catalog jointly determine geometries and enemy identities. All five real bot personalities compete for rooms.

The player walks from the shared spawn, claims a vacant room, reaches the bed and sleeps through real model interactions. Both arms receive the ordinary 25 Gold and zero Electricity. No outcome is scripted. One reference warm-up win earned the Gold Crate from First Blood and a Battery through an RM purchase. The archived inventory is copied for independent replays. Runs with the crate equip and spend only that one item. No-item runs unequip all consumables. Through Level 10 all policies use no rank perk. From Level 11 onward all policies equip the Silver door-frame perk unlocked on that same profile. Story position and prerequisite clear records are staged before each trial with the existing Phase 16 fixture. This represents return visits with conservative equipment and does not simulate grinding through a full career.

After each terminal outcome, the harness settles the real Story match, reloads the file, compares Story, inventory, RM Cash and XP, then confirms that a duplicate settlement is rejected. The report verifies equal map hashes, spawn positions, starting HP and wallet, room claims and time to bed. Rows preserve individual owner and room measurements. Main-Hunter damage excludes attacks on other enemies.

## Player policies

| Policy | Decision interval | Spending and reactions |
|---|---:|---|
| Passive | No purchases | Claims a room, sleeps and keeps all income. |
| Beginner | 7.2 s | Builds one Needle, basic bed, door and Dynamo, then upgrades the Needle once. Attempts repair below 20% HP. |
| Average | 3.6 s | Existing balanced plan buys income, mixed defenses and manual repairs. |
| Defensive | 2.7 s | Holds a door-upgrade reserve, responds to nearby sieges, adds Needles, repairs and Ward when eligible. |
| Offensive | 2.7 s | Needle-first build with early crossfire, then electricity and upgrades. |
| Skilled | 1.8 s | Invests early in the bed, electricity and crossfire, checks live siege pressure, pays for door upgrades, Ward or repairs, and builds Frost against selected physical archetypes. |
| Skilled with a Gold Crate | 1.8 s | Same code, one legitimate early crate activation consumes the first action. Later purchases can change when the extra Gold becomes available. |

At most one successful action occurs per policy decision. Selecting legal placement coordinates is automated. Players do not anticipate unrevealed RNG. These are policy comparisons, not predictions of human win rates. A beginner who stops expanding after one turret is a deliberately conservative example. A skilled profile may lose with ample resources because its purchase priorities and reaction cadence are fixed.

## Reproduction and interpretation

Use the Phase 22.1 reference checkout with `tests/phase23_campaign.gd` copied into `tests/`, or the released Phase 23 source with the documented opt-in disabled to reproduce the reference behavior. For the candidate set the opt-in to 1. After headless import, run the following shell commands from the Godot project directory. Each output is an ordinary JSON object per line.

```sh
out=$(mktemp -d)
export XDG_DATA_HOME="$out/profile"
export NIGHTFALL_HUNTER_INTELLIGENCE=1
godot --headless --path . --script res://tests/phase23_campaign.gd -- \
  "$out/candidate-development-0.jsonl" "$PWD/docs/evidence/phase23/cohort-earned-profile.json" development 0 210
```

Repeat with `held-out` and the reference arm. The last two arguments are a zero-based start offset and count for independently reproducible shards. Name output files `baseline|candidate`–`development|held-out`–`offset.jsonl`. Use `tools/nightmare_tactics/summarize_phase23.py SHARDS_DIR OUTPUT_DIR` to validate pairing and regenerate the summary and compressed full receipts.

Simulation uses the established 0.15 s campaign matrix timestep with a 900 s timeout. Results measure model outcomes and settlement, not render performance. For each row, room and owner are separate values. Displayed room indices in the receipts start at 1. The original engine event field `next_room` remains zero-based. Use `trace.target_changes` for normalized one-based changes. Scored choices include the selected and best costs in the decision, the number of comparable doors, and the options considered at that particular decision. On a mid-siege reassessment the options can already be restricted to alternatives with enough advantage. The timestamp of the first `encounter` is the physical door arrival. A target choice can occur without contact if a valid Hall retreat, phase change or terminal event intervenes. `seconds_under_attack` includes breach time. Transactions show successful event-backed purchases. The wait/no-purchase counter includes intentional saving and unavailable purchases. Elapsed time for a paired item run can shorten after a victory or lengthen after an avoided loss. Neither is a general estimate of item strength.

## Additional checks at the game's maximum simulation substep

The game splits a long rendered frame into simulation steps of at most 0.05 s. Six preselected development fixtures were replayed on each arm at that finer step. A second check used four new Story seed bases, two early Normal missions and two beginner policies. The expanded policy buys a second Level 1 Needle once the original Needle reaches Level 2. It uses the identical 7.2 s decision interval and buys no further upgrades. A game that ends before the player can afford the additional Needle remains in the sample.

To reproduce these checks, copy the project to a temporary test directory and set the inherited test constant `MODEL_STEP` in `tools/nightmare_maps/check_nightmare_matches.gd` to `.05`. Game scripts remain stock. For each arm run single development fixtures 0, 5, 38, 105, 147 and 209, with files named `fine-baseline-ID.jsonl` or `fine-candidate-ID.jsonl`. For the early check use the candidate and `opening 0 16` with output `opening.jsonl`. The summary tool validates these pairs and writes their receipts to `cohort-diagnostics.json.gz`.
