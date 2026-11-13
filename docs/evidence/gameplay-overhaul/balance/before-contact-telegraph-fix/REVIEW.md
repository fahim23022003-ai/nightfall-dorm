# Independent gameplay balance audit

Status: ACCEPTED within the tested scope. All39 final cases completed with zero invariant failures. This audit does not substitute for human difficulty approval.

## Scope and method

Actual Godot4.6.3 model simulations on Linux use legal player navigation, claim/sleep, paid building placement/upgrades/branches, repairs and expansion. Starting wallets are25 Gold/0 Electricity. No perks, consumables or debug resource/HP/position/wave edits are used. New campaign Hunters are selected through the real strategy configuration; Endless follows the normal seeded six-Hunter cycle. No user save is opened. This is automated gameplay simulation, not manual playtesting or native Windows execution.

The final campaign matrix has27 cases; extra Electric Hell controls add8, three earned Endless cases run to a one-hour limit, and one extra long Hell run reaches a genuine defeat before its two-hour cap. Per-second checks repeat invariants and are not unique gameplay scenarios. The full regular/extended regressions and persistent rank/reward QA belong to the parent task.

## Final results so far

- Campaign: 249,685 checks, 0 failures; 39.909s wall.
- One-hour Endless: 750,202 checks, 0 failures; 217.599s wall.
- Extra Electric Hell: 66,422 checks, 0 failures; 8.609s wall.

| Hunter/map | Mode | Bed/door-only | Active without new magic buildings | Active with early magic investment |
| --- | --- | --- | --- | --- |
| witch/abandoned_dorm | standard | victory at206.0s | victory at160.0s | victory at160.4s |
| witch/abandoned_dorm | hard | victory at164.8s | victory at164.8s | victory at164.8s |
| witch/abandoned_dorm | hell | defeat at199.7s | victory at177.4s | victory at189.8s |
| electric/underground_lab | standard | victory at223.7s | victory at217.9s | victory at219.7s |
| electric/underground_lab | hard | victory at236.2s | victory at202.4s | victory at203.8s |
| electric/underground_lab | hell | defeat at144.0s | defeat at137.9s | defeat at137.9s |
| storm/cursed_mansion | standard | victory at242.5s | victory at194.6s | victory at194.6s |
| storm/cursed_mansion | hard | victory at224.5s | victory at212.8s | victory at216.5s |
| storm/cursed_mansion | hell | defeat at203.4s | victory at204.8s | defeat at168.1s |

All three initial Hell passive cases lose. Normal/Long passive victories remain; this finite matrix is not a universal win-rate estimate. New magic buildings are optional: no-magic active strategies beat Hell Witch and Storm; early magic investment wins Witch but loses Storm in that fixture, showing an actual opportunity cost rather than a mandatory build. The initial Lab Electric Hell fixture defeats both active policies. Extra Electric controls win on Dorm/Hospital without new magic buildings and on Mansion for the ordinary active policy, while Lab remains a hard case on a second seed. This is map/strategy-dependent evidence, not proof of unfairness or a recommendation for arbitrary stat nerfs.

## Earned room and Level10 progression

| Map/mode | Slots16 earned | True waves cleared at3600.1s | Earned Level10 types |
| --- | --- | --- | --- |
| abandoned_dorm/standard | 386.7s, wave9 | 38 | turret, heavy, barrier, plasma, antenna |
| underground_lab/hell | 392.1s, wave7 | 31 | turret, heavy, barrier, plasma, antenna |
| cursed_mansion/hell | 329.7s, wave5 | 34 | turret, heavy, barrier, plasma, antenna |

All seven expansion purchases used exactly6,560 Gold/1,105 Electricity in addition to actual structure upgrades. All three runs earned Needle, Arc and each new magic defense at Level10. The runs remain alive at their finite one-hour stop; this does not prove eventual defeat, permanent invulnerability, or unlimited-session balance.

The real player—not only NPCs—produced new defensive events in all three runs:
- abandoned_dorm: Magic absorbs24, reflects7, Antenna activations8, Plasma releases7; peak minions10, projectiles9, route keys11; 38 actual intermission JSON round-trips.
- underground_lab: Magic absorbs11, reflects5, Antenna activations6, Plasma releases5; peak minions10, projectiles6, route keys11; 31 actual intermission JSON round-trips.
- cursed_mansion: Magic absorbs29, reflects11, Antenna activations12, Plasma releases11; peak minions10, projectiles5, route keys11; 34 actual intermission JSON round-trips.

## Extended Hell attrition

A fresh actual earned Cursed Mansion Hell run, seed115, used the same legitimate policy and was allowed up to7200seconds. It **lost on wave46 after45 cleared waves at4688.6seconds** (78.14 simulated minutes), after allfive NPC allies were eliminated. The player had allseven room expansions and Needle/Arc/Barrier/Plasma/Antenna Level10. There was no forced outcome, debug damage, resource injection or wave jump. The completed run passed310,167 repeated invariants, with45 genuine intermission JSON restores, in81.826 Linux wall seconds. This provides a concrete late-pressure loss alongside the earlier bounded living cases; it is not an exhaustive strategy proof.

`earned-cursed_mansion.json` is the last genuine sealed wave45 model checkpoint. It contains earned actual investment, geometry, resources and surviving player state, suitable for a separately labeled real-state rendered inspection. It is not a user profile and does not grant rewards.

## Failures and fixture corrections

The first probe compared an absent optional specialization key to canonical saved empty-string data and falsely reported an investment change. Only the test normalization was corrected; original probe log/result are retained. A diagnostic policy also repeatedly requested a bed upgrade while its displayed door prerequisite was unmet; the final policy follows that actual prerequisite through paid upgrades. The earlier policy results remain separately labeled. Neither finding required production changes.

## Limits

No balance parameter changes are recommended from these finite cases. Normal ally contribution can be substantial; the tested Hell passive controls lose, but broader human playtesting remains required. No online fairness, native Windows performance, human usability, perceived horror or sound quality is verified. Finite object/health/currency/slot/minion/projectile checks are not proof against every possible long-session defect.

Runtime hashes are recorded before/after. The parent confirmed interface tooltips, branch-preview formatting and Plasma label positioning are presentation-only. Independent final diff review also confirms the later Game change only expands camera framing around a nearby live Hunter. Actual damage/economy/resolver behavior is unchanged.
