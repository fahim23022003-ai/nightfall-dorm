# V2.2 matched combat and counterplay QA

The independent broad cohort ran 270 ordinary Campaign matches per arm. Each of ten map families ran three seeds on each difficulty with passive, Balanced and Needle-first plans. The same seeds, room, generated map hash and policy matched in all pairs. The harness places the survivor beside the bed, then uses the normal sleep action. Resources thereafter come from income and normal transactions. Every match settled with valid movement, wallet and Hall accounting. Standard matched in all 90 full telemetry rows.

| Difficulty | Passive wins | Balanced wins | Needle-first wins | Defense-induced switches |
| --- | ---: | ---: | ---: | ---: |
| Standard | 4/30 → 4/30 | 30/30 → 30/30 | 28/30 → 28/30 | 0 |
| Hard | 1/30 → 4/30 | 18/30 → 19/30 | 17/30 → 18/30 | 70 |
| Hell | 0/30 → 0/30 | 4/30 → 4/30 | 9/30 → 10/30 | 22 |

### Outcomes across families

| Family | Hard active wins | Hell active wins |
| --- | ---: | ---: |
| Ring | 4/6 → 4/6 | 2/6 → 2/6 |
| Branching | 6/6 → 6/6 | 0/6 → 0/6 |
| Scattered | 6/6 → 6/6 | 1/6 → 1/6 |
| Spine | 3/6 → 3/6 | 2/6 → 2/6 |
| Zigzag | 3/6 → 3/6 | 3/6 → 4/6 |
| Radial | 2/6 → 0/6 | 2/6 → 2/6 |
| Twin Wings | 2/6 → 3/6 | 1/6 → 1/6 |
| Labyrinth | 4/6 → 6/6 | 0/6 → 0/6 |
| Courtyards | 2/6 → 2/6 | 0/6 → 0/6 |
| Hybrid | 3/6 → 4/6 | 2/6 → 2/6 |

Hell remained demanding. Branching, Courtyards and Labyrinth each stayed at 0/6 on these two broad active strategies. The targeted plans and alternate room choices below test different decisions. The paired sample supports a new defense interaction. It shows a modest change in broad active win counts.

### Hard passive results

Hard passive wins rose from one to four. The three additional wins had zero player damage. Genuine NPC damage and upkeep contributed to their doors holding; all three traces show at least one defense-induced switch from an NPC room. Those shifts changed exposure and let teammates land more damage. NPC contribution is valid gameplay, and the increase in this paired sample is a trade-off. The sample does not establish the general passive win rate. Hell passive remained at zero.

| Family and seed | NPC damage to Hunter | Player direct siege | Hunter switches between NPC rooms |
| --- | ---: | ---: | ---: |
| Hybrid 12077 | 1773 → 6615 | 3.9s → 0.0s | R6→R4, R4→R3, R3→R4, R4→R3 |
| Ring 60899 | 7584 → 9140 | 0.0s → 0.0s | R6→R5, R5→R6, R6→R5, R5→R6 |
| Scattered 62900 | 3297 → 7515 | 3.3s → 0.0s | R3→R5 |

## Exact Hell starts

Both exact starts begin with 25 Gold and zero Electricity. The nine initial policies are matched per room. Some policies converged on the same early purchases once low door HP took priority. Their win counts are separate attempts and should not be treated as independent strategic styles.

| Exact start | Plan | V2.1 → V2.2 | V2.2 realized purchases and tools |
| --- | --- | --- | --- |
| Labyrinth 10358 R2 | Passive | defeat → defeat | — |
| Labyrinth 10358 R2 | Balanced | defeat → defeat | 2 turret, 1 generator, 1 repair |
| Labyrinth 10358 R2 | Needle Defense | defeat → defeat | 5 turret |
| Labyrinth 10358 R2 | Survival Transition | defeat → defeat | 3 turret |
| Labyrinth 10358 R2 | Economic Rush | defeat → defeat | 3 turret |
| Labyrinth 10358 R2 | Door Reserve | defeat → defeat | 3 turret |
| Labyrinth 10358 R2 | Frost Arc | defeat → defeat | 3 turret |
| Labyrinth 10358 R2 | Precision Layout | defeat → defeat | 3 turret, reposition |
| Labyrinth 10358 R2 | Earned Repair | defeat → defeat | 3 turret, repair |
| Hybrid 12336 R4 | Passive | defeat → defeat | — |
| Hybrid 12336 R4 | Balanced | defeat → defeat | 2 turret, 1 generator |
| Hybrid 12336 R4 | Needle Defense | defeat → defeat | 5 turret |
| Hybrid 12336 R4 | Survival Transition | defeat → victory | 3 turret, 1 generator, 1 repair, 1 paid Ward |
| Hybrid 12336 R4 | Economic Rush | defeat → victory | 3 turret, 1 generator, 1 repair, 1 paid Ward |
| Hybrid 12336 R4 | Door Reserve | defeat → victory | 3 turret, 1 generator, 1 repair, 1 paid Ward |
| Hybrid 12336 R4 | Frost Arc | defeat → victory | 3 turret, 1 generator, 1 repair, 1 shock, 1 paid Ward |
| Hybrid 12336 R4 | Precision Layout | defeat → victory | 3 turret, 1 generator, 2 repair, 2 paid Ward, reposition |
| Hybrid 12336 R4 | Earned Repair | defeat → defeat | 3 turret, 1 generator, 1 paid Ward, repair |
| Labyrinth 10358 R2 | Approach Fire | defeat → defeat | 5 turret |
| Labyrinth 10358 R2 | Earned Control | victory → victory | 1 frost, 4 turret, 1 generator, 1 repair, 1 shock, 1 heavy, 3 paid Ward, gold, battery |
| Hybrid 12336 R4 | Approach Fire | defeat → defeat | 5 turret |
| Hybrid 12336 R4 | Earned Control | defeat → defeat | 1 frost, 3 turret, 1 paid Ward, gold, battery |

