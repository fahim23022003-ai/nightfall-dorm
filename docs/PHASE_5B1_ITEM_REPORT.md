# Phase 5B-1 — Lucky Spin, inventory and consumables

Continued clean existing `work` at `c3bdc49b7c536f11b9601bd4e3c71995954b8d86`.
Recovery tag `pre-phase5b1-c3bdc49`. Agent B owns production; C independently
checks transactions/effects/balance; A provides a bounded anti-farming review;
D inspects actual rendered effects and audio. No future item tiers or phases.

IMPLEMENTED and TESTED: all eight items, reward/inventory flows and regression checks below.
UNVERIFIED: native Windows and human experience/balance.
INCOMPLETE: no requested production mechanic deferred; future tiers are out of scope.

## Implemented mechanics and transactions

The existing profile gains an optional versioned consumables section: stacked
inventory, two selected item types, and a bounded queue of persisted reveal
receipts. XP, seven ranks, perks, settings and campaign records remain in the
same save. Missing fields migrate to empty inventory; damaged/future consumable
data preserve base progression and prevent unsafe writes. Active item snapshots
are validated independently of current stock, allowing a consumed slot to reach
zero safely. Inventory stock is capped at9999; receipts report the actual grant
when the cap limits a stack.

A valid finalized victory uses the existing performance eligibility and requires
a dead Hunter and living player. Consolation requires a dead claimed resident,
60occupied seconds and at least100Hunter damage or100door damage taken. Aborts,
instant defeats and otherwise ineligible results receive no spin; the results
explain the eligibility rule. These are disclosed anti-instant-loss/contribution
gates, not proof that every intentional farming strategy is impossible.

At settlement, a separate reward RNG rolls only the eight functional items and
saves the inventory grant plus receipt with progression. The selector animates
that predetermined item; skipping changes only animation. Reveal acknowledgement
removes one receipt and saves it, never grants inventory again. Reload/menu can
resume queued reveals. Actual result actions and new-match entry are gated until
reveals are acknowledged. Failed save states are shown honestly and the spin
retries persistence before claiming the reward is safely stored.

One Victory Spin grants up to4units of its single item type; Consolation grants
1. Victory odds are15%each Common and10%each Rare. Consolation odds are23%repair,
23%gold,22%battery,22%radar,3%shield,3%overdrive,2%frost,2%trap. Exact odds and
quantities are visible. No Epic/Legendary results, purchases or paid spins.

Inventory has original icons, names/rarities, stock, descriptions and tooltips.
Its two-slot selection is reached from the existing preparation screen, separate
from the one permanent perk. Equipping spends nothing. Consuming the last unit removes that type from future selection, while the
active hotbar retains its empty slot. Active-match snapshots
prevent future loadout changes from altering the current hotbar. Only successful
activation spends stock: validate, save the decrement, then apply synchronously;
failed saves restore stock and never apply the effect. Double clicks/key repeats
are blocked by existing input handling and a1second global item cooldown.

The hotbar supports keys1/2 and mouse buttons, quantities, active durations,
shared cooldown, disabled states and explanations. It adds no blocking gameplay
modal. All temporary effects clear at results/reset and pause with the match.

| Item | Actual effect and limits |
| --- | --- |
| Instant Repair Kit | +25%maximum door HP, capped; intact damaged door only |
| Gold Supply Crate | +150match Gold |
| Emergency Battery | +80match Electricity |
| Hunter Radar |30s live coordinates/target HUD and locator rings; removed on expiry |
| Emergency Shield |30%maximum door HP absorption pool for15s; damage overflow reaches the door |
| Turret Overdrive | Player turret/heavy firing interval divided by1.35 for12s |
| Frost Bomb |40%movement reduction for7s; Reaper resistance reduces slow to25% |
| Explosive Trap | Valid doorway approach,30radius,220base damage once (normal vulnerability/HP-clamp rules apply),45s expiry |

Canonical tuning is in ItemCatalog.TUNING. Nonstacking active effects cannot be
reapplied; trap deployment is limited to one. Trap movement uses swept collision
before breach transitions, including large timesteps and exposed pursuit. Death
cannot be overwritten by arrival state changes. Trap damage is clamped to actual
HP loss and credited to the player. Shield damage numbers reflect real absorbed
and door damage separately. Frost recalculates against current Hunter form.

Presentation uses eight original authored SVG icons, a spinning reward wheel,
rarity-colored reveal, short item feedback, repair crosses/green HP values,
crate opening/coins, lightning, radar locator, shield dome/HP/sparks, glowing
faster turrets/projectiles, frost on the Hunter and trap/explosion effects.
Expiry has a visible end cue. Twelve original synthesized WAVs extend56assets to
68: eight activation sounds plus reveal, explosion, shield impact and ending.
Generators are offline/reproducible under tools/art and tools/audio. Existing
four music stems, saved volumes, voice budgets and original assets are preserved.
Effects are bounded, use ten particles per event and no added screen shake;
a separate reduced-effects setting was not needed for this modest renderer.

