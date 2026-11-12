# Phase 5D-1 — premium horror UI and strategic gameplay

## Status and delivery

**IMPLEMENTED:** premium interactive UI, three Hunter archetypes, four exclusive
turret branches, room advantages/drawbacks and three optional saved contracts.
**TESTED:** baseline, independent mechanics/accounting/migration/contracts/UI,
actual before/after rendering, balance scenarios, all existing regular and
extended suites, final editor import and actual scene/startup checks.
**UNVERIFIED:** native Windows, physical controls/speakers, hardware FPS and
subjective visual quality, horror, sound and human gameplay balance.
**INCOMPLETE:** no known required Phase 5D-1 code feature remains. Native/human
verification and the balance/art limitations below are explicit. Git delivery
verification is recorded at the end after the actual push.

Started clean on `work` at `496b9b9df9efbe95f99f2efc0e7a5de3c6597815`, exactly
matching GitHub. Recovery tag `pre-phase5d1-496b9b9`; baseline checkpoint
`83f915c`; tested core checkpoint `d5c35a4`; reviewed UI/save fixes `45a3f3f`.
`main` is unchanged.

The previous checkpoint and Phase 5C-3 report were read. Existing themes,
controls/fonts/art, Hunter/door/navigation/Reaper rules, paid investments,
room/economy, profile migration and result/reward transactions were inspected.
The architecture was extended, not rebuilt. B owned all production; C independent
mechanic/UI/exploit QA; D actual baseline/after rendering; A one bounded gameplay
balance audit. Root owns regression orchestration, documentation and Git delivery.

## Premium presentation and local artwork

The existing cached Gothic metal/glass theme now gives buttons raised chamfers,
side rails and restrained cast shadows, distinct hover/pressed surfaces, pressed
text depth and visible keyboard-focus edging. A 0.12-second hover/focus tint
transition respects Reduced Effects. Important actions use recognizable original
emblems alongside text, rather than empty generic controls. Narrow controls use
compact icons/padding to retain their complete labels.

`tools/art/generate_premium_ui.py` authors **30 original SVG emblems**: actions,
Gold/Electricity/RM Cash, difficulty, archetypes, room defense and branches. Four
existing Common inventory icons are improved into physical repair tools, a coin
crate, battery and radar, preserving registered IDs. No external game imagery or
runtime download dependency was introduced.

The local **Grenze Gotisch SemiBold** heading font replaces ordinary headings for
the title, major menu/mode sections and Reaper announcement. It is a static 600
weight instance of the Google Fonts variable font, generated with fontTools.
`assets/fonts/GrenzeGotisch-OFL.txt` carries SIL OFL 1.1 and author attribution;
`GrenzeGotisch-SOURCE.txt` records provenance. All 95 printable ASCII characters
are present. Existing licensed Interface.ttf remains for body text, instructions,
prices, numerical values and dense descriptions. This is not reliance on a font
installed on the developer machine.

- Main menu retains the haunted facade/fog and adds Gothic identity and action
  icons. D required title/subtitle spacing and full How-to-Play text refinements.
- Preparation is reorganized into legible archetype information, consistent mode
  cards, optional contract selection and separate permanent-perk management.
  Normal has shield/steel-green, Long Night moon/violet, Hell fire/crimson-orange;
  each has a visible brief, selected text and an ordinary Start confirmation.
- Shop uses 90-pixel original Common illustrations, rarity/owned/effect/price,
  distinct banknote balance and actual affordability. Success briefly lights the
  item/card, displays the real deduction and stock update, and plays the existing
  cue. Animation is one-shot; reopening the store cannot replay a false purchase.
- Gold coin, cyan electricity and green/gold RM banknote are distinct. RM remains
  an earned in-game currency with no payment integration; prices are unchanged.
- Shared components also apply to stages, HUD, inventory/loadout, perks, ranks,
  achievements, results/spin, tutorial/opening, pause and settings. Existing
  transactions and controls remain functional. Major information remains text.
- HUD shows the actual archetype, living team count and compact contract state,
  while real Reaper warnings retain priority. Room-selection help identifies a
  genuinely vacant room and its benefit/drawback; no-vacancy has a safe fallback.

