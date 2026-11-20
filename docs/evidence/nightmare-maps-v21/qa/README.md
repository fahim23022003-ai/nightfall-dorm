# Matched Campaign tactics QA

The test ran 270 cases on the frozen baseline and 270 on the candidate. The seed, generated geometry hash, room, difficulty and automated policy matched in each pair. Every family ran three seeds per difficulty. Passive players made no purchases. Both defensive policies spent only resources earned through ordinary play. Each survivor started at the bed so the test could use normal sleep and focus on siege balance. NPCs claimed and reached all five other beds in every case. In one Courtyards fixture the first NPC was eliminated before the last NPC fell asleep, so simultaneous occupancy peaked at four. A targeted replay verified that all five reached their beds in all three policy pairs. All runs settled without illegal Hunter movement, economy or Hall budget failures.

## Wins by difficulty and policy

| Difficulty | Passive | Balanced | Needle-first |
| --- | ---: | ---: | ---: |
| Standard | 4/30 → 4/30 | 30/30 → 30/30 | 28/30 → 28/30 |
| Hard | 4/30 → 1/30 | 26/30 → 18/30 | 16/30 → 17/30 |
| Hell | 2/30 → 0/30 | 18/30 → 4/30 | 13/30 → 9/30 |

Standard had 90/90 exactly matching outcome and telemetry rows. The same scoring applies to every occupied room the Hunter can reach.

## Family comparison

Each difficulty-family pair has six active-plan runs across three exact seeds and two defense plans. The candidate recorded zero of six Hell wins in Branching, Courtyards and Labyrinth. The counts characterize the picked rooms and strategies.

| Family | Hard active wins | Hell active wins |
| --- | ---: | ---: |
| Ring | 4/6 → 4/6 | 3/6 → 2/6 |
| Branching | 6/6 → 6/6 | 2/6 → 0/6 |
| Scattered | 6/6 → 6/6 | 4/6 → 1/6 |
| Spine | 4/6 → 3/6 | 6/6 → 2/6 |
| Zigzag | 3/6 → 3/6 | 6/6 → 3/6 |
| Radial | 3/6 → 2/6 | 3/6 → 2/6 |
| Twin Wings | 2/6 → 2/6 | 2/6 → 1/6 |
| Labyrinth | 6/6 → 4/6 | 3/6 → 0/6 |
| Courtyards | 4/6 → 2/6 | 0/6 → 0/6 |
| Hybrid | 4/6 → 3/6 | 2/6 → 2/6 |

## Exposure and team damage

Each cell gives baseline → candidate. First-strike medians use matches in which the player door was actually hit. The adjacent count shows how often that happened.

| Difficulty | Player door hit cases | First strike, median s | Player siege, median s | Hunter damage from player, median | Hunter damage from NPCs, median | Retargets, median | Evolution level, median | Hall visits |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Standard | 75 → 75 | 220.7 → 220.7 | 10.2 → 10.2 | 1245 → 1245 | 3060 → 3060 | 2 → 2 | 6 → 6 | 71 → 71 |
| Hard | 87 → 88 | 206.1 → 195.6 | 9.3 → 11.3 | 751 → 1040 | 3020 → 1990 | 3 → 0 | 6 → 6 | 34 → 31 |
| Hell | 88 → 90 | 159.4 → 171.0 | 14.2 → 17.1 | 1228 → 1246 | 2201 → 855 | 3 → 0 | 7 → 6 | 31 → 15 |

| Difficulty | Match duration, median s | NPC rooms surviving, median | Total eliminations |
| --- | ---: | ---: | ---: |
| Standard | 303.4 → 303.4 | 4.0 → 4.0 | 142 → 142 |
| Hard | 318.5 → 273.1 | 4.0 → 3.0 | 148 → 233 |
| Hell | 283.4 → 194.0 | 4.0 → 3.0 | 203 → 273 |

Room survival counts include the five NPC residences. Total eliminations also count a player loss.

## The five original passive wins

All five reproduced on the frozen V2 checkpoint. Each delivered zero player damage to the Hunter. The team damage records show how much damage the NPCs supplied, including any damage needed to overcome Hall healing. No first strike means the player door remained untouched.

