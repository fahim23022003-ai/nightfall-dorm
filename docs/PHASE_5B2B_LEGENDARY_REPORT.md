# Phase 5B-2B — Legendary items and cinematic effects

Starting point: clean `work` at `b4d1798d82a458636eebb1b62419f7e0bbd66b7d`,
confirmed against the private GitHub remote. Recovery tag:
`pre-phase5b2b-b4d1798`. Existing architecture and Phase 5B-2A reports reviewed.

IMPLEMENTED: all 20 items, including the four Legendary mechanics, saved shared
activation limit, reward odds, original assets and readable presentation.
TESTED: independent mechanics/combinations, matched balance, full regular and
extended regressions, actual Linux rendering and engine audio.
UNVERIFIED: native Windows and subjective audiovisual quality/human balance.
INCOMPLETE: no requested implementation deferred; no known functional test failure
remains. Delivery SHA and verified GitHub status are recorded below.

Agent B owns production implementation; Agent C owns independent mechanics and
balance tests. Agent A provides a bounded design audit. Agent D inspected
actual rendered effects and engine audio after presentation was ready.

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

## Independent mechanics and balance evidence

Agent C's `legendary_qa.gd` passes **20,798 checks**, zero final failures. It
covers all 20 definitions and exact reward tables, real reward settlements and
replay rejection, stock persistence, old saves and missing optional counters,
malformed counters, same-match reload limits, save-failure rollback, ordinary
and Reaper freeze at multiple timestep sizes, economy during freeze, charged
attacks, transformations, exposed pursuit, valid and invalid Seal windows,
Guardian triggers on all five maps and three modes, and exact Fortune accounting.

`legendary_combos.gd` passes **140 checks**, zero final failures. It exercises
finite shields, mitigation, repair, automatic rescue ordering, old control
items, Legendary limits and rank-perk interactions. Initial failures were test
fixture sequencing issues: a curse partial-frame result was reused without the
next item tick, and an old First Aid flag was left set in a prepared fixture.
They were corrected without weakening production assertions; initial logs remain.

`legendary_balance.gd` completes **120 matched simulations**, zero invariant
failures: five maps × three modes × four loadout policies × baseline/item arms.
The pairs are Freeze + Repair, Seal + Shield, Heart + Barricade, and Fortune +
Feather. Paired runs use the same rank perks, seed and earned match currency;
item stock is a disclosed fixture budget, not claimed naturally earned stock.

| Difficulty | Baseline | Legendary loadout policy |
| --- | --- | --- |
| Normal | 20 wins / 0 losses | 20 wins / 0 losses |
| Long Night | 17 wins / 3 losses | 18 wins / 2 losses |
| Hell | 5 wins / 15 losses | 13 wins / 7 losses |

There were 32 successful Legendary uses across the 60 item-arm matches and 114
manual activations including older items. Automatic Heart is included in the
Legendary count but excluded from the manual count. All four triggered in the
matrix: Freeze 5, Seal 8, Heart 4, Fortune 15. The 8,000-XP fixture remains Master
without the separate Mythic gates; existing Mythic tests cover those gates.
These are limited diagnostic
policies, not human win rates, exhaustive seeds or proof every combination is
balanced. Strategic items help without guaranteeing victory in the tested Hell
runs. Baseline difficulty definitions were not inflated to offset item power.

## Regular and extended regression evidence

All existing suites in `tools/check.sh --extended` were executed in sequential
batches, preserving successful results when the audio-import failure was fixed.
No assertions were disabled. `regression-all.log` contains the passing first
batch; `regression-audio-initial.log` preserves the five import-related failures;
`regression-audio-final.log` passes after the fix; `regression-remaining.log`
contains the remaining regular suites, extended matrices, profile round-trip
and startup. Final editor import is clean in `import-final.log`.

- Existing original-item QA: 11,203 checks; advanced-item QA: 7,988; advanced
  combinations: 27. Both existing 60-match item matrices preserve their previous
  outcomes. The original-item seed sweep increased to cover the rarer new drops;
  old effect assertions remain intact.
- Core model: 126; Mythic: 200 + 7; rank: 350; boss: 6,699 + 25 architecture +
  42 audio checks and 60 matched comparisons.
- Difficulty: 268 checks and 90 simulations. No-item outcomes remain Normal
  29/1, Long Night 18/12, Hell 3/27.
- Maps: 15,348 core + 5,107 integration + 922 UI checks; 144 matches, 79 wins /
  65 losses, none unresolved. Campaign: 85 profile + 126 flow checks and 20
  matches, 9 wins / 11 losses.