## Hunter archetypes and fair counterplay

One existing Hunter entity/controller is used. Archetype selection depends on the
legitimate completed-match ordinal plus stage and difficulty, without consuming
gameplay or reward RNG. It is shown in preparation, saved in the active match,
bound to the model/match ID and immutable during that match. Menu navigation,
abort/retry and reload do not cheaply reroll it. Deterministic model tests can
explicitly choose any archetype. Every real Game start enables strategy;
standalone legacy test fixtures remain neutral unless configured.

| Archetype | Normal-form modifiers | Real behavior and weakness |
| --- | --- | --- |
| Crusher | HP ×1.15, damage ×1.20, speed ×0.82 | Every heavy strike has a 0.65s telegraph; longer siege commitment and different door preference. Concentrated fire benefits from its slower approach. |
| Stalker | HP ×0.92, damage ×0.82, speed ×1.08 | Prefers isolated/weakly covered doors; 0.55s first-strike warning, subdued distant silhouette. Lower direct damage and readable commitment permit response. |
| Ravager | HP ×0.88, damage ×0.85, speed ×1.18 | Faster pressure/shorter commitment; three strikes followed by 0.8s extra recovery, with a 0.3s burst-opening warning. Lower durability rewards rapid fire/coverage. |

Actual-motion Phase 5C-3 facing and animation remain. Crusher armor, Stalker hood/
eye band and Ravager claw details/silhouette/tint distinguish them; real warning
rings/poses and existing danger audio announce attacks. They are not merely skins.
No illegal movement, fake Hunter copies or remote hits were added.

Reaper transformation remains once-only with its separate robe/scythe and all
three specials. Archetype factors blend 35% toward their normal modifiers and
clamp to 0.90–1.10 during Reaper form. Normal archetype attack patterns give way
to the existing boss state machine. Maximum HP is adjusted without transformation
healing; ordinary existing growth remains. Slow effects use the strongest current
movement reduction instead of multiplying into immobilization.

## Turret specializations, Level 10 and accounting

At owned Needle/Arc Level 4, choose **one** branch to purchase Level 5. Generic
upgrade pauses for this explicit decision. The selection is permanent for that
building; later upgrades continue normally to Level 10. Bots retain their existing
four-level budgets. Existing unconfigured buildings/fixtures remain compatible.

| Branch | Actual changes relative to its current base tier |
| --- | --- |
| Needle — Heavy Precision | +55% hit damage, 40% longer interval, **15% shorter range: 204px**. Strong concentrated hits require placement. |
| Needle — Suppression | 20% weaker hits, 18% shorter interval, 240px range; actual impacts apply 15% movement slow for 1s, 7.5% on Reaper. Refreshes, never stacks into stronger control. |
| Arc — Focused Discharge | 50% stronger hits, 35% longer interval, 300px range. |
| Arc — Storm Coil | 28% weaker hits, 28% shorter interval, 360px range, 25% faster projectiles. A truthful coverage/rapid-fire role for one Hunter, not imaginary chain targets. |

The Level 5 transaction adds **25 Gold / 4 Electricity** to the existing upgrade
price. Undiscounted Level 5 totals: Needle 125G/19E; Arc 500G/79E. Construction
Coupon applies to the complete eligible transaction exactly once, only after
validation and successful persistent consumption. Actual separately paid Gold/
Electricity ledgers include the branch fee. Sales refund **50% of actual eligible
investment**, including discounts/upgrades, once, and free the pad.

Undiscounted complete Level 10 investment: Needle **1765G/262E**, Arc
**8290G/1306E**. No nominal-price refund inference, free branch, duplicate choice,
Level 11, negative-resource or sale/rebuy gain is permitted. Turret Overdrive
composes with actual branch interval; Frost and suppression use strongest-only
movement slowing with bounded Reaper reduction. Real projectile damage, speed,
range and effects are tested. Hunter threat estimates also use actual branch
coverage/damage/rate, avoiding misleading defensive evaluation.

Branches have distinct emblems, weapon overlays/projectile treatment and inspector
stats/costs. Successful choice returns to the upgrade inspector showing the
selected branch and Level 6 cost; rejected transactions retain the selection.
Buildings remain transient because this project has no mid-match save system.

