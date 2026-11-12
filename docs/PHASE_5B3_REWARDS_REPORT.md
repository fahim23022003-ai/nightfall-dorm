# Phase 5B-3 — rank perks, achievements and meaningful rewards

IMPLEMENTED: seven perks, Master slots, twelve achievements/rewards, saved stage
choices and original feedback. TESTED: independent QA, 160 simulations, full
regular/extended regression, actual rendering and engine audio. UNVERIFIED:
native Windows and subjective quality/human balance. INCOMPLETE: none of the
requested implementation; no known functional failure remains.
Baseline clean `work` at
`88a6821aaa3df885f2fcf954eb817b2961ffc6e6`; remote verified.
Recovery tag: `pre-phase5b3-88a6821`.

Agent B owned production, C independent QA, A a bounded design review and D actual
render/audio inspection. Native Windows and subjective quality are UNVERIFIED.
Stop after Phase 5B-3.

## Perk compatibility and loadouts

The suggested effects overlap the existing six perks. Their IDs, unlock ranks
and tuning are preserved to keep existing profiles and strategies valid:

| Rank | Existing perk | Actual bonus |
| --- | --- | --- |
| Bronze | Pocket Change | +5 starting Gold |
| Silver | Reinforced Frame | +5% door maximum HP |
| Gold | Deep Sleeper | +3% occupied bed Gold income |
| Platinum | Clean Current | +4% Dynamo Electricity |
| Diamond | Steady Aim | +3% turret damage |
| Master | Last Light | Once below 25% intact door HP: heal 10% |
| Mythic | Reaper Slayer (new) | +6% owned-turret damage against transformed Reaper |

One permanent slot applies below Master; Master and Mythic allow two. Consumables
retain their separate two item-type slots and one Legendary activation limit.
Mythic requires the existing accomplishment gates as well as XP.

## Stage choices and achievement definitions

The new catalog defines three next-stage options: +5% door maximum HP, +25 starting
Gold, or +8% owned-turret damage until 60 seconds after Hunter arrival. Choices
are saved, unique and applied to their intended stage only.

Twelve deterministic achievements cover victory, Hunter defeat, Long Night,
Hell, Reaper defeat/three defeats, a full surviving team, 1,500 actual door
damage, 10,000 occupied-bed income, 30 purchases/upgrades, ten distinct item types,
and a successful Legendary activation during an eligible completed match.
Actual rewards and validation are recorded below.

| Achievement | XP | One guaranteed item |
| --- | ---: | --- |
| First Victory | 15 | Instant Repair Kit |
| First Blood | 10 | Gold Supply Crate |
| Night Survivor | 25 | Emergency Shield |
| Hell Survivor | 40 | Inferno Ammo; Hell Survivor title |
| Reaper Hunter | 30 | Turret Overdrive |
| Reaper Slayer | 50 | Last Stand Feather |
| Perfect Team | 25 | Team Rescue Signal |
| Iron Fortress | 25 | Iron Barricade |
| Economy Master | 25 | Golden Pillow |
| Master Builder | 25 | Construction Coupon |
| Item Collector | 20 | Emergency Battery |
| Legendary Survivor | 35 | Shadow Smoke |

These definitions do not grant Legendary stock. Claimed rewards enter existing XP
and inventory. Unlock and claim are separate persisted states; actual granting,
cap handling, failure rollback and retry behavior are covered by the tests below.

## Transaction and migration rules

Achievements store an unlocked/claimed state in an optional versioned rewards
section of the existing profile. Claims save XP, one guaranteed item and the
claim marker together. Failed writes restore the previous state. A full reward
item stack blocks the claim until space is available; XP is capped by the
existing maximum. No parallel inventory or paid reward system was added.

Only reliable old wins/mode wins/Reaper records and currently owned item types
prove retroactive unlocks. Old construction, income, door damage, teamwork and
Legendary-use counts are not invented. New counters use settled eligible matches
and actual gameplay metrics. Inventory collection remembers obtained types after
consumption. A repeated settlement or claim cannot grant again.

Stage bonuses come from first clears of stages 1–4. Saved offers record source,
target, match and choice; unresolved offers are queued rather than overwritten.
The selected bonus is consumed atomically when its intended stage begins.
Replays cannot generate repeated first-clear offers. The bonus is separate from
rank perks, item stock and building investment/refund accounting.

Match settlement now rolls back XP, campaign records, inventory, receipts,
achievements, counters and offers when saving fails. Reward RNG state is restored
for a stable retry. Result UI provides a retry instead of confirming unsaved
progress. Existing saves with absent optional reward fields retain their data.

## Independent QA and balance

C's progression suite passes 342 checks; combination suite passes 27. They cover
rank gates, Master slots, real Reaper impacts, old saves, unknown/corrupt fields,
retroactive evidence, claim replay/full stacks/failed saves, settlement RNG retry,
queued stage offers, intended-stage use, expiry and existing Legendary limits.