## Balancing observations

A targeted economy review identified that one item per60s defeat could outpace
one per160–200s victory. Victory stacks were increased to4 while retaining one
spin and one rolled type. For160–200s wins this yields1.2–1.5units/minute versus
1unit/minute at the minimum qualifying loss, with substantially higher rare
throughput. Long wins or farming a specific Common can still have different
incentives; offline contribution gates are not universal intent detection.

Sixty matched simulations use five maps, three modes, two policies, and with/
without items. The item arm receives a disclosed fixture budget of4units per
equipped type in two types, equivalent to two Victory Spin quantities; Gold and
Electricity remain earned normally. Baseline→item outcomes: Normal10W/0L→10/0,
LongNight8/2→10/0, Hell2/8→8/2;134successful activations, zero invariant failures.
These are limited deterministic strategies, not human rates or coverage of every
item pair/stockpile. The tested Hell budget did not guarantee victory. Normal
remains playable without consumables. No blanket combat/economy nerfs were made.

## Validation

Independent Agent C final suite:3,179checks, zero failures. An additional13actual-controller feedback checks pass for precise full-door, no-stock, empty-slot and read-only reasons, with no invalid consumption. It covers weighted
seeded rolls, victory/consolation eligibility, real receipts/stack quantities,
claim/skip idempotency, old-save migration, corrupt/future fields, snapshot
validation, two-type ownership limits, failed-save rollback, all eight effects
across five maps/three modes, real firing/movement/absorption, pause/expiry,
large-step trap crossings, last-stock future deselection and no leakage/replay.
Campaign UI now exercises Results→Spin→Skip→Reveal→Next/Retry and retains prior
stage/loadout assertions:126checks passed. Existing rank UI63checks passed.

Regular regression completed in resumed batches: model126, boss6,699 +25state
and42audio checks,60boss comparison matches,90difficulty matches with unchanged
29W/1LNormal,18W/12LLongNight,3W/27LHell. Maps15,348core +5,107integration
+922UI checks,144matches79W/65L. Campaign85profile and20matches9W/11L;
Phase1purchases/refunds314+421; horror319+21+5; rank350; priorMythic200+7;
controls54/layout196; general audio207checks/68streams/fourmusic starts;
projectile, furniture, scene, availability and old UI suites pass. Legacy12matches
9W/3L;20ktransactions/175,941invariants and6rate scenarios pass. Extended27timestep,
144room/strategy and48rank/perk matches22W/26L pass. Separate-process profile
cleanup/write/read/cleanup and main startup pass. No assertions were disabled.
The old campaign test's direct Next button expectation was updated to traverse
the actual new reward gate; its original semantic coverage is retained/expanded.

Actual Linux Godot/Mesa:92rendered checks passed,23PNGs captured with representative
frames inspected by D; coordinator also viewed victory reveal, shield absorption
and small-window radar. Actual keyboard/mouse activation, Retry sound reset,
wheel skip/reveal, inventory descriptions, all eight effects and expiry are
covered. A15.418-second actual engine mix is non-silent, peak1071/32767,
RMS183.02, zero clipped samples. All eight activation cues plus reveal, shield
hit, trap explosion and ending played;68streams decode with no missing assets.
Four permanent music starts remain unchanged. Prepared fixtures are not natural
matches or human listening. See docs/evidence/items/README.md.

Confirmed issues fixed: trap tunneling across a large movement step; malformed
saved item snapshots; same-model Retry suppressing fresh audio events; clipped
inventory description; missing crate opening; ambiguous damage/absorption text;
last-stock future selection/rollback; and durability wording before a failed save
was retried. Final controller feedback also preserves exact activation failure reasons
instead of replacing them with a generic message. Relevant cases reran. No known functional failures remain in tested
paths. Dense prepared bursts can overlap transient numerical values near the
door; essential HUD/controls remain accessible. This cosmetic limitation and
subjective effects quality remain for human playtesting.

## Unverified and scope

Native Windows execution, subjective audio/fear/satisfaction, PC performance and
broad human economy/balance remain unverified. Manual Windows checks: import the
latest work ZIP in Godot4.6.3, load an old profile, complete a real win and a
qualifying defeat; inspect odds, skip/reload/reveal once; equip two types without
spending, use keys1/2 and mouse, test failed activation, pause/expiry/results;
verify unused stock and XP/stages/perks survive restart. Test shield overflow,
overdrive cadence, frost/Reaper transition and trap before a breach. Recheck
building double clicks/cancel/sell/refund and all five map layouts.

No remaining12items, Epic/Legendary mechanics, Mythic item unlocks, maps, bosses,
achievements, Android or Phase5B-2/3 were implemented. Final response reports the
actual committed SHA and verified private work push.