## Room strategy

All six rooms and all buildable pads remain on each of the five maps. A stable
map/room assignment gives two rooms of each trait. Decorative plaques and the
selection guide explain actual benefits and drawbacks; bot residents use the
same legitimate multipliers. No layout, collision, slot or path was removed.

| Trait | Benefit | Drawback |
| --- | --- | --- |
| Fortified | +15% maximum/initial door HP | −10% occupied bed income |
| Power Conduit | +20% Dynamo electricity | −10% door durability |
| Prosperous | +15% occupied bed income | −10% Dynamo electricity |

Traits apply once and compose with existing perks/stage bonuses, upgrade HP and
item calculations. Unoccupied/dead rooms do not gain fictitious bed income.
The tutorial remains isolated and keeps its nine steps; advanced help is short
and appears in preparation or at the relevant purchase/room choice.

## Optional challenge contracts and saved rewards

| Contract | Genuine condition | Extra RM Cash |
| --- | --- | --- |
| No Legendary Help | Win without any manual **or automatic** Legendary trigger | 8 |
| Limited Defense | Win without ever simultaneously owning more than two offensive turrets; selling the third later cannot erase failure | 10 |
| Iron Survivor | Win without manual door repair. Stations, upgrades, items and perks remain allowed | 8 |

Opt-out is explicit. Restrictions are observed through actual successful actions/
item consumption and irreversible match-local counters. Genuine terminal facts
are sealed and bound to the same model, match ID, stage, difficulty, archetype
and contract; forged/unsealed/tampered results cannot qualify. Normal eligibility,
occupied time, real victory and living player are required. Abort/restart/defeat
cannot pay a contract bonus.

A contract pays once per **stage + difficulty + contract**, at most 45 keys /
390 total bonus RM. Existing base RM/XP/Lucky Spin/achievement rewards continue.
The claim and payment share the existing result-save transaction and full rollback,
including active match, cash, inventory, stage/rank/achievements and reward RNG.
Failed save may be retried once successfully without duplicated grants. A full
wallet does not record an unpaid claim; another qualifying win after spending can
claim it. Results distinguish paid, already claimed, failed and wallet-full states.

An optional version-1 strategy save block preserves selected contract and claims.
Old saves without it retain progression, all 20 items, perks/achievements, cash,
shop tokens, spins, settings and tutorial state. Unknown/malformed strategy data
loads known records read-only and preserves original bytes. Partially malformed
active snapshots now use safe getters/type checks instead of interrupting loading.
No unsupported mid-match load guarantee is claimed.

## Independent tests and regressions

| Evidence | Result |
| --- | --- |
| Baseline actual renderer | 45 PNGs, 73 checks, zero failures |
| Baseline gameplay/economy/profile/item/reward/property/scene/startup | All commands exit 0; logs retained |
| C complete mechanics/navigation | 172,324 checks, 270 real approaches = 5 maps ×3 modes ×3 Hunters ×6 rooms; zero failures |
| C final Precision/Storm/weapon/estimate focused rerun | 983 checks, zero failures; unchanged navigation not repeated |
| C separate actual branch/coupon/refund economy | 556 checks /16 scenarios, zero failures |
| C saved contracts, genuine terminal, duplication and rollback | **425 checks, zero failures**, including automatic Guardian and failed Legendary save |
| C migration | **159 checks, zero failures**, including malformed partial active snapshots |
| C actual UI 720p/1080p | **3,190 checks, zero failures**, including actual glyph/price/refund fit and tutorial cleanup |
| A live diagnostic simulations | 150 cases, zero integrity/settlement failures; 140 victories/10 defeats |
| A controlled paid L10 tradeoff regression | 8 fixtures, zero failures |
| D final actual rendering | **85 paired +264 strategy +21 map/frame checks**, zero failures; **113 AFTER PNGs** |
| Final editor import / legacy visual UI | Exit **0**, clean engine; **1,267** legacy UI checks, zero failures |
| Actual scene / startup | **24** scene checks; startup **PASS** in intro |
| Existing full regular + extended suites | All suites pass through initial run + corrected difficulty check + resumed run; resume exit **0**, no failures |

