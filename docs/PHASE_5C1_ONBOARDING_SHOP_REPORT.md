# Phase 5C-1 — opening cinematic, first-time tutorial and RM shop

IMPLEMENTED: animated opening/title, mandatory real practice, menu audio mix,
RM Cash and Common shop. TESTED: independent profile/flow/economy checks, full
regular and extended regressions, actual rendering and engine audio. UNVERIFIED:
native Windows, subjective quality and typical human tutorial pacing. INCOMPLETE:
no requested implementation deferred; no known functional failure remains.

Baseline clean `work` at
`d8ac232cf40f785e9454222a1d204d2dfb6e5ab3`, remote verified.
Recovery tag `pre-phase5c1-d8ac232`. B owns production; C independently tests;
A provided a bounded audit; D inspected real cinematic/tutorial/audio output. Native Windows and subjective quality remain UNVERIFIED.
No Phase 5C-2 or Phase 6 scope.

## RM economy and Common shop definitions

RM Cash is a separate persistent, in-game currency. The existing match settlement
adds its award alongside XP, achievements and saved Lucky Spin receipts; it has
no separate repeatable claim screen. The original spin roll occurs before the
RM sample. Failed writes roll back balance and RNG for a stable retry.

Current configurable rewards: eligible victory 24–32 random RM, plus up to 12
performance RM (damage/500 and occupied minutes), plus 10 for Long Night or 20
for Hell. Qualifying defeat: 3–5 random RM, plus up to 3 for occupied time, only
with at least 90 occupied seconds and 100 Hunter damage dealt or door damage
taken. Instant/abandoned losses and tutorials award zero. Balance cap: 100,000,000.
The economy scenarios below assess these gates; they cannot infer human intent.

| Common item | RM price |
| --- | ---: |
| Instant Repair Kit | 18 |
| Gold Supply Crate | 16 |
| Emergency Battery | 16 |
| Hunter Radar | 12 |

The shop uses existing definitions/icons/effects and inventory, with persistent
purchase intent serials. Successful purchases save stock and RM together;
insufficient balance, full stacks, invalid rarity, duplicate intent or save
failure grant nothing. UI confirmation and double-click behavior pass the
actual input tests below. No real-money system or paid spin was introduced.

## Opening and practice implementation

A 15-second animated opening covers a fleeing character with moving limbs/sprite
frames, scrolling forest silhouettes/fog, the pursuing Hunter with a brief reveal,
arrival at an abandoned dorm, the character entering and closing the door, an
aligned Hunter impact and fade to darkness/shriek. A four-second connected title
card displays the exact text “Welcome to NightFall Dorm” and “Created by Fahim”,
with four short story lines revealed in sequence. Total default opening: 19 seconds.
This is a cinematic backdrop, not a new playable map or outdoor gameplay system.

Space, Enter, Escape or left click immediately skip the remaining opening.
Skip removes only opening controls/audio and transitions through the same tutorial
or menu gate. Returning to the menu does not restart it. Saved Reduced Effects
removes the lightning flash and reduces fog; saved audio preferences remain active.

Fresh profiles enter nine real practice objectives: movement, claim a room, sleep,
observe earned Gold, buy a Dynamo and observe Electricity, buy an in-range turret,
upgrade it and repair the door, observe weak combat, then save completion. The
practice model is isolated: no match entry/settlement, stock consumption, XP,
achievements, RM or spin rewards. A focused objective/progress panel, highlights,
recovery action and generous practice resources support the steps. The Hunter is
held until the combat lesson and uses reduced damage/speed with capped growth.
Recovery handles wrong pads/full grids and a sold or out-of-range defense.

Completion must save before entering normal flow; failure offers a retry.
Replay Tutorial uses the same practice without resetting profile progress. Closing
mid-tutorial restarts practice safely next launch. Old saves without the new field
bypass practice only when XP, recorded matches, stage records or positive inventory
prove previous progress. An empty save file/settings alone do not prove experience.

## Audio integration

Nine new original generated PCM cues extend 87 streams to 96. Existing audio
management and bounded voices are reused. A new original 12-second menu piece
loops seamlessly. Gameplay music gain is 0.55 versus menu 0.85, with smooth ducking
toward 0.48 while critical cues play. Existing saved buses/settings remain.
The focused original audio suite passes 263 assertions, all 96 streams decode,
and four music stems start once. Actual mixer recording and subjective limits
are recorded below.

## Independent verification and rendered evidence

