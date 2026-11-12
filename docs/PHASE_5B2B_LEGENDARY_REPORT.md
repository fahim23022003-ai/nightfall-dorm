# Phase 5B-2B — Legendary items and cinematic effects

Starting point: clean `work` at `b4d1798d82a458636eebb1b62419f7e0bbd66b7d`,
confirmed against the private GitHub remote. Recovery tag:
`pre-phase5b2b-b4d1798`. Existing architecture and Phase 5B-2A reports reviewed.

IN PROGRESS: implementation and independent verification. This draft is not a
completion or passing-test claim. Final results will replace this section.

Agent B owns production implementation; Agent C owns independent mechanics and
balance tests. Agent A provides a bounded design audit. Agent D will inspect
actual rendered effects and engine audio after presentation is ready.

Native Windows gameplay and subjective audiovisual quality remain UNVERIFIED
unless directly tested. Linux screenshots and engine recordings cannot establish
those claims. Phase 5B-3, Android and unrelated features remain out of scope.

## Mechanics and transaction rules

Four IDs extend the existing catalog and two-slot loadout. Tuning is centralized
in `ItemCatalog.TUNING`; existing rank, stage, map and difficulty definitions
are unchanged.

| Item | Gameplay rule |
| --- | --- |
| Time Freeze | Stops Hunter movement, windups, attack/cooldown and transformation progression for 3 seconds, or 1.5 seconds for an already transformed Reaper. Economy, player input, projectiles and damage continue. Shares the existing 20-second control recovery with Decoy/Smoke. |
| Reaper Seal | Counters an active, telegraphed Reaper special against a valid intact door while the boss is at its attack position. Preserves special cooldowns and gives at least 1.25 seconds of recovery. Ordinary attacks, dead bosses and invalid windows cannot spend it. |
| Guardian Heart | Equipped automatic interception of lethal damage after mitigation and existing absorption. Restores the intact door to 15% maximum HP and grants a finite 20%-maximum-HP shield lasting 3 seconds. The rescued hit does not also trigger Feather or First Aid. |
| Cursed Fortune | Grants exactly 500 in-match Gold once. For 20 seconds, Hunter damage is multiplied by 1.25 and attack intervals by 0.8; modifiers are recomputed from normal difficulty values rather than permanently changing base tuning. |

One successful Legendary activation per match includes Guardian Heart. The
counter is persisted in the active match together with stock deduction before
any effect is applied. Save failures roll back inventory, selection and counter.
An old save with no counter defaults to zero. Binding the same match cannot lower
a used counter. Unused items remain in the existing persistent inventory.

Guardian protection is a finite pool, not invulnerability: another sufficiently
large attack can still break the door. Barricade mitigation applies first,
Guardian absorption then existing Emergency Shield; the Heart only intercepts
remaining lethal damage. No duplicate consumption or additional automatic heal
is permitted from that intercepted hit. Later valid nonlethal threshold crossings
can still use the separately equipped Feather or existing First Aid perk.

Freeze uses fractional frame time at expiry and leaves the Hunter damageable.
Global match time and economy continue; difficulty growth uses the existing
match clock and catches up when Hunter actions resume. Cursed Fortune's damage
and interval combination implies approximately 56.25% greater sustained attack
pressure while active, subject to real telegraphs, navigation and cooldowns.
Neither effect changes Hell Mode's baseline tuning.

## Reward distribution and compatibility

| Rarity | Victory total | Consolation total | Each item, Victory / Consolation |
| --- | --- | --- | --- |
| Common (4) | 40% | 80% | 10% / 20% |
| Rare (8) | 40% | 16% | 5% / 2% |
| Epic (4) | 16% | 3% | 4% / 0.75% |
| Legendary (4) | 4% | 1% | 1% / 0.25% |

This deliberately reallocates four Victory percentage points and one Consolation
percentage point from Epic to Legendary. Common and Rare probabilities remain
unchanged. Integer weighted sampling (1,000 Victory units; 4,000 Consolation
units) represents quarter-percent probabilities exactly. Existing reward
qualification, up-to-four Victory units, one Consolation unit, 9,999 stack cap,
persisted receipts and acknowledgment rules remain. The animation cannot choose,
reroll or grant a reward; previously awarded receipts retain their item and amount.

## Verification pending

Independent mechanics, combinations, matched balance simulations, regular and
extended regressions, rendered inspection and engine audio are in progress.
Final counts, evidence, findings and remote push verification will be recorded
here after checks finish.
