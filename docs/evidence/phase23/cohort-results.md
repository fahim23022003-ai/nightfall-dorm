# Phase 23 Story match results

840 complete Campaign matches yielded 420 matched outcome comparisons on 20 reproducible mission maps. Each arm includes ten development maps and ten independently held-out maps. The two arms matched on starting geometry, spawn, time to bed, room, Hunter HP and wallets. All 840 reached an ordinary victory or defeat, settled once, reloaded successfully and passed the navigation and wallet checks. None timed out.

## Wins on each difficulty

Each cell reports Phase 22.1 wins → Phase 23 wins, out of ten mission fixtures. Policy behavior and earning conditions are in the [match protocol](cohort-method.md).

### Development

| Policy | Normal | Long Night | Hell |
| --- | --- | --- | --- |
| Passive | 1 → 0 | 0 → 0 | 0 → 0 |
| Beginner | 0 → 0 | 0 → 0 | 0 → 0 |
| Average | 6 → 8 | 2 → 2 | 2 → 1 |
| Defensive | 6 → 8 | 2 → 3 | 1 → 1 |
| Offensive | 8 → 6 | 3 → 2 | 1 → 1 |
| Skilled | 9 → 10 | 7 → 6 | 4 → 3 |
| Skilled + Gold Crate | 9 → 10 | 8 → 8 | 5 → 4 |

### Held-out

| Policy | Normal | Long Night | Hell |
| --- | --- | --- | --- |
| Passive | 0 → 1 | 0 → 1 | 0 → 0 |
| Beginner | 0 → 2 | 0 → 1 | 0 → 0 |
| Average | 6 → 6 | 3 → 3 | 1 → 2 |
| Defensive | 7 → 8 | 5 → 4 | 1 → 2 |
| Offensive | 6 → 8 | 4 → 5 | 0 → 1 |
| Skilled | 10 → 9 | 7 → 8 | 4 → 5 |
| Skilled + Gold Crate | 10 → 10 | 9 → 9 | 6 → 5 |

## What the Hunter and allies did

| Measure | Development, 210 per arm | Held-out, 210 per arm |
| --- | --- | --- |
| Team wins | 74 → 73 | 79 → 90 |
| Physically approached human room (matches) | 199 → 194 | 186 → 179 |
| Player door received recorded damage (matches) | 208 → 202 | 195 → 199 |
| All room contact episodes | 866 → 940 | 742 → 953 |
| Return contacts to a previously reached room | 121 → 194 | 116 → 268 |
| Tactical mid-siege reassess events | 29 → 208 | 32 → 217 |
| Median motion time (s) | 96.3 → 101.1 | 70.2 → 89.93 |
| Median player-room attack/breach time (s) | 17.85 → 19.12 | 18.45 → 20.25 |
| Mean player damage to main Hunter | 1513.97 → 1419.83 | 1656.47 → 1611.85 |
| Mean ally damage to main Hunter | 2349.54 → 2374.11 | 2248.49 → 2718.28 |
| Wins with zero personal damage and zero player door damage | 1 → 8 | 15 → 9 |
| Completed Haunted Hall visits | 88 → 76 | 78 → 105 |
| Allied deaths | 431 → 365 | 318 → 310 |
| Median match duration (s) | 274.35 → 282.53 | 248.93 → 278.55 |

The revised Hunter can return to a repaired room. Both splits saw more return contacts and motion time. A well-funded door can discourage a direct siege, allies can finish the encounter, and a Hall retreat can interrupt a route. The summary lists each zero-damage, untouched win with its passive twin and Gold spent.

**Development passive wins** — baseline 1, candidate 0.

**Held-out passive wins** — baseline 0, candidate 2. Both occurred on the same Room 3 Zigzag start. On Normal the Hunter left the first defended siege at 92.55 s, kept pressure on the other residents, and transformed there. On Hard the Hunter initially chose the human door at 235.20 s, then the Hall retreat interrupted travel and it chose Room 1 at 267.75 s. The transformed Reaper also revisited Room 5. In the matching Hell run the Hunter physically reached Room 3 at 268.20 s and eliminated the player.