Counts contain repeated movement-step invariants, not that many distinct matches.
Fixtures with injected resources/HP are labelled as controlled tests, not earned
balance evidence. Earlier failed/parse/fixture runs are preserved. C corrected
new fixture precision/type/range/growth/timestep assumptions without production
rounding or hiding genuine differences. D inspects raster output in addition to
control rectangles; counters alone do not establish art quality.

The initial full command passed through `boss_matrix`, then exited1 at a stale
legacy test searching Button.text for Hell. The mode card now has semantic mode
metadata and visible labels. `difficulty_behavior.gd` was updated to click that
actual card, additionally check its visible name, and passes269checks. The remaining
regular and all extended suites then ran sequentially with explicit exit/error
recording; `regression-resume-results.json` has no failures. Completed unchanged
suites were not needlessly repeated.

Two other legacy UI fixtures were adapted before their resumed runs: campaign
and rank UI follow the dedicated perk screen, include archetype/trait composition
in stat expectations, and let the real model tick establish/seal terminal results.
No assertion was disabled, no real Game strategy was bypassed, and reward
eligibility was not weakened. Campaign flow148 and rank UI76 checks pass.
`regression-full.log`, `regression-difficulty-behavior-{initial,final}.log`,
`regression-resume.log` and per-suite logs preserve the complete history. The final
legacy visual UI rerun covers late layout-only fixes.

The extended suites pass27timestep matches (none unresolved),144strategy audit
matches and48phase2matches (22victories/26defeats), plus A's separate eight-fixture
`--check`. Regular coverage includes all20items/combos, haunted worlds/Level10,
105audio streams/281assertions,512+421purchase/cancel/refund checks, safe RMshop/
spins/perks/ranks/achievements,5maps/navigation/campaign,20,000property transactions
with175,889invariants, cross-process profile write/read and actual startup. All
five new C suites are registered in `tools/check.sh`; A's bounded `--check` is
registered under `--extended`, preserving live audit evidence.

Confirmed production defects found and corrected during independent review:
malformed active-save missing-contract access; branch success leaving the wrong
inspector; replaying purchase glow; title/subtitle overlap; clipped narrow action;
misleading nearest occupied-room hint; lost living-team HUD count; stale combat
warning when replaying the safe tutorial. Original
same-range Precision also showed a dominance signal and was tuned as below.
Final acceptance logs, exact remaining issues and source/push ID follow below.

## Balance evidence and limits

[Independent balance report](evidence/premium-strategy/balance-summary.md)
discloses policy, budgets, maps, exact outcomes and source provenance. The 108
core cases cover 3 archetypes ×3 difficulties ×3 requested traits ×4 branches,
with all five maps and matched stage/map/seed/budget within branch comparisons.
Prepared Master/rare item budgets are explicitly seeded; positions, HP, time and
currency are not injected in live matches. Players actually walk, claim, sleep,
earn and buy. Additional arms cover reservation, Mythic control, contracts and
Arc branch-first investment.

The first same-range Needle sample favored Precision (19 faster/0 Suppression/
7 ties among 26 pairs reaching Level 5). After its 204px range tradeoff, the fresh
78 affected live cases give **13 Precision faster /5 Suppression faster /8 ties**.
A real Ravager/Hell/Dorm/Power-room-4 seed-11 pair changes from Precision defeat
at 167.3s to Suppression victory at 156.3s, under the same disclosed budget.
This demonstrates a meaningful coverage choice, not universal balance or parity.

Normal/Long Night core each have 36 victories; Hell has 29 victories/7 defeats.
These automated results are not human win rates. Room/encounter comparisons
across different geometry remain confounded; no universal best room is claimed.

Arc branch-first play reaches Level 5 in all 12 additional probes at123.4–152.6s;
actual Long Night/Stalker/Lab specialized impacts occur for both branches.
Four reservation probes reach Needle 10; some wins depend wholly on teammates.
**Natural Arc 10 was not reached by these bounded Phase 5D-1 policies.** Paid
controlled combat proves both Arc branches work at10, not natural reachability.
Finite Mythic Frost/Freeze arms leave Reaper attacking (2–14 strikes in six
transformed encounters); three Hell control arms lose before transformation.