C's focused profile/currency/shop suite passes 164 checks. Economy coverage runs
42 deterministic scenarios with 57,016 checks, sampling 1,000 seeded draws per
case. It verifies valid win/loss ranges, contribution/time gates, caps, settlement
retry/RNG stability and tutorial exclusion. These synthetic comparisons are not
human earning rates or universal intent/farming detection. Shop tests cover all
four prices, token reuse across items/reload, full stock, insufficient balance,
invalid rarity, read-only data and save-failure rollback.

D passes 77 rendered checks and inspected 26 actual Godot/Mesa PNGs: chase frames,
Hunter reveal, entry/impact/darkness, exact welcome/credit/story, normal/small
layouts, all nine tutorial objectives, completion/menu/replay, and shop purchase,
insufficient funds, save failure and double-click behavior. The walkthrough uses
real WASD/E/R and mouse input in an isolated profile. The coordinator additionally
viewed the door-impact, welcome story and focused bed-instruction frames.

The actual recorded master bus is stereo 44.1 kHz, 34.737052 seconds, peak
608/32767, RMS 87.01369 and zero clipped samples. All nine new cues played;
96 streams load with no missing assets and four music stems start. This records
the real engine mixer with Dummy output, not a source-asset concatenation.
No human listening or speaker-quality claim is made.

Confirmed fixes: turret-range/full-grid/sold-defense recovery; tutorial camera,
practice HUD and context highlights; closing the inspector at completion; and
coherent Hunter arrival/door-impact timing. Failed fixture logs are retained:
JSON numeric deep comparisons, an initial nonwalkable capture goal, and a
headless timer that advanced ahead of the shop's wall-clock cooldown. Assertions
were corrected to exercise semantic values, reachable input paths and the actual
cooldown, preserving transaction and normal-click checks.

## Limitations and scope

UNVERIFIED: native Windows import/run/controls/FPS/speakers; subjective fear,
art/audio quality and typical human 2–3 minute tutorial pacing. The software
walkthrough is input automation, not a human onboarding study. No Phase 5C-2,
Phase 6, playable outdoor map, decorative creature, weather system, new boss,
level-10 upgrade, multiplayer or Android feature was added.

Windows home checklist: launch with an old save and confirm opening→menu; use a
fresh profile to complete all nine practice lessons; close midway and relaunch;
retry completion after a failed save; replay without reward changes; win/qualify
for a defeat and inspect RM with XP/spin/stage rewards; buy each Common, double
click, reopen and verify stock/RM; check saved mix and Reduced Effects.


## Final regression and delivery evidence

C's interactive flow passes 92 checks, including an enabled shop button receiving
an OS-marked double-click after 550 ms and a subsequent successful ordinary click.
At 180 occupied seconds/1,000 damage in the disclosed fixture, Normal victories
average 33.041 RM, Hell victories 53.041 and defeats 4.996. These are fixed-input
reward samples, not human rates or 57,016 distinct scenarios.

The existing `tools/check.sh --extended` suites all passed in one full run, with
new onboarding suites independently executed above. New suites are now included
for future runs. Evidence: `regression-all.log`, `qa-summary.md` and final logs.
No assertions were disabled; legacy scene fixtures explicitly seed graduated
profiles and skip through the actual opening API. No production bypass exists.

Coverage includes all 20 items (11,203 original,7,988 advanced,20,798 Legendary
checks plus combinations/matrices), progression342+27, Mythic204+7/rank354,
boss6,703 and60comparisons;90difficulty simulations unchanged;15,348map-core/
5,107integration/922UI and144mapmatches79W65L;campaign89profile/146flow and20matches;
building314+421;audio263/96streams;20ktransactions/175,941invariants;sixratecases;
27timesteps/144strategycases/48rankmatches22W26L;separate-process profile write/read/
cleanup and actual main startup with `MODE=intro`. Final editor import is clean.

The only new gameplay-rule branches are practice isolation and weak practice
Hunter tuning; existing difficulty, maps, stage and boss catalogs, project and
Windows export configuration remain unchanged. Native Windows is unverified.
Recovery tag `pre-phase5c1-d8ac232`; tested implementation milestone `238e2ec`.
Latest verified implementation/evidence commit: `c636b225cb8127dbd4caf7a5cf22439d8f03929d`.
GitHub push SUCCEEDED: `d8ac232..c636b22 work -> work`; `git ls-remote origin
refs/heads/work` returned exactly that full SHA, matching local HEAD.
The subsequent documentation-only commit records this verification; its final
HEAD and matching remote SHA are confirmed in the completion response.
`main` is unchanged. Stop after 5C-1.
