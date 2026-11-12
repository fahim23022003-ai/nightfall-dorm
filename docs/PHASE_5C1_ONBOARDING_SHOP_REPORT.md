# Phase 5C-1 — opening cinematic, first-time tutorial and RM shop

IN PROGRESS. Baseline clean `work` at
`d8ac232cf40f785e9454222a1d204d2dfb6e5ab3`, remote verified.
Recovery tag `pre-phase5c1-d8ac232`. B owns production; C independently tests;
A provides a bounded audit; D will inspect real cinematic/tutorial/audio output.
Final rules, test evidence, limitations and delivery verification follow after
implementation. Native Windows and subjective quality remain UNVERIFIED.
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
Final economy scenarios below assess these gates; they cannot infer human intent.

| Common item | RM price |
| --- | ---: |
| Instant Repair Kit | 18 |
| Gold Supply Crate | 16 |
| Emergency Battery | 16 |
| Hunter Radar | 12 |

The shop uses existing definitions/icons/effects and inventory, with persistent
purchase intent serials. Successful purchases save stock and RM together;
insufficient balance, full stacks, invalid rarity, duplicate intent or save
failure grant nothing. UI confirmation and double-click behavior require the
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
are recorded below after final rendered verification.
