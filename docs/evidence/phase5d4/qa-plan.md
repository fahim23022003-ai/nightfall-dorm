# Phase5D4 independent QA plan

C owns only new `tests/phase5d4_qa*` and QA evidence. Root runs final existing
regular/extended and owns legacy fixture ports; B owns gameplay/UI, Audio owns
AudioDirector/assets. No production/Git edits by C. Baseline97 is complete and
frozen before release of the implementation gate. A/D provide natural balance,
rendering and actual mixer evidence separately; no human approval is inferred.

## Early UI gate

Actual Game scene, ordinary mouse/physical-key controls, 720/1080-compatible
coordinates, isolated returning/fresh profiles and all five maps. Assert a single
fixed bottom context parent for empty/build/upgrade/bed/door/branch confirmation;
record camera/zoom/target/player/model/RNG/wallet before and after previews.
No movement or debit before Confirm, safe Cancel/back, double-click exactly once,
correct current/next/discount/branch cost/disabled reason/current resources.
Scroll-aware visibility must distinguish genuinely clipped cards from outside
viewport controls. Repeated open/close does not accumulate UI nodes. Existing
spectator/home/danger/item/repair flow remains valid. Effective stat expectations
include genuine support/item/perk effects exactly once, with branch tradeoffs.

## Evolution attribution and fifteen effects

Use genuine primary/minion bed-contact elimination and central validated API,
not synthetic event emission. Registered living attacker/contact/breached living
victim required. Dead/unowned/invalid/out-of-contact/fake actor/repeated victim
requests cannot award. One owner identity receives one credit even if two actors
reach it in the same frame. Player terminal credit occurs before cleanup.

Seeded eligible kills expose all fifteen named choices across independent runs;
verify actual mechanical effects/limits, not registration or skin alone. Explicit
eligibility/deferred-only behavior for boss/minion-specific effects. Aggregate
caps, no repeated multiplication, expiry and new-match reset. NPC/player/minion
source distinctions and event order are captured. No evolution reward from actor
despawn or fake death events. Campaign/endless/practice/challenge eligibility is
covered rather than assuming every mode shares permanent rewards.

## Boss and minion integration

Run real model ticks through eligible transformation, PhaseII and once-only
final10% encounter. Main HP must never increase from transition/guards; large
hits cannot cause repeated guards/refills or rearm ultimate after healing.
Actual stage/difficulty eligibility explained, not force every Normal stage.

All eleven major abilities need actual activation/damage/state tests, including
small/ten-member summon cap, enhanced minion stats, bounded SoulSteal, actual
quarter-door ScytheSlash, lock failure/no item consumption, projectile throw/
embed/duration/destruction attempts (including a real L10 machine), exact half
current fractional Gold/Electricity after completed SoulReaper, all valid living
doors affected by PhantomScream, and temporary production freeze with unchanged
stored resources/no banked catch-up. Channels interrupt through real incoming
hits/controls/Seal; no duplicate completion or permanently stuck lock.

CrimsonExecution chooses one real living player OR NPC room, uses real navigation
and one scythe/domain controller. Minions clear/suspend, foreign room attacks and
foreign turret fire cannot violate1v1. Target defenses/items/repairs work; test
win, actual target death, timeout and boss death. All cleanup paths remove scythe,
locks/domain/music intent/camera overrides without resetting identity or HP.

Attackable IDs: each projectile damages its actual selected actor. Dead/despawned
or recycled-slot old IDs cancel, never fallback to the boss/new actor. Repeated
summon/death/domain/wave cycles bound active actors<=10, slot routes and graph
cache keys, projectiles, FX/events and actor references; monotonic identity does
not imply unbounded route dictionaries. Windows performance remains unverified.

## New machines, economy and role scope

Twelve registered machines (six preserved plus flame/frost/shock/auto_repair/
shield/decoy), structural bed/door separately. Every real machine gets paid1–10,
two exclusive paths, no11, genuine coupon prices/branch fee/failed-write rollback,
exact separate half-capital Gold/Electricity refunds, no repeat sale and pad reuse.
Operating Electricity/Gold is not refundable capital. Active barriers/lures/
charges do not duplicate through sale/rebuild/reload or leave stale targets.

Measure actual Flame impact/DoT/spread caps, Frost movement/attack slow/boss
resistance/shared control recovery, Shock cooldown and anti-stunlock, paid repair
and no-energy stop, shield finite capacity/refractory/energy cost, decoy legal
navigation and finite lure/refractory. All role-specific tradeoffs must affect
real behavior. New private tuning cannot leak as global range/rate/repair-cost
buffs. Cooling/Ballistic global effects remain explicit/capped; original Needle/
Arc calculations and support economics are retained. Natural reachability is A's
independent earned-policy evidence, not transaction-fixture budgets.

## Persistence, Challenge and existing items

Frozen genuine profiles `qa-frozen-5d3-normal.json`, `qa-frozen-5d3-hell.json`
contain all eight old systems atL10; `qa-frozen-5d2.json` covers older ruleset1
and unselected structuralL5. Validate old data survives unchanged before using
new paths. New snapshot stores buff+dead victim ledger atomically at between-wave
checkpoint; midwave replay rewinds BOTH, so no banked extra buff. Durable consumed
items remain spent. Completed checkpoint resume cannot recredit an old victim.
Canonical string owner keys survive JSON serialization. Unknown future/malformed
branch/credit/timer data remains safely rejected/read-only, never overwritten.

New Challenge ruleset3 normalizes actual Game conditions; strict archival1/2
records survive but old imports reject clearly. Fresh-engine full traces across
beginner/progressed profiles must agree under same inputs/seed, including minions
and evolved outcomes. No online/cross-platform bitwise claim.

All20 consumables retain limits/counters. Test Shield/Barricade/Guardian/Feather
against explicit actual victims (never fake hunter.target for area/minion hits),
Seal/Freeze interrupt new casts and locks, and failed activation consumes nothing.
Practice uses temporary state and gives no XP/cash/spins/achievements/campaign/
Endless record changes. Rewards/claims cannot duplicate through results/reload.

## Evidence and failure policy

Each gate records actual exit status, engine errors, assertion counters and
warnings; an exit0/counter0 does not override a SCRIPT ERROR. Preserve initial
failures, distinguish harness assumptions from product defects and rerun only
affected gates after focused fixes. Never mutate a running runner or historical
evidence. Counts include repeated invariants, not independent human sessions.