The primary matrix completes 120 matches: five maps, three modes, four ranks
(Bronze, Gold, Diamond, genuinely qualified Mythic), and perk-only/prepared arms.
The prepared fixture budget is four Emergency Shields, one Guardian Heart and
an Economic Preparation bonus; match currency otherwise comes from gameplay.
Seed 11's balanced policy wins all 20 prepared Hell matches versus 4/20 with
perks alone. This strong fixture must not be presented as proof of universal
balance. Forty additional seed-47 Hell scenarios use a reactive-economy policy:
prepared builds win 12/20 and lose 8/20, versus 4/20 baseline wins. All 160 matches
terminate with zero invariant failures. These are limited deterministic policies,
not human win rates. Higher ranks add options and measurable effects; this matrix
does not establish a monotonic win-rate increase for every build.

Initial fixture failures and corrections are preserved: a Mythic profile needed
the complete stage-record chain; queue comparisons needed semantic numeric fields
after JSON reload; older tests had to select stage rewards before starting the
next stage. Existing XP/combat assertions were retained. The actual settlement
save-failure defect was fixed through rollback and truthful retry UI.

## Presentation and platform limits

Seven original perk emblems and twelve achievement emblems are generated locally.
Six original lossless PCM cues cover perk unlock, achievement unlock/claim,
difficult-stage completion, bonus selection and Mythic perk unlock, extending
the existing system to 87 streams. Brief reveal/flourish effects respect Reduced
Effects; values, progress, requirements and actual saved claim status remain visible.

Native Windows import/run/input/FPS and subjective audiovisual quality/human
balance remain UNVERIFIED. Linux rendering, deterministic tests and engine audio
do not certify native Windows. No Android, new maps/bosses or Phase 6 work.

## Actual rendered and audio evidence

D passed 382 rendered checks and captured/inspected 22 PNGs in actual Godot 4.6.3
OpenGL/Mesa. Prepared isolated profiles exercise real mouse input for perk
removal/replacement, locked Mythic, separate consumable slots, achievement claim
and replay rejection, saved stage selection, reload and intended-stage use.
The economic bonus produces an actual 50 Gold room start (25 base +25 bonus).
Full-size, 960×540 and Reduced Effects views remain readable. The coordinator
also viewed Master loadout, three-stage choices and claimed-achievement frames.

All six new audio cues played through valid engine events. The recorded master
bus is stereo 44.1 kHz, 9.473742 seconds, peak 943/32767, RMS 91.20924 and zero
clipped samples. All 87 streams load, four music stems start and no assets are
missing. This is actual engine mixing with Dummy output, not a concatenation of
source sounds or human listening. Capture provenance is in the evidence README.

Confirmed presentation fixes include icon minimum-size overlap, long Mythic
text under a button, missing combined bonus/progress previews and readable
actual claim feedback. A final wording polish displays stage numbers/titles
instead of internal stage IDs. No long forced cinematic or gameplay interruption.

## Regression status and delivery

The full existing regular and extended suites completed successfully in batches;
initial failed fixture logs and passing reruns are preserved. The mechanics
checkpoint is `b3fdb35`; final implementation/push verification is recorded below. `main`, project/export configuration, maps and boss catalogs remain
unchanged. Stop after Phase 5B-3.


Regular regression evidence covers all 20 items (11,203 original-item checks,
7,988 advanced checks and 20,798 Legendary checks plus their combination/balance
suites), Mythic 204 +7, ranks 354, boss 6,703, 90 difficulty simulations,
15,348 map core +5,107 integration +922 UI checks, 144 map matches (79 wins /
65 losses), campaign profile 89 and flow 146, and audio 245 assertions. Building
purchase/refund, horror, keyboard/mouse, projectiles, furniture and scene suites
also pass. No baseline difficulty, map or boss values were changed.

Separate logs preserve the initial boss fixture error and the old UI-heading
expectation. The latter now checks the actual Permanent Perks heading; all mouse
and unlock assertions remain. Final editor import is clean. New suites are added
to `tools/check.sh` for future runs. Extended completion: 20,000 economy transactions /175,941 invariant checks,
six rate scenarios, 27 timestep cases, 144 room/strategy cases and 48 rank/perk
matches (22 wins /26 losses) pass. Separate-process profile cleanup/write/read
and main startup pass. All final processes exited successfully.


Home Windows checklist: load an old profile, verify XP/stacks/stages, inspect
locked and unlocked perks, remove/replace at Master, equip consumables separately,
claim an earned achievement once, reload, complete a first-clear spin/choice and
start its intended next stage. Verify actual starting values, battle-bonus
expiry, Legendary limits, purchases/cancel/sell and normal boss combat. Native
Windows results remain UNVERIFIED until executed there.

Delivery: recovery tag `pre-phase5b3-88a6821`; mechanics checkpoint `b3fdb35`.
Latest verified implementation/evidence commit: `73d9a7ac32ea54f337912f74b548e0feedee5925`.
GitHub push SUCCEEDED: remote `refs/heads/work` returned exactly this SHA,
matching local HEAD. Initial HTTP 503 push failures left the remote unchanged;
pushing the mechanics checkpoint first and using a buffered HTTP/1.1 upload
completed both fast-forward pushes successfully. No force push was used.

The subsequent documentation-only commit records this verification. Its final
HEAD and matching GitHub SHA are confirmed in the completion message.
