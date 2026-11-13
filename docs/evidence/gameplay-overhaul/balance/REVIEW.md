# Independent gameplay balance audit

**ACCEPTED on final first-contact-telegraph mechanics.** All39 final cases completed with zero invariant failures. This audit does not substitute for human difficulty approval.

## Scope and method

Actual Godot4.6.3 model simulations on Linux use legal player navigation, claim/sleep, paid placement/upgrades/exclusive branches, repairs and room expansion. Starting wallets25 Gold/0 Electricity, no perks or consumables, no live resources/HP/positions/clocks/wave injection. Campaign Hunters use the real strategy configuration; Endless follows the normal seeded six-Hunter cycle. No user save is opened. This is automated gameplay simulation, not manual playtesting or native Windows execution.

Per-second checks repeat invariants and are not unique gameplay scenarios. Profile rank/reward transactions and full regular/extended regressions belong to the parent task.

## Final accepted gates

| Gate | Cases | Repeated checks | Failures | Linux wall seconds |
| --- | ---: | ---: | ---: | ---: |
| campaign | 27 | 248,625 | 0 | 41.249 |
| electric | 8 | 74,087 | 0 | 9.812 |
| endless | 3 | 750,560 | 0 | 218.620 |
| long | 1 | 296,700 | 0 | 84.296 |

## Final campaign strategies

| Hunter/map | Mode | Bed/door-only | Active, no new magic defenses | Active, early magic investment |
| --- | --- | --- | --- | --- |
| witch/abandoned_dorm | standard | victory at205.0s | victory at160.0s | victory at160.4s |
| witch/abandoned_dorm | hard | victory at171.3s | victory at171.3s | victory at171.3s |
| witch/abandoned_dorm | hell | defeat at186.4s | victory at179.3s | victory at179.7s |
| electric/underground_lab | standard | victory at224.1s | victory at234.8s | victory at223.1s |
| electric/underground_lab | hard | victory at186.7s | victory at186.7s | victory at186.7s |
| electric/underground_lab | hell | defeat at144.5s | defeat at137.5s | defeat at137.5s |
| storm/cursed_mansion | standard | victory at242.5s | victory at194.6s | victory at194.6s |
| storm/cursed_mansion | hard | victory at222.6s | victory at195.6s | victory at195.6s |
| storm/cursed_mansion | hell | defeat at206.6s | victory at199.5s | victory at242.7s |

The three initial Hell passive controls lose. Normal/Long passive victories remain accessible. Active no-magic policies beat Hell Witch and Storm, so new magic buildings are not mandatory in these tests. Early magic investment changes actual budgets and outcomes; it is a strategic opportunity cost rather than an automatic upgrade over offensive investment. The Lab Electric fixture defeats both tested fresh active policies. Additional Electric Hell controls below test other seeds/maps; a finite strategy sample is not a universal win-rate estimate or proof that a map is unfair.

| Extra Electric Hell map/seed | Active without new magic defenses | Early magic investment |
| --- | --- | --- |
| abandoned_dorm/127 | victory at201.9s | victory at226.3s |
| haunted_hospital/164 | victory at194.2s | victory at200.0s |
| underground_lab/238 | defeat at164.4s | defeat at152.9s |
| cursed_mansion/275 | victory at198.0s | victory at223.8s |

## Earned room and Level10 progression

| Map/mode | Slots16 earned | True waves cleared at3600.1s | Earned Level10 types |
| --- | --- | --- | --- |
| abandoned_dorm/standard | 386.7s, wave9 | 39 | turret, heavy, barrier, plasma, antenna |
| underground_lab/hell | 392.1s, wave7 | 35 | turret, heavy, barrier, plasma, antenna |
| cursed_mansion/hell | 329.7s, wave5 | 35 | turret, heavy, barrier, plasma, antenna |

All seven expansion purchases use exactly6,560 Gold/1,105 Electricity in addition to actual Bed/Door upgrades. The run itself uses normal waves and actual earned production; no debug top-up is used. Each intermission is JSON round-tripped and its actual investment/tier fields checked. Earlier bounded living runs do not establish permanent invulnerability. Actual player new-defense events (separate from NPC events):
- abandoned_dorm: absorbs18, reflects6, Antenna activations7, Plasma releases6; 39 actual intermission JSON restores. Peak minions10, projectiles8, navigation route keys11.
- underground_lab: absorbs40, reflects15, Antenna activations16, Plasma releases15; 35 actual intermission JSON restores. Peak minions10, projectiles6, navigation route keys11.
- cursed_mansion: absorbs49, reflects17, Antenna activations19, Plasma releases18; 35 actual intermission JSON restores. Peak minions10, projectiles5, navigation route keys11.

## Extended genuine Hell pressure

The fresh Cursed Mansion Hell seed115 policy was allowed up to7200seconds. Final outcome **defeat on wave46, after45 cleared waves at4487.5seconds** (74.79 simulated minutes). Living NPC allies at the end:0. Player earned16slots and turret, heavy, barrier, plasma, antenna Level10. No forced outcome, debug damage or resource injection was applied.

`earned-cursed_mansion.json` is the last genuine sealed intermission model checkpoint, suitable for separately labeled earned-state rendering. It is not a user profile and does not grant rewards.

## Preserved failures and source changes

The first diagnostic probe falsely compared an absent optional specialization key against canonical saved empty-string data; only test normalization was corrected. A diagnostic strategy also repeatedly requested a Bed upgrade behind an unmet Door prerequisite; the final strategy follows that actual prerequisite through paid upgrades. Both older logs/results remain labeled, not presented as final acceptance.

After the first39-case audit, a preserved regression exposed a real first-basic-attack telegraph omission for the three new magical archetypes. The developer fixed it and verified all six Hunters across all three difficulties. **All39 balance cases were then rerun on the actual final warning behavior.** The entire prior result set, original hash maps and harness are preserved under `before-contact-telegraph-fix/`; their outcomes are not relabeled final.

Source hash maps record the actual runtime scripts. During the final39-case rerun, only AudioDirector changed: independent Git-object/hash comparison confirms it maps the three new archetype warnings to valid existing sampled cues. It does not mutate the model. All gameplay script hashes are identical before/after the final run. Earlier tooltip/branch-preview/Plasma-label and camera-framing corrections were presentation-only; their earlier evidence remains archived. No unreviewed gameplay/economy change was assumed equivalent.

## Limits and recommendations

No balance parameter change is recommended from these finite cases. New magic defenses are useful against magic and optional in winning controls; the fresh Lab Electric Hell fixture remains difficult under both policies, while other maps/seeds provide winning controls. Meaningful long-run loss and ally attrition are observed where recorded, not scripted. This does not prove every strategy is fair, every session eventually loses, or every long session is leak-free.

Native Windows execution/performance, human usability, perceived art/music/SFX quality and owner/Adie difficulty approval remain UNVERIFIED. No public release, multiplayer or Phase6 work is part of this audit.
