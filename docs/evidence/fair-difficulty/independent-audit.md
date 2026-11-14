# Phase 12B — bounded independent pressure audit

Scope: read-only inspection of Phase12 delivery `1b6d76e`, retained failures and focused economy/combat/entry code. No production edits, new simulation claims or whole-project regression run. Line numbers refer to that starting source. Main developer owns fixes and validation.

## Established facts

| Finding | Source | Implication |
|---|---|---|
| Stage1 is fresh-unlocked; `begin_match` accepts all defined difficulty IDs without rank/previous-difficulty lock. | `player_profile.gd:252–255,563–590`; `game.gd:207,236–238` | Fresh no-stock/zero-XP hard/Hell entry must be tested. A prepared progressed profile cannot replace that entry test. |
| Campaign time-based growth is unbounded, apart from a minimum attack interval. Hard adds14 base damage per32s after45s opening; Hell18 per25s. At the same time interval contracts, existing difficulty/archetype factors apply, kill buffs may apply, charged hits multiply, and sustained-contact pressure adds up to16%. | `hunter_state.gd:245–250,373–396,480–492`; `rank_catalog.gd:24–32`; `match_model.gd:559–586` | This is an actual multiplicative pressure stack. It is not evidence that each individual modifier is broken. Expose final strike/interval values and compare affordable infrastructure against those values. |
| Endless explicitly caps the above combat growth at1 and combat level2 per wave; it uses its own deliberate wave scaling. | `hunter_state.gd:377` | Harder Endless survival does not validate harder Campaign; the time-growth pressure curves differ materially. |
| Early repair station consumes12E to purchase, then protects at least8E (up to40E depending next generator upgrade). Base upkeep.35E/level/s only runs above reserve. | `balance_rules.gd:27,33`; `room_state.gd:357–371` | A newly purchased station may do zero healing for a rebuilding interval. With Dynamo1/.6E/s and no other draw, rebuilding8E takes13.3s, then first running step needs upkeep as well. This delay is a real opportunity-cost issue, not a free-healing claim. |
| Inspector reports nominal healing even while reserve blocks it; it only describes generic “keeps8–40E grid reserve.” | `building_stats.gd:53–56,75` | Concrete misleading-state UX issue: show actual running/idle/block reason and exact reserve/available power, while retaining nominal output as a labelled potential. |
| Bots only trigger emergency repairs below35% HP, save for120G Dynamo after Bed/Door2, then advance shared structure goals before broader support/weapon investment. | `bot_ai.gd:97–122` | Plausible ally-collapse cause under revised slower income. Test an actual-resource defense/control policy before handing NPCs money or weakening all enemies. |
| Principal test strategies share most opening goals and a repeated power-upgrade priority before divergent branches. | `tools/phase12_strategy_probe.gd:38–67` | Identical5.4G/s median at5min is partly test-policy convergence. It does not alone prove every legal human opening is forced. |
| Final defeat tips test wallet/prerequisites at death rather than record a prior actionable window. | `defeat_facts.gd:29–34` | A factual resource-at-death statement can be true but insufficient to establish a meaningful missed counter. Capture pre-breach affordability, intact-door state and warning/reaction times before recommending an action. |

## Retained failure evidence

- `long-night.json`: Campaign seed1 (Ravager) defeated185.6s, Bed/Door3, generator1/repair1/Needle3,160G manual repairs,103.8G/11.6E remaining. Seed2 Witch defeated176.4s with64G repairs and150.1G/8.8E remaining; seed3 Electric182.6s with96G repairs; seed4 Storm176.0s with96G; seed5 Crusher192.8s. A remaining wallet alone does not prove a useful upgrade was affordable in time.
- `hell-counter-tuned.json`: Campaign seeds1–5 all failed145.6–180.2s, mostly Bed/Door2. The ordinary counter policy did not establish campaign viability.
- `hell-siege.json`: three early Needles shifted failures to161.0–187.2s; all five Campaign samples still lost. This is a different investment attempt, not a victory.
- `combat-reward-paths.json`: seed1 balanced Endless Long Night first own-door hit158.0s → breach177.2s,776.8755 actual damage,17 positive damage events,84G manual repair spending. Hell143.0s →153.6s,474.654 damage,9 positive events,28G repairs. These totals include actual mitigation/healing and cannot be used as unopposed dummy DPS.
- Normal seed1 first/last draft paths both cleared8 waves by900s; only101.2 player-door damage recorded, no own breach, zero manual repair Gold. This is forgiving in that selected scenario, not a reason to punish every Normal player.

## Cause classification and focused recommendations

A. **Weak/test strategy:** shared policy repeatedly prioritizes generator/weapon upgrades, then starts emergency repair spam when damaged; this can spend the240G needed for Door4 before accumulated power reaches its10E requirement. The retained seed1 Long Night trace spends16G repairs each second from173–182s while holding Bed/Door3 and rebuilding electricity from6.8→9.75E. Its repair station was purchased at139s with.4E left and did not immediately heal at nominal rate. Test explicit savings/reaction rules and alternative weapon/control purchase orders with the same budget and human-plausible delay.

B. **Gameplay/UI issue:** reserve gating has no exact live status, and defeat advice lacks pre-breach affordability evidence. Fix these independently of tuning. Also inspect recovery/windup timer interactions before assuming every telegraph provides a useful window. Existing Frost gives bounded22% attack interval extension with a1s status, refreshed only on actual hits; it is not a permanent stun. Magic barriers affect magical packets, not all ordinary physical strikes, so “buy magic defense” cannot be a blanket response to every archetype's regular door hits.

C. **Likely economy/pressure mismatch to prove:** uncapped Campaign time growth plus accelerated interval and charged hits can outpace slower early infrastructure. Unlike Endless, Campaign continues this curve while allies have not yet built useful firepower. Controlled comparisons should isolate Campaign time-growth pacing and NPC ordering, then assess reserve/recovery as their own group. Keep Normal prices/income and long-term prerequisites stable unless measured evidence requires a precise change. Preserve Level10 evolution, distinct skills, valid paths and real stock-free entry. Do not claim the mismatch fully proven until event-level traces show actual factors and alternative strategy outcomes.

## Avoid unsupported conclusions

No current audit evidence proves every possible hard Campaign strategy fails, no rare item is required, all12 perks are equivalent, an early repair reserve is always harmful, or a precise desired win percentage exists. Do not use a single successful repair or one winning seed as completion proof. Compare original failing and held-out seeds, disclose actions and affordances, and preserve measured losses.