Controlled 20s Level 10 tests separately show close Precision damage4603.5 versus
Suppression4032 at180px; at220px Precision0 versus Suppression3960. Arc Focus9660
versus Storm8870.4 at210px; at330px Focus0 versus Storm8668.8. These injected
stationary-target probes establish damage/coverage mechanics, not AI balance.

Contracts may be inexpensive restrictions for an already compatible one-weapon
policy; they are limited optional milestones, not guaranteed harder for everyone.
No human reaction-time, fun or exhaustive item/perk balance claim is made.

## Rendered comparison, performance and remaining work

[Actual visual evidence and provenance](evidence/premium-strategy/README.md),
[PNG manifest](evidence/premium-strategy/render-manifest.json).
Prepared isolated production profiles expose screens; these are unedited actual
Godot viewport images, not mockups or natural human matches.

| View | BEFORE | AFTER |
| --- | --- | --- |
| Main menu720 | [Before](evidence/premium-strategy/before/01-menu-720.png) | [After](evidence/premium-strategy/after/01-menu-720.png) |
| Hell mode720 | [Before](evidence/premium-strategy/before/06-mode-hell-720.png) | [After](evidence/premium-strategy/after/06-mode-hell-720.png) |
| Common shop720 | [Before](evidence/premium-strategy/before/07-shop-720.png) | [After](evidence/premium-strategy/after/07-shop-720.png) |
| Gameplay720 | [Before](evidence/premium-strategy/before/11-hud-siege-720.png) | [After](evidence/premium-strategy/after/11-hud-siege-720.png) |

D individually inspected **45 BEFORE /113 AFTER** PNGs (45paired +68new),
including pointer hover/held press/focus, all five maps, room choices, all four
paid/coupon branches and Level10, failed/qualified/already-claimed contracts,
Reaper states and safe tutorial replay. Baseline PNG hashes are unchanged. The
coordinator also inspected the actual before/after menu, shop, Hell, discounted
Needle choices and contract cards. Glyph ink leaves8px between title/subtitle;
How-to-Play and ordinary/discounted L10 refund labels fit without hiding either
resource or50%. Actual mouse and Enter interactions accompany these renders.

Additional strategy examples: [room choice](evidence/premium-strategy/after/extra-room-1-720.png),
[discounted Needle branches](evidence/premium-strategy/after/extra-specialization-turret-720.png),
[contracts](evidence/premium-strategy/after/extra-contracts-720.png),
[Storm10](evidence/premium-strategy/after/extra-level10-storm-1080.png),
[failed contract result](evidence/premium-strategy/after/extra-contract-failed-result-720.png).

No fresh pre-phase timing was captured. Warm2.5s Linux llvmpipe samples measure
mean/p95 **32.678/39.972ms720p**, **46.430/52.225ms1080p**,
**31.003/37.000msReduced720p**; material cache stays18→18. These are bounded
post-change observations, not a matched performance comparison or hardware FPS
claim. New emblems/materials are cached; existing bounded effects/culling remain.

The actual **43.096s stereo44100Hz** Master-bus recording has peak0.0230103,
RMS0.00386990 and **zero full-scale samples**. All105existing streams load with
none missing. Real purchase/refund/projectile/coupon/archetype/Reaper/victory
events played. Thirty-three low-priority events were intentionally suppressed
in prepared upgrade bursts; no critical events were pending. No WAV was added
or replaced. Engine output is not subjective physical listening.

No known functional or blocking presentation defect remains in tested paths.
Native Windows import/execution, physical mouse/keyboard/display, speakers,
hardware/long-session FPS and subjective premium-art/horror/audio quality remain
**UNVERIFIED**.

Existing simplified survivor sprites/exterior scenery remain; icons, typography
and dimensional 2D surfaces are not a full hand-painted or 3D character overhaul.
No Phase 5D-2/6, Endless Siege, new Hunter entities/maps, specialization beyond
the four listed branches, payment, cosmetic economy, Android, multiplayer or
new practice mode was added.

## Final delivery verification

Pending final acceptance, commit and actual private GitHub `work` push.
No push success is inferred from local checkpoints.