- Standard L27, seed 21529445, Room 3. Victory at 384.90 s. The player took 26.3 door damage and dealt zero damage. It reached rooms 5, 6, 4, 5, 5, 4. The five allies dealt 5,944.4 main-Hunter damage.

- Hard L27, seed 21529445, Room 3. Victory at 367.65 s. The player took 91.2 door damage and dealt zero damage. It reached rooms 5, 6, 4, 6, 1, 1, 2, 5. The five allies dealt 6,504.8 main-Hunter damage.

### Matched examples

- **Normal L6, seed 2717961, Room 6, passive.** Phase 22.1 selected the player room at 236.70 s, retreated to the west Hall before arriving, then excluded that room on exit. Allies finished the Hunter at 294.45 s. Phase 23 allowed Room 6 back into the comparison on exit. The player lost at 286.35 s after receiving 150 door damage. The finer-step replays produced the same two outcomes.

- **Normal L1, seed 444177, Room 4, average.** The reference attacked Room 4 and won the siege. The player dealt 1,417.1. In the revised match the Hunter revisited the defended Room 3, then selected Room 6. Allies won with zero player damage or strikes on Room 4. The passive twin lost. There are still runs where investment discourages an attack and allies deal all the damage.

- **Hell L27, seed 20794696, Room 2, defensive.** The reference breached the human room and ended the match at 162.15 s. Multiple revised siege decisions and legitimate heals extended the match to 309.45 s, with the player room absorbing 1,885.9 damage. The player survived and the Hunter died. The 0.05 s replay also ended in victory, at a different elapsed time.

The [structured comparison](cohort-summary.json) records the first diverging observed tactical event, both terminal times, personal damage and retarget counts for every outcome flip. The full event streams are in the [compressed match receipts](cohort-matches.jsonl.gz). The first divergence shows where the two recorded fights began to separate. Later hits and purchases can have several contributing causes.

## Story progression and items

**Development Phase 23 wins across the seven policies**

| Level band | Normal | Long Night | Hell |
| --- | --- | --- | --- |
| Early L1–15 | 14/21 | 7/21 | 0/21 |
| Middle L16–34 | 15/28 | 6/28 | 6/28 |
| Late L35–50 | 13/21 | 8/21 | 4/21 |

For the same skilled policy and a legitimate Gold Crate in 30 pairs, 3 defeats became wins and 0 wins became defeats. Median personal damage difference was +84.9. The extra currency can change build timing, Hunter decisions, player exposure and the fight's duration.

**Held-out Phase 23 wins across the seven policies**

| Level band | Normal | Long Night | Hell |
| --- | --- | --- | --- |
| Early L1–15 | 13/21 | 7/21 | 3/21 |
| Middle L16–34 | 18/28 | 16/28 | 8/28 |
| Late L35–50 | 13/21 | 8/21 | 4/21 |

For the same skilled policy and a legitimate Gold Crate in 30 pairs, 3 defeats became wins and 1 win became a defeat. Median personal damage difference was +0.0. The extra currency can change build timing, Hunter decisions, player exposure and the fight's duration.

Difficulty comparisons hold level, seed, room, equipment and policy constant. Chapter comparisons change Hunter, map, room, encounter timing and sometimes the Reaper policy. Variation across those columns cannot identify a purely level-driven effect. The late-track profile has one earned defensive perk. The cohort does not estimate the entire population of late-career loadouts.

## Early Normal and timestep checks

On eight previously unused early Normal maps at 0.05 s, the slow single-Needle beginner won 1/8. The same beginner with a second L1 Needle won 1/8. Seven could buy the extra Needle before the result, and six dealt more damage. A fixed beginner policy that stops upgrading remains vulnerable even on Normal.

All 12/12 preselected outcomes agreed when the 0.15 s cohort runs were repeated at the gameplay maximum substep of 0.05 s. The largest difference in one terminal time was 56.9 s. Timing and damage from accelerated simulations remain step-sensitive. [Additional match receipts](cohort-diagnostics.json.gz)
