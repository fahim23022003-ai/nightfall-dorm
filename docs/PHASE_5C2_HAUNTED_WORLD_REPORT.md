# Phase 5C-2 — haunted world, elimination horror and Level 10 defenses

IMPLEMENTED: five haunted environments, bounded noncombat creatures/weather,
genuine survivor/breach horror feedback, eligible Level 10 defenses and original
art/audio. TESTED: independent QA/economy/live simulations, full regular/extended
regressions, actual Linux rendering and engine audio. UNVERIFIED: native Windows,
subjective quality and human balance/performance. INCOMPLETE: no requested
implementation deferred; no known functional test failure remains.

Baseline clean `work` at
`48ecdae4bc77114108e6f5f2c123bf158c50d6ba`, remote verified.
Recovery tag `pre-phase5c2-48ecdae`. B production, C independent QA, A bounded
review and D actual rendering/audio. Native Windows and
subjective horror/audio quality remain UNVERIFIED. Stop after Phase5C-2.

## Defense progression design

Only Needle and Arc turrets extend to Level 10. Utility/economy/support buildings
and existing autonomous spending remain capped at four. Original Levels 1–4 keep
their costs and combat formulas. New catalog helpers centralize kind-specific
caps, prices, prerequisites, damage and interval calculations used by combat and
Hunter threat estimates. Actual successful Gold/Electricity payments continue
feeding the existing ledger; coupons discount those payments and sales return
50% of the actual eligible investment in each resource separately.

Verified prestige upgrade cost factors are 5, 7, 10, 14, 19 and 25 for the
transitions from Levels 4–9. They multiply base Gold and `(base Electricity +3)`.
Target Levels 5–7 require bed/door internal level2 (displayed Level3); Levels 8–10
require internal level3 (displayed Level4). These were evaluated through
normal earned-resource scenarios as well as funded transaction fixtures.
Verified costs, reachability and bounded combat power follow below.

## Haunted world and map identities

A shared read-only environment owns separate cosmetic randomness and bounded
presentation state: five reusable ambient actors and at most seventy scenery
entries. It never adds combat targets, colliders, damage, navigation edges or
model RNG calls. Complete actor footprints stay outside the protected room and
corridor geometry. Initial anchors are selected to make exterior actors visible
in the ordinary map camera. Lifetimes/hidden intervals control frequency.

| Existing map | Exterior treatment |
| --- | --- |
| Abandoned Student Dorm | Dead branching trees, wandering silhouettes, eyes, birds and thin drifting fog |
| Haunted Hospital | Cold medical structures, red-cross details, flickering exterior lights and distant figures |
| Forgotten Hotel | Abandoned street facades, broken windows, watchers and mist |
| Underground Laboratory | Sealed/glazed observation structures, sparks and industrial silhouettes |
| Cursed Mansion | Gravestones, twisted trees, bats, heavier fog and more frequent storms |

Five recognizable behaviors: wandering shadow walker, fading watching eyes,
low crawling shadow, framed window watcher and a fog apparition whose actual
opacity is zero until lightning reveals it. Moving clouds, rain, fog and birds
are drawn under gameplay geometry. First lightning occurs after 12–17 seconds;
subsequent map-controlled intervals span 24–54 seconds, with a 0.6-second flash
and thunder delayed 0.6–1.8 seconds. Reduced Effects removes the flash overlay
and lowers weather ornament while preserving readable status and the subtle
reveal. Practice/intro presentation stays isolated.

## Genuine elimination and audio behavior

Real Hunter routing remains: destroy a door, enter through its opening, reach
within 12 pixels of the bed, then eliminate through existing gameplay logic.
Read-only fear and attack events add panic and a brief strike pose/sweep without
changing attack timing, navigation or target selection. The eliminated room
stops bed/electricity/repair production, bot purchases and new turret fire through
existing alive/sleeping guards; references and ownership are retained.