On Labyrinth 10358 R2, the first player strike was at 48.0 seconds, eight seconds after preparation. At first contact the original no-item defended plans generally held 35.4–40.6 Gold and zero Electricity, against a 120 Gold Dynamo and an 18 Electricity Frost Tower. Immediate repair and cheaper Needles competed for that income. The Balanced variant gained a real defensive switch at 63.0 seconds and later paid for a Dynamo and Repair Station, but lost. That trace identifies an opening constraint without proving the seed or room unwinnable.

In Hybrid 12336 R4, the five successful original V2.2 replays all show a change from room 4 to room 5 at 154.65 seconds with reason `defense_delays_breach`. The matched V2.1 policies lost. Their positive response actually used earned infrastructure and paid Ward. Repair, Needle, and Shock purchases are recorded by policy. The two reposition scripts moved an existing paid Needle during preparation and verified its identity and wallet on the move. The one-use Repair Kit came from an actual prior Standard victory and First Victory achievement.

The extra Earned Control experiment won Labyrinth R2 on both versions. The prior Campaign victory funded the normal First Blood Gold Crate and a 16 RM shop Battery. The test equipped and consumed each once through the profile API. That purchased a Frost Tower at 3.75 seconds and registered 53 controlled hits on either version. The same finite loadout lost Hybrid R4, despite landing 17 Frost hits. The five-Needle approach-aware experiment lost both rooms. The assisted Labyrinth result shows a practical route using earned items. The ordinary no-item plans tested for that room still lost.

### Longer matches for control and specialization

| Fixture | Policy | V2.1 → V2.2 | V2.2 controlled hits | V2.2 specializations |
| --- | --- | --- | ---: | ---: |
| Twin Wings 37719 R3 | Frost Arc | victory → victory | 0 | 0 |
| Twin Wings 37719 R3 | Branch Focus | victory → victory | 3 | 0 |
| Spine 63906 R5 | Frost Arc | victory → victory | 10 | 0 |
| Spine 63906 R5 | Branch Focus | victory → victory | 11 | 0 |
| Ring 60899 R2 | Frost Arc | victory → victory | 0 | 0 |
| Ring 60899 R2 | Branch Focus | victory → victory | 0 | 0 |
| Radial 37278 R2 | Frost Arc | defeat → defeat | 0 | 0 |
| Radial 37278 R2 | Branch Focus | defeat → defeat | 0 | 0 |
| Hybrid 70169 R2 | Frost Arc | defeat → victory | 0 | 0 |
| Hybrid 70169 R2 | Branch Focus | defeat → victory | 34 | 0 |

The longer subset deliberately tests paid capabilities that the exact early deaths did not leave time to reach.

### Same Hell seeds, alternate rooms

| Fixture | Policy | V2.1 → V2.2 | V2.2 controlled hits | V2.2 specializations |
| --- | --- | --- | ---: | ---: |
| Labyrinth 10358 R1 | Needle Defense | victory → defeat | 0 | 0 |
| Labyrinth 10358 R4 | Balanced | victory → defeat | 0 | 0 |
| Hybrid 12336 R3 | Survival Transition | victory → defeat | 12 | 0 |

A different room keeps the same seed, archetype and corridor layout. These three R1/R4/R3 victories on V2.1 became losses under V2.2. Each recorded a defense-induced switch. These are matched counterexamples to a uniform improvement across room choices.

### Separately prepared specialization fixture

These Stage 5 Hell Hybrid 70169 R2 controls add a documented 2,250 Gold and 210 Electricity test treasury. The fixture records it as other income. Bed, Door, Needle and branch upgrades are paid through the original transactions. These two pairs are excluded from all earned results above.

| Paid Needle branch | L5 payment | Session time at purchase | V2.1 → V2.2 | Hunter defensive switch in V2.2 |
| --- | ---: | ---: | --- | --- |
| Precision | 225G / 44E | 10.8s | victory → victory | R3→R5 at 55.5s |
| Suppression | 225G / 44E | 10.8s | victory → victory | R3→R5 at 55.5s |

None of the unprepared focused runs reached a paid specialization. The prepared branch checks verify payment, branch selection and combat through a normal ending.

## Reproduce

Use Godot 4.6.3. Run the base matrix on the frozen V2.1 checkpoint with the existing tactics gate enabled. Run the same seed cohort on the V2.2 source with the fair-siege gate enabled. Use a distinct profile home per process.

```sh
godot --headless --script tools/nightmare_tactics/check_complete_matches.gd -- /tmp/baseline-0.json candidate 0
godot --headless --script tools/nightmare_tactics/check_fair_counterplay.gd -- /tmp/initial-0.json v22 0
godot --headless --script tools/nightmare_tactics/check_fair_counterplay.gd -- /tmp/baseline-exact.json v21 exact
godot --headless --script tools/nightmare_tactics/check_fair_counterplay.gd -- /tmp/initial-exact.json v22 exact
```

Repeat the broad cohort for repetitions 1 and 2. The focused harness also accepts `probes`, `late`, `alternate` and `staged` for both arms. Run this report generator on the receipt folder. [Structured summary](summary.json)