| Theme family, difficulty, seed and room | Result | NPC damage to Hunter | Player siege s | First player strike s | Retargets | Evolution | Hall visits |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Branching, Standard, 3802, R2 | Victory → Victory | 7819 → 7819 | 0.0 → 0.0 | — → — | 3 → 3 | 6 → 6 | 1 → 1 |
| Scattered, Hard, 5076, R6 | Victory → Victory | 6084 → 5971 | 0.0 → 0.0 | 333.8 → 268.9 | 8 → 1 | 10 → 10 | 0 → 0 |
| Zigzag, Hell, 7338, R5 | Victory → Defeat | 7577 → 2889 | 0.0 → 1.4 | 359.7 → 283.6 | 12 → 0 | 9 → 9 | 1 → 0 |
| Radial, Standard, 7839, R6 | Victory → Victory | 5799 → 5799 | 0.0 → 0.0 | 279.9 → 279.9 | 1 → 1 | 6 → 6 | 1 → 1 |
| Hybrid, Hard, 12077, R1 | Victory → Defeat | 6564 → 1773 | 0.0 → 3.9 | 331.2 → 220.1 | 13 → 0 | 6 → 5 | 1 → 0 |

Every baseline passive win had zero direct player siege. The Hall and door hit timelines show one untouched room and four rooms damaged by a cursed projectile, Phantom Scream, or Undead. The unchanged two Standard wins and the surviving Hard win still had zero direct siege. In the two flipped matches, direct pressure did reach the player. [Summary and five exact timelines](summary.json) · [Door hit sources](focused-baseline.json)

## What changed in five Hell losses

The first repeat supplied five fixtures where the baseline Balanced policy won and the candidate lost. These are targeted losses, so this table tests counterplay on difficult cases. The focused survival policy bought an early Door upgrade and used repairs or a paid Ward under direct pressure, then added Needle, Frost and Arc machines as funds allowed.

| Family and seed | Player first hit after prep, old → new | Candidate breach time | Permanent purchases before breach | Repairs before breach | Candidate Needle-first | Candidate survival-transition |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Labyrinth 10358 | 8.0s → 8.0s | 110.7s | 4 | 18 | Defeat | Defeat |
| Hybrid 12336 | 55.2s → 98.0s | 164.1s | 8 | 12 | Defeat | Defeat |
| Ring 3341 | 167.3s → 161.2s | 214.7s | 12 | 11 | Victory | Victory |
| Radial 8332 | 297.4s → 192.3s | 249.8s | 12 | 11 | Victory | Defeat |
| Scattered 5335 | 315.6s → 235.9s | 293.6s | 16 | 5 | Victory | Victory |

On Labyrinth 10358, the first encounter and strike matched, but continued productive siege removed the breaks the previous Hunter gave the defenders. The candidate breached at 110.7 seconds and received zero damage from NPC weapons. In the corresponding baseline the Hunter rotated back through Room 6, taking 3,513 NPC damage before losing at 424.8 seconds. On Hybrid 12336 the first player strike came later under the candidate, but the Hunter then held the approach and breached 26.1 seconds after the first strike. Those two selected rooms lost under all three tested policies. Needle-first won the other three selected losses, and survival-transition won two. [Focused decision and combat timelines](focused-candidate.json) · [Matched baseline timelines](focused-baseline.json)

## The same two maps from other rooms

These two tests kept the same Hell seed, Hunter archetype and geometry. The three active plans ran all five other rooms. All 30 matches settled with legal movement and correct income. Each map produced wins from other choices, even though the original room lost with all three tested policies.

| Family and seed | Original room | Wins across other rooms | Other rooms with wins |
| --- | ---: | ---: | --- |
| Labyrinth 10358 | R2 | 2/15 | R1 Needle-first · R4 Balanced |
| Hybrid 12336 | R4 | 7/15 | R3 Balanced, Needle-first, Survival-transition · R5 Balanced, Survival-transition · R6 Balanced, Needle-first |

[Labyrinth reruns](alternate-10358.json) · [Hybrid reruns](alternate-12336.json)

## Reproduce

Run the same harness from the clean baseline checkout and from the candidate checkout, with a separate output per repetition. Use Godot 4.6.3. The script sets the V2 and grid previews internally.

```sh
godot --headless --script tools/nightmare_tactics/check_complete_matches.gd -- /tmp/baseline-0.json baseline 0
godot --headless --script tools/nightmare_tactics/check_complete_matches.gd -- /tmp/candidate-0.json candidate 0
```

Repeat for shards 1 and 2. To reproduce the targeted HUD-independent replay, pass [the case manifest](audit-fixtures.json) to `tools/nightmare_tactics/audit_siege_pressure.gd` after the output path and arm. Use `tools/nightmare_tactics/report_complete_matches.py` to compare receipts.