A 1.4-second collapse ends in a fallen representation and persistent darkened,
abandoned room. The existing horror notification system shows `SURVIVOR
ELIMINATED`, actual survivor name, room and remaining claimed survivor count.
Player breach has higher priority. Team status updates without a fullscreen
interruption or forced new target. Fake intact-door/living-survivor callbacks
cannot cause breach/death presentation.

Two original death cues serialize in a bounded per-room queue. A genuine room
elimination triggers once despite repeated/new-ID callbacks. Normal Hunter and
Reaper use different original laughs once after actual door destruction; laughs
wait behind death screams and remain lower priority than critical warnings.
Distant reactions retain controlled prominence. Weather uses the existing
Ambient bus at -29 dB voice gain versus ordinary Effects at -20 dB; death cues
use -17 dB. Saved Music/SFX/Ambience preferences remain. Menu/practice transitions
clear owned sound queues. Nine new lossless PCM cues bring the total to 105.

## Level 10 verified tuning and accounting

| Weapon | Full purchase + Levels 2–10 | Base Level 10 shot /interval | Nominal DPS |
| --- | --- | --- | ---: |
| Needle | 1,740 Gold /258 Electricity | 90 /0.4327s | 208 |
| Arc | 8,265 Gold /1,302 Electricity | 280 /0.625s | 448 |

These nominal figures exclude rank, relay, stage, item and boss modifiers.
Level is capped at ten in calculations; Level 11 upgrades fail without payment.
Twelve original SVG armor tiers layer over existing sprites with fins/crowns,
compact max badges, enhanced projectile accents and a special maximum-upgrade
cue. Reduced Effects reduces ornament. UI uses readable decimal amounts while
resource ledgers retain exact paid values. Unmodified full-investment refunds
are 870G/129E for Needle and 4,132.5G/651E for Arc; coupons lower refunds according
to actual payments. Duplicate sale fails and the pad becomes reusable.
Buildings remain transient match state, so no saved-building migration is needed.

## Independent QA and earned reachability

Focused QA passes 78,195 checks. Most are repeated exterior/bounded-state checks
across 1,400 updates on each map; they are not 78,195 separate gameplay scenarios.
Accounting covers both currencies, each cap/prerequisite, real impacts at levels
1/4/7/10, coupon/refund/double-sale behavior, all-map/mode real elimination,
nonacting dead bots, duplicate/false events and real serialized mixer playback.
Rank/stage/transformed-Reaper/Overdrive/Time Freeze interactions remain finite.
The suite was rerun successfully after final presentation changes.

Four controlled earned-income workshops pass 5,382 checks, without an active
Hunter: Needle reaches10 in215.5s (209.5s with income/power perks), Arc in466.5s
(453s). These prove accounting/economic possibility, not survival.

The live matrix completes60 matches, zero invariant failures: five maps ×three
modes ×two weapon policies ×cap4/cap10 arms. Paired Master profiles use Deep
Sleeper +Last Light, four Shields and one Heart. Gold/Electricity are earned;
AI/HP/door health/time are not artificially paused or inflated. The policy builds
economy/repair, reserves the full weapon cost, then attempts valid upgrades at
0.1-second automated cadence. This is disclosed automation, not human input speed.

- Needle10: Haunted Hospital/Normal at191.1s, victory191.5s,5,453.7Gold generated.
- Arc10: Underground Laboratory/Normal at218.7s, Reaper victory229.3s,
  14,263.9Gold generated.
- Cap4→cap10 outcomes: Normal10W0L→10/0; Long Night10/0→10/0; Hell3/7→2/8.
  Saving for prestige worsened one Hell case. No Level10 was reached in tested
  Long Night/Hell cases; their direct high-level interactions are covered by
  focused fixtures. These results do not prove universal reachability, improved
  win rates or human balance. Baseline Hunter stats were not inflated.


## Actual rendered/audio evidence and fixes

D passes 151 rendered checks with zero final engine errors and individually
inspected 31 actual Godot/Mesa PNGs. These prepared isolated fixtures use real
combat routing, UI purchases, coupon payments and sale accounting; they are not
natural human matches. All five worlds, initial visible actors, five creature
closeups, lightning reveal/delayed thunder, small/reduced views, panic/strike/
collapse/abandoned room, actual warnings/counts, both prestige weapons and paid
refund/free-pad behavior are covered. The coordinator additionally inspected
the dorm world, survivor collapse notification and Needle max/refund frames.

