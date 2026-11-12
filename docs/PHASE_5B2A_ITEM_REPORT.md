# Phase 5B-2A — advanced Rare and Epic items

Continued clean `work` at `23333de60f5abf783d69666a61703f1ef7428f4d`.
Recovery tag `pre-phase5b2a-23333de`. Agent B owns production; C independently
tests transactions and combinations; A performs a bounded balance review;
D reviews actual rendered presentation and audio when implementation is ready.

IMPLEMENTED: sixteen functional items, revised odds and readable/reduced effects.
TESTED: independent mechanics/combinations, regular/extended regressions and actual Linux render/audio below.
UNVERIFIED: native Windows and subjective human experience/balance.
INCOMPLETE: no requested mechanic deferred; Legendary items remain out of scope.

## Mechanics and stacking rules

The eight existing items and two-slot inventory architecture remain. Eight new
IDs extend the same definitions, receipts, stock limits and active snapshots.
Tuning remains centralized in ItemCatalog. No Legendary mechanics or extra slots.

| New item | Rarity | Functional rule |
| --- | --- | --- |
| Iron Barricade | Rare |25%incoming player-door reduction for20s, before Shield absorption |
| Last Stand Feather | Epic | Equipped/available, automatic once per match on a nonlethal crossing from above25%doorHP to25%or below; heals15%maximum |
| Inferno Ammo | Epic |15s owned-turret impact ignition; refreshes one4s burn at12DPS, Reaper receives60% |
| Golden Pillow | Rare | Occupied living player's bed income ×1.5 for25s |
| Construction Coupon | Rare | Free reservation; one building purchase/upgrade costs60%of its original gold and electricity |
| Ghost Decoy Doll | Epic | Existing-route distraction toward deployed doorway target, up to8s; Reaper4s |
| Team Rescue Signal | Rare | Select one living teammate with an intact damaged door; restore25%maximum |
| Shadow Smoke | Epic | Reduce own room priority for6s, Reaper3s; one valid alternative may be selected |

Feather saves its stock deduction before healing and marks its per-match trigger
only after success. It ignores manual-item cooldown, cannot restore a broken
door and cannot retrigger with additional stock. Feather resolves before the
existing First Aid perk; if its heal lifts HP above the perk's threshold, First
Aid remains available for a later crossing. Otherwise both can resolve once.

Barricade is one nonstacking modifier. Its reduction precedes Shield, extending
the finite shield pool without adding invulnerability. Inferno requires real
owned-projectile impacts, not firing animation; repeated hits refresh one burn,
never add independent stacks. Timed damage and income use fractional expiry
integration to avoid extra/lost full-tick awards. Golden Pillow applies no bonus
to inactive beds and composes with existing income boosts.

Coupon reserves without spending. Full prerequisites, current funds and an
immutable discounted quote are checked before saved stock consumption and the
validated payment. Building paid-gold and paid-electricity ledgers record the
actual60%cost; subsequent sale returns exactly half those investments. Invalid
purchase, failed save, occupied tile and maximum upgrades spend no coupon.
Bed/door upgrades are outside this building coupon's scope. Fractional costs and
refunds are retained. Preview and savings feedback expose the actual amounts.

Decoy and Smoke share20s recovery to prevent alternating permanent interruption.
They do not teleport the Hunter, bypass intact doors, revive a dead target or
remove the last valid target. Decoy distracts movement toward an actual reachable
point; Smoke changes room preference and may redirect to another valid room.
No alternative means existing attacks remain possible. Special attacks recover
through existing cancellation/navigation logic. Temporary state clears on
expiry/results/reset; the original finite-stock and nonstacking rules remain.

## Lucky Spin and save compatibility

The same persisted inventory grant/reveal receipt transaction remains: spinning
or skipping never chooses another item or adds stock twice. Existing stock,
equipped items, old receipts, XP, Mythic status, settings and campaign data are
preserved. Victory still awards up to4units of one type; Consolation1, with the
existing qualification rules and9999stock cap.

The old60/40Victory and90/10Consolation Common/Rare split is deliberately expanded:
Victory Common40%/Rare40%/Epic20%; Consolation80%/16%/4%. Each of four Commons
is10%on Victory and20%on Consolation. Each of eight Rares is5%/2%, and each of
four Epics5%/1%. Exact odds remain visible. This gives every new implemented item
a chance while retaining better victory quality and excluding unfinished tiers.

## Balance and validation

A bounded independent design review checked mitigation order, automatic rescue,
immutable coupon quotes/refunds and shared targeting recovery. Inferno burn was
set to12DPS so its capped duration is meaningful compared with the existing
220base-damage trap, without uncontrolled per-turret stacking.