- Building purchase/refund: 314 + 421; horror: 319 + 21 + 5; existing input,
  layout, projectile, furniture and scene suites pass. Audio: 233 assertions,
  81 streams and four music starts.
- Economy property tests: 20,000 transactions and 175,941 invariants; six rate
  scenarios. Extended tests: 27 timestep scenarios, 144 room/strategy cases and
  48 rank/perk matches. Separate-process profile write/read/cleanup and main
  startup pass.

`tools/check.sh` now also includes the three Legendary suites for future runs.


## Actual visual and audio implementation

Four original SVG icons and five deterministic synthesized PCM cues extend the
existing assets: one activation cue per Legendary plus a distinct Legendary
reward reveal. There are now 81 decoded audio streams; the four permanent music
stems and existing bounded voice/priority queue remain.

Time Freeze draws blue temporal shockwaves, clock hands and a countdown; a
separate Hunter animation clock holds sprite/robe movement during the freeze.
Seal draws golden binding geometry and shows `SPECIAL ATTACK INTERRUPTED!`.
Heart animates golden wings, a glowing heart and a finite shield, with
`GUARDIAN HEART ACTIVATED!`. Fortune opens a cursed chest, emits coins and purple
smoke, displays `+500 GOLD`, and shows a visible curse timer/pressure warning.
A brief 1.6-second Legendary name banner occupies a reserved left-side area,
leaving the combat warning visible. No gameplay pause or long cinematic is used.
Reduced Effects retains names, markers and timers while reducing ornament.

Agent D's full rendered smoke passes **115 checks**, zero failures and no engine
errors. Actual Godot 4.6.3/Mesa captures cover all three inventory pages, exact
20-item odds, a saved Legendary receipt/reveal, all four effects, invalid Seal,
expiry, one-use limit, Reduced Effects, and 960×540 layouts. These are isolated
prepared fixtures exercising real production methods and input, not natural
matches. The coordinator additionally inspected final Fortune, Heart and exact
Consolation odds screenshots. Evidence is under `docs/evidence/legendary/`.

An actual Godot master-bus recording is 11.7029 seconds, stereo 44.1 kHz, peak
2,589/32,767 and RMS 200.39, with zero clipped samples. All four activation cues
and the Legendary reveal cue played; 81 streams load, no assets are missing,
four music stems start, and no critical sounds remain queued. Ordinary competing
sounds may still be intentionally dropped by the existing bounded audio budget.
The Dummy output driver was used while recording the real mixer. No human
listening or Windows speaker-quality claim is made.

Confirmed presentation defects fixed and rerendered: degenerate first-frame
Heart wing polygons, a Legendary banner hiding the combat warning, freeze text
near door HP, inventory description/button overlap, and a stale invalid-Seal
toast after a later successful activation, and expiry labels crossing door HP.
The full audio regression also detected that Godot had initially imported the
five new cues with compression enabled, unlike the existing PCM convention.
Those import settings now use uncompressed PCM; the original audio suite passes
233 assertions with all 81 streams. The generator preserves the lossless setting
on regeneration. A refreshed engine capture verifies the final runtime audio. Initial failed
logs remain available; no regression assertion is disabled.

## Native Windows and scope limitations

UNVERIFIED: native Windows import, launch, keyboard/mouse/FPS and speaker output;
subjective excitement, visual/audio quality and human balance. Linux import,
rendering, input fixtures and recordings do not establish native Windows results.
The project, Windows export preset, rank/stage catalogs and boss tuning remain
unchanged. No previous Windows executable was overwritten or rebuilt.

Home checklist: download the `work` ZIP, import `project.godot` in Godot 4.6.3,
load an existing profile, verify old stacks/XP/stages, equip two types and use
keys 1/2 or hotbar clicks. Check freeze during a charged attack and transformation,
invalid then valid Seal, lethal Heart followed by a second hit, Fortune's exact
Gold/expiry, one-Legendary limit, reduced visuals, and saved spin acknowledgment.
Verify ordinary purchases, cancellation, selling and actual-investment refunds.

No Phase 5B-3 achievement integration, Android, additional ranks/stages/maps/bosses,
multiplayer or unrelated feature was started. Stop after Phase 5B-2B.


## Git checkpoints and delivery

Recovery baseline: `b4d1798d82a458636eebb1b62419f7e0bbd66b7d`, with local tag
`pre-phase5b2b-b4d1798`. Verified mechanics milestone: `e920274`.
Final implementation/evidence commit and private `work` push verification are
recorded after the completed tests. `main` is unchanged.