The actual master-bus recording is stereo44.1kHz,18.668844seconds, peak723/32767,
RMS147.08291 and zero clipped samples. All nine new cues played,105streams load,
four music stems start and no assets are missing. Ambient mute is independent
of combat SFX. Ordinary competing effects may still be throttled by the existing
bounded budget; critical death/notice cues retain priority. Dummy output recorded
the real engine mixer; no human audition/speaker-quality claim is made.

Confirmed issues fixed and rerendered: Reduced Effects state being overwritten,
a mutable-control draw callback, initial creatures off-camera, missing genuine
strike feedback, clipped elimination count, long refund floats, max badge/HP
and stacked upgrade-pulse overlap, and coupon savings labeled as damage blocked.
A feedback edit briefly inserted an out-of-scope line and caused a compile error;
it was removed, fresh startup passed, and map integration plus all later suites
were rerun successfully. Initial failed evidence is retained. Audio-wall-clock
and synthetic living/intact-state fixture corrections preserve real event guards;
no gameplay assertions were disabled.

## Existing regressions and compatibility

Full regular and extended suites completed in batches. `regression-all.log`
contains successful early suites and the caught map-integration compile failure;
`regression-remaining.log` is the clean passing rerun from map integration onward.
Final `haunted_qa.gd` was rerun after visual fixes. Final import is clean in
`import-final.log`. Future `tools/check.sh` includes the three haunted suites.

Existing coverage passes: all20items (11,203original/7,988advanced/20,798Legendary
checks plus combination/matrices), onboarding164+92/economy57,016, rewards342+27,
Mythic204+7/rank354, boss6,703 and60comparisons;90difficulty simulations unchanged;
15,348map-core/5,107integration/922UI and144matches79W65L;campaign89profile/146flow;
building512+421;horror319+22+5;audio281/105streams;20ktransactions/175,889invariants;
sixrates;27timesteps/144strategycases/48rankmatches22W26L;profile write/read/cleanup
and actual startup intro. The property count changes because the new valid
weapon caps permit52more seeded transactions. Original gameplay assertions remain.

Existing profile data,20items, Legendary limit, achievements/perks, XP, stage
choices, Lucky Spins, RMshop and opening/tutorial retain their formats and tests.
Map layouts, stage assignments, boss catalog and Windows project/export settings
are unchanged. Utilities and autonomous spending remain4; doors/beds retain their
existing caps. No new gameplay enemy or automatic Hunter stat inflation.

## Limitations, home check and delivery

UNVERIFIED: native Windows import/run/input/hardware FPS/speakers, subjective
fear/art/audio quality, human balance and all possible camera compositions.
Software captures and deterministic simulations cannot establish these claims.
Live reachability proves one earned success for each weapon, not Level10 access
in every mode or a measured benefit in fully equipped Hell matches.

Home Windows checklist: import the `work` ZIP in Godot4.6.3, retain old saves,
verify opening/tutorial/RMshop, inspect allfive maps/focus/map views, toggle
Reduced Effects/Ambience, observe a genuine teammate breach/death and continued
Hunter targeting, then test prestige prerequisites/coupon/upgrade10/rejected11/
half actual-paid sale/free pad. Check door HP, warnings and numbers during storms.

Recovery tag `pre-phase5c2-48ecdae`; mechanics checkpoint `327b27a`.
Latest verified implementation/evidence commit: `5f09ef6933ab302e172c21304bb92e0a4862e042`.
GitHub push SUCCEEDED: `48ecdae..5f09ef6 work -> work`; `git ls-remote origin
refs/heads/work` returned exactly that full SHA, matching local HEAD. The following
documentation-only commit records this result; its final HEAD and matching remote
SHA are confirmed in the completion response. `main` unchanged. No Phase6, Android, multiplayer,
unrelated maps or bosses. Stop after Phase5C-2.