Sixty matched comparisons use five maps, three modes, two policies and4units of
each selected type in a two-type fixture budget; match currency is earned.
Pairs are Barricade+Inferno and Pillow+Feather. Baseline→advanced outcomes:
Normal10W/0L→10/0, LongNight8/2→9/1, Hell2/8→5/5, zero invariant failures.
115manual activations were observed; automatic Feather events are not included
in that counter. These are limited policies, not human rates or coverage of all
120item pairs, stockpiles or seeds. The tested budget did not guarantee Hell wins.

Independent C:7,988checks passed with zero final failures. Coverage includes all
16definitions/tables/icons, old inventory and pending receipt migration, coupon
both-currency discounted ledger/refunds and save failures, automatic Feather
boundaries/once/First Aid, Barricade+Shield, exact Pillow integration at0.1/.5/1/30s,
owned-impact burn cap/resistance, teammate validation, all-map control navigation,
last valid target and shared recovery, settings persistence and no stock exploits.

An additional27focused checks passed: active Inferno+Overdrive produced12real
shots versus9in8s, with one bounded burn whose DPS was not multiplied; Frost+
Decoy/Smoke preserved Reaper movement/resistance/navigation and expiry. The
Reaper subsequently resumed a genuine charged warning and damaging siege strike.
This is concrete interaction coverage, not a claim every pair was simulated.

The original eight-item suite retains its mechanics assertions and passes3,195
checks; only registration/odds checks and the original-eight test loop were
adapted for16definitions. Existing activation-feedback13, campaignflow126,
Mythic200+7, rank350, purchase/refund314+421 and prior scene/input/save tests pass.
Regular regression completed in batches: model126, boss6,699 +25architecture
+42audio checks,60boss comparisons,90difficulty simulations with unchanged
Normal29W/1L,LongNight18W/12L,Hell3W/27L;15,348map-core +5,107integration +922UI,
144mapmatches79W/65L;85campaignprofile and20matches9W/11L. Original item60matched
comparisons also retain10/0Normal,10/0Hard,8/2Hell item-arm outcomes.

General audio223checks passes with76streams/four music starts. Legacy12matches
9W/3L;20ktransactions/175,941invariants,6rates; extended27timestep,144room/strategy,
48rank/perk matches22W/26L all pass. Separate-process profile cleanup/write/read/
cleanup and main startup pass. No assertions were disabled. Project and Windows
export settings are unchanged.

Actual Godot4.6.3/Mesa:84rendered checks pass,20PNGs captured and inspected by D.
Coordinator additionally viewed combined mitigation/number lanes, discounted
purchase preview and teammate rescue frames. Both inventory pages, Epic odds/
reveal, all eight effects, real coupon purchase/refund, Reaper burn, targeting,
Reduced Effects persistence and Retry sound reset are covered. A15.047s actual
master-bus recording is non-silent, peak1294/32767,RMS201.49,zero clipped samples.
All eight new cues play;76streams decode with no missing assets; four permanent
music stems remain. These are prepared isolated fixtures, not natural matches,
human listening or Windows certification. See evidence README for provenance.

Visual changes aggregate repeated item/phase values into spaced foreground
lanes separated from door/shield HP, with particles underneath. Reduced Effects
persists in Settings: three particles instead of ten, four smoke puffs instead
of nine. Core effects, indicators, numbers and gameplay remain active.

Confirmed implementation issues fixed: coupon preview/affordability using the
undiscounted cost, activation audio being dropped in dense frames, and the
three-rarity heading overflowing. Important earned cues now use the existing
bounded priority/retry queue; voice/frame limits were not raised. Initial QA
failures from missing pre-generation art and direct-room economy fixtures were
corrected to exercise complete assets and actual model integration. A floating
threshold fixture now tests an exact boundary. Failed evidence remains alongside
passing reruns. No known functional failures remain in tested paths.

## Unverified and scope

Native Windows import/launch/controls/FPS and subjective visual/audio appeal and
human balance remain unverified in Linux cloud. Windows checklist: load an old
work-profile; verify all old stacks/receipts/perks/XP/stages; inspect both inventory
pages and odds; toggle/reload Reduced Effects; test Feather once, coupon failed
purchase/success/sale, shield mitigation, burning impacts/expiry and Pillow income;
select a valid/invalid teammate; deploy Decoy and Smoke against normal and Reaper;
pause/retry/results and confirm cleanup. Recheck purchases, double clicks,
cancellation and separate-currency refunds on all maps.

No Time Freeze, Reaper Seal, Guardian Heart, Cursed Fortune, new ranks, maps,
bosses, multiplayer, achievements or Android work is included. Final response
records the actual latest commit and verified private work push.
