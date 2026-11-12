# Phase 5D-2 — Endless Siege and long-term replayability

## Implementation and verification status

**IMPLEMENTED:** functional Endless Siege, resumable wave checkpoints, normalized
Challenge Codes, saved Lucky Spin pity, four earned visual cosmetics, factual
post-defeat analysis and a dedicated isolated Practice Room.

**TESTED:** independent mechanics, transactions, migration, reproducibility,
practice, cosmetics/facts, earned-economy balance, real rendered scenes and
engine audio. All existing regular and extended regressions pass, including
profile process round trips and startup. Detailed evidence follows.

**UNVERIFIED:** native Windows/cross-platform execution, physical inputs/speakers,
hardware and long-session rendered FPS, human repair cadence, subjective fun,
visual/audio quality and universal balance.

**INCOMPLETE:** none of the six requested systems in the tested scope. The
platform and human-verification limits above remain explicit. Git delivery is
reported separately below; a local commit alone is not push evidence.

Started clean on `work` at `d16a82da5baccdf5bcbe566635ee949c086c7a32`, exactly
matching GitHub. Recovery tag: `pre-phase5d2-d16a82d`. Baseline checkpoint:
`1e0fc86`; independently tested core: `160081b`; integrated production:
`3cf3362f342eb410a0306b621bfcfad9aa660e0e`; final result metadata fix:
`e2a75f8fa820372478d1895e63aa0aba418d24ba`. Existing Phase 5D-1 reports,
model/AI, economy/paid ledgers, profile/rewards/items and UI were inspected first.
Six baseline Godot screenshots and 11 baseline test commands pass. `main` is
unchanged. No Phase 6 work was started.

B owned production. C independently tested mechanics, persistence, transactions
and UI. A performed bounded actual earned-currency/long-run and pity audits.
D inspected real rendering, interactions and audio. Root owns existing regression
integration, documentation, recoverable commits and exact push verification.

## Endless design and actual loop

The main menu has a functional original skull action with its own black, crimson
and violet material, hover/pressed/focus states. Select any of the five existing
maps, Normal/Long Night/Hell and a seed. Enter the actual room-selection/preparation
flow, sleep, earn resources, buy and specialize defenses using the existing
mechanics. There is one actual attacking Hunter, rotating Crusher/Stalker/Ravager
by the saved run seed and wave. There is no decorative-creature combat or enemy
swarm system.

A genuine Hunter defeat freezes the world at intermission. Buildings, actual
investment ledgers, room/door HP, dead teammates, resources and elapsed active
play remain. The world earns no Gold/Electricity and recovers no item cooldowns
while waiting. You may prepare actual buildings/repairs with existing resources,
then choose exactly one aid before the next Hunter:

- Reinforce: restore 10% maximum HP to an **intact** door.
- Salvage: add 25 Gold.
- Recharge: add 5 Electricity.

Continue creates one intentional fresh Hunter and four seconds of arrival grace;
rooms and the rest of the run are retained. Paid room/weapon buffs keep remaining
active-play duration. Statuses belonging to the defeated Hunter are removed so
Frost, Freeze, burn and decoy do not transfer to a different enemy. Per-run
Legendary, Feather and First Aid use caps do not reset between waves.

Intermission offers separate actions for **Continue**, **Save & exit** (suspend),
and **End run here** (close the run while retaining genuinely earned records and
rewards). Forfeit is explicit and grants no new rewards. A destroyed door stays
destroyed: Reinforce is not a resurrection. A following breach through that door
can therefore eliminate the player without a new door-hit event; this is carried
combat state, not an unexplained instant strike.

The HUD retains resources, current archetype, actual living team count and danger
warnings, while prominently identifying the wave, personal best and current
scaling/repair pressure. Existing premium controls, pad placement, cancellation,
50% sales and Windows keyboard/mouse controls remain.

## Bounded pressure and Reaper milestones

For wave `w`, let `e=min(19,w-1)` and `l=max(0,w-20)`:

| Endless wave factor | Formula / bound |
| --- | --- |
| Hunter HP | `min(100, 1 + 0.30e + 0.90l)` |
| Damage | `min(9, 1 + 0.025e + 0.12l)` |
| Speed | `min(1.25, 1 + 0.008 min(59,w-1))` |
| Contact repair effectiveness | `1 - min(0.65, 0.01625l)`; reaches 35% at wave 60 |

HP reaches its wave-factor cap at 124; damage at 83. These factors compose with
existing difficulty/archetype/boss/item rules, rather than representing raw final
HP or damage. Within-wave escalation is capped at one growth step/level 2 in
Endless so a single indefinitely prolonged encounter cannot evade the bounds.
Campaign growth, prices and progression are unchanged.

Existing Reaper transformation/special attacks occur on waves divisible by five,
and additionally on multiples of three from wave 30. Each new encounter may
transform once through the existing controller; there is no mid-encounter HP
refill or duplicate Reaper. Actual windups, recovery, Scythe, Soul Siege and Surge
remain. The next wave's fresh enemy is an explicit transition, not resetting an
alive boss to obtain health.

Later variety includes the archetype rotation, extra milestone encounters and
increasing contact repair pressure, not endlessly increasing HP. Intermission
and HUD explain the pressure before continuing. Actual late controlled peak-hit
tests include difficulty, Curse, charged attacks and boss multipliers: see the
balance section. Already damaged or low-tier doors remain vulnerable.

## Natural Level 10 reachability and strategy audit

[Independent earned-economy/long-run audit](evidence/replay/balance-summary.md).
There are **39 final-source policy runs /1,295 completed waves**, zero integrity
or settlement failures. These use actual walking, legal room entry, elapsed
model ticks, bed/Dynamo production, paid upgrades and real combat. No runtime
Gold, electricity, HP, positions, time or wave index is injected. Only the genuine
10% intermission repair is chosen; free Gold/Power choices are not used.

Prepared Master/Mythic progression and finite item stock are disclosed test
budgets, not naturally earned inventory or human play. Policies decide every
1.0s or 0.2s; the faster repair cadence is not evidence of human reactions.

| Genuine canonical run | First Level 10 | Actual weapon investment | Actual L10 damage before saved checkpoint |
| --- | --- | --- | --- |
| Suppression Needle | Wave 1, 155.5s | 1765 Gold /262 Electricity | 3283.2; saved wave 4 at 262.7s |
| Storm Arc | Wave 4, 229.9s | 8290 Gold /1306 Electricity | 3064.3; saved wave 4 at 252.5s |

Both are Normal, Hospital Economy room 1, seed 11, with zero sales/refunds before
first L10. They generated 5052.3 and 20174.9 Gold respectively. These are actual
separate paid ledgers and impacts, not simply a debug tower or teammates winning.
The genuine profiles reopen through normal profile/checkpoint APIs:
`balance-earned-turret-profile.json`, `balance-earned-heavy-profile.json`.
A genuine Mansion wave-20 profile is also retained. D copies these for actual
rendered resume, later-wave L10 firing and checkpoint interactions.

The prior campaign problem was the short investment horizon and the tested
policy saving for complete Arc10 before construction. Persistent Endless economy
and branch-first investment make the tier attainable without reducing campaign
prices. The final 24-case paired early/mid matrix covers all five maps, all three
difficulties/archetypes/traits and all four branches. All clear 12 waves and reach Level 10;
16 contribute actual L10 damage. Eight zero-impact cases establish availability,
not that the player's tower caused the clear. This is a bounded matched matrix,
not every possible combination or universal best strategy.

Initial capped pressure let passive builds coast through 70 waves. A subsequent
candidate still let large Mansion layouts coast through 75. Those findings and
failed candidates are retained. Final full16-pad Fortified construction reaches
four Focus Arc10/four Relay4/four Repair4 at wave 24, then stops actions and loses
at 77. Its matched active counterpart clears 130; the Power/Storm fortress also
clears 130 with active paid repairs but loses77 passively. Other passive plans
fail at 41/47/53. Active Long Night/Hell control arms clear 75 with only four Frost
and one Freeze across the entire run. Money alone does not protect the unattended
door, while deliberate paid repair and item timing remain viable.

Two separately labelled controlled real-controller tests verify extreme damage:
Hell Crusher charged + Curse + growth1 deals 1539 to a full 1620HP Power door,
leaving 81; its actual 0.65s and 0.9s warnings occur. Reaper Soul Siege deals 1155.6,
leaving 464.4 with its 1.8s warning. They use injected high-wave fixture state and
are **not** natural reachability evidence or a guarantee for damaged doors.

## Persistent records, rewards and checkpoints

Best cleared wave is a global local profile record. Milestones 5/10/15/20 each
pay **8 RM Cash +20 XP once per profile**, at most 32 RM/80 XP lifetime under
these rules. Reaching a wave alone, pausing, reloading, abandoning or repeating
an already claimed milestone cannot pay again. Current eligibility, claimed
milestones, next reward/wallet-space status and best are shown separately.
Endless does not produce campaign spins, contract bonuses, campaign clears or
ordinary win/loss statistics. Cosmetic milestones are separate visual unlocks.

An optional version-1 replay block stores one checkpoint, run identity/serial,
best/milestone claim state, pity, cosmetics, at most 32 local code records and a
last receipt. Checkpoints use strict whitelisted primitive state: rooms/owners/
traits, bed/door/building levels, exact paid ledgers, resources, valid position,
item state/caps and RNG state encoded as a canonical signed 64-bit decimal string.
Validation rejects impossible levels, wrong maps/owners, excessive multipliers,
nonfinite values, malformed/overflowing RNG and inconsistent active-run context.

**Resume is between waves only.** Mid-wave progress returns to the last safe
intermission. Permanent stock already consumed stays spent; durable Legendary,
Feather, coupon and rank-rescue flags cannot rewind. Prep purchases/sales save
before Continue, Save/Exit or normal quit. Failed save keeps the intermission
available and permits a safe retry; no phantom reward is committed. A failed
second close transaction after a successful milestone save resumes the legitimately
paid checkpoint without awarding it again.

Only one permanent campaign/Endless session is active. Campaign start while an
Endless run remains suspended routes to an explicit Resume/New/Forfeit decision.
Practice and imported challenges preserve that durable run. Unknown/newer or
malformed optional replay data loads known campaign/inventory data read-only and
preserves original bytes. Old saves without the block receive safe defaults;
previously rolled spin rewards remain unchanged and are not retroactively rerolled
or counted as new pity draws.

## Challenge Codes and comparison limits

Format: `NF2-<ruleset>-<map>-<seed>-<archetype>-<difficulty>-<resource>-<gear>-<checksum>`.
Ruleset is 1; seeds 1–999999; fixed whitelists cover all five maps, three modes and
archetypes. The checksum is the first eight uppercase SHA256 hex characters of
the canonical body. Input is bounded to 128 characters; bad syntax, fields,
canonical formatting, checksum and incompatible rulesets return useful errors.
No account identifier, password or personal save is encoded.

The UI generates the normalized 25G/0E, no-perk preset with two loaned Shields
and two Repair Kits. Supported alternate resource/gear presets are explicit
code fields and validated on import. Rank, permanent stock and personal stage
bonuses grant no combat advantage. Room traits come from the versioned map rules.
One Hunter and the usual Reaper policy determine the real encounter. There are
no permanent RM/XP/spin/achievement/campaign/Endless rewards from imported codes;
only bounded local personal challenge records may change.

Actual simulation uses fixed 30Hz challenge ticks. C runs three configurations
through six fresh engine processes with beginner versus progressed profiles;
full traces/outcomes match. This proves supported conditions and same-input
Linux/Godot4.6.3 reproduction, not perfect physical-input or cross-platform/
cross-engine determinism. Different decisions, input timing or versions can
produce different results. The UI states this limitation.

Generation, pasted validation, clipboard copy and actual play/results are
functional. Results display code/ruleset/map/mode/archetype/outcome/elapsed time,
actual damage-based score and local best; code and a message-ready summary can
be copied for Adie. Recording a successful terminal is idempotent; failed writes
can retry. Best time/outcome corresponds to the best recorded score instead of
mixing a quick failed attempt with a later victory. Shared results are explicitly
**self-reported**, with no online server/verified leaderboard.

## Transparent Lucky Spin pity

Only new legitimately eligible **campaign Victory draws** advance/reset these
counters, in the existing saved result transaction. They change at the actual
saved draw, not on opening/reopening/acknowledging the reveal. Consolation neither
advances nor resets Victory-only pity; quick ineligible defeats grant no draw.

| Draw condition | Common | Rare | Epic | Legendary |
| --- | ---: | ---: | ---: | ---: |
| Ordinary Victory |40%|40%|16%|4%|
| Eighth Victory without Epic+ |0%|0%|80%|20%|
| Fortieth Victory without Legendary |0%|0%|0%|100%|
| Eligible Consolation |80%|16%|3%|1%|

Legendary guarantee has priority. Epic/Legendary resets Epic+ dry count; only
Legendary resets Legendary dry count. The guarantee filters lower rarities and
renormalizes the registered table; it does not secretly retain the4% Legendary
rate on an Epic-guaranteed draw. Per-item odds use those same actual weights.
The queued receipt preserves draw-time odds/pity; NEXT progress is displayed
separately after counter reset. Save failure restores counters, inventory, pending
receipt, other progression and RNG; reload cannot duplicate or reroll a saved draw.
Existing four-item Victory/one-item Consolation quantities and one-successful-
Legendary-per-match/run effects remain. There are no paid spins or payments.

[500,000-draw threshold audit](evidence/replay/pity-balance-summary.md) compares
base, 6/30, 8/40, 10/50 and Consolation. Production 8/40 observes Legendary 5.534%,
mean 18.070/max 40 draws; Epic+ mean 4.080/max 8. The Epic guarantee's exact odds are
80/20, and the 40th guarantee100%. At explicitly assumed 180s wins versus 60s eligible
losses, mean Legendary-drop time is 3252.6s versus 5910.2s, with four versus one item
units. Very slow victories change timing comparisons; these are declared model
assumptions, not human measurements. Losses never move the guarantee closer.

## Cosmetic collection

Nine original new SVGs from `tools/art/generate_replay_art.py` add five replay
emblems and four cosmetic previews. Runtime shape/detail overlays are visual-only;
model calculations never read them. Existing licensed local fonts and material
components are reused.

| Appearance | Earned condition | Actual visual difference |
| --- | --- | --- |
| Iron Reliquary Door | One genuine campaign victory | Arched iron ribs, riveted lock and carved lintel |
| Cathedral Coil Turret | Clear Endless wave 3 | Twin spires, metal halo and engraved casing |
| Midnight Canopy Bed | Clear Endless wave 5 | Sculpted posts and torn canopy |
| Reaper Watch Crest | Genuine campaign Reaper victory | Engraved scythe crest beside the HUD name |

Gallery shows preview/locked/unlocked/equipped states and saves equipment.
Old legitimate accomplishments qualify without repeating them. Branch/Prestige10,
door cracks/damage, corpse/danger and projectile readability remain layered above
or alongside appearances; Reduced Effects is respected. There is no damage, HP,
income, electricity, price or progression bonus and no cosmetic purchase economy.

## Factual defeat analysis and Practice

The optional Why Did I Lose page follows a real established defeat, preserving
ordinary reward/retry controls. It reports actual source/archetype/Reaper state,
elapsed active time, final door/building/branch levels, repair counts, remaining
Gold/Electricity and equipped unused stock captured **before** new settlement
loot. Recent damage/breach/elimination history is capped 16 and door upgrade/
repair history 12. Recent-event scope is explicitly since start/resume; saved
room totals/buildings cover the run. Missing older telemetry is not fabricated.
At most two tips depend on actual stock, affordability, prerequisites or not
occupying a bed. No unavailable item/upgrade or speculative cause is asserted.

Dedicated Practice supplements the unchanged nine-step first-time tutorial.
Choose a map, real archetype/Reaper and two distinct temporary item types. The
same real model starts with a paid L4 Needle near the door, paid bed/door upgrades
and an explicitly temporary 20,000G/5,000E budget. Real attack/repair/branch/item/
Reaper mechanics operate at normal combat values (`tutorial_mode=false`). Training
focuses the player's door; Rescue selection supplies a valid injured ally.

The isolated in-memory wallet gives temporary stock, including the usual one
Legendary per reset. Pause→Reset Practice makes a fresh training state without
restarting the application. Inventory, XP, RM, spins, pity, campaign, achievements,
statistics and Endless records in the real profile do not change. All 20 items
are exercised through shared effects; UI rejects duplicate item choices clearly.
This is real gameplay practice, not a weaker tutorial or static effect demo.

## QA, long-session stability and rendering

| Independent acceptance | Result |
| --- | --- |
| Baseline |6 actual PNGs/14 render checks;11 baseline commands pass|
| Endless |28,123 checks/45 actual approaches across5maps×3modes×3archetypes, real wave 5 Reaper/specials|
| Late bounds focused |187 checks, huge finite encounter time, real charged/boss/Curse composition|
| Transactions |284 checks, stock/caps/failed save/retry/forfeit/resume/no-room defeat|
| Codes |759 checks including six fresh engine workers; 749 focused checks after input validation hardening|
| Pity |20,180 checks/6000 draw scenarios, exact odds/receipt/reset/rollback|
| Migration |190 checks preserving frozen prephase20-item/strategy profile|
| Practice |3644 checks/all20 items/15map-archetype cases, plus87 focused effect checks|
| Facts/cosmetics |25 checks, real terminal guard, exact stat neutrality|
| Safe retirement failure |21 checks, paid checkpoint survives failed second close save|
| Actual UI |1,537 checks, real Continue, input, mode transitions, save/prep, reset and carried-feedback verification|
| A earned/long-run |39 final runs/1295 waves, zero integrity/settlement failures|
| A pity balance |500,000 seeded draws, zero harness failures|
| D actual rendered/audio |119 after PNGs plus six baseline; 531 final accepted checks/0, including final explicit Challenge metadata/clipboard verification|
| Existing regular/extended /final import |All pass; 71 resumed commands plus initial core/strategy suites and corrected migration; final import clean|

Counts include repeated invariants rather than that many independent scenarios.
Prepared resources in transaction/graphical fixtures are not natural economy
proof. Genuine earned checkpoint renders are separately identified. Initial
failed fixtures/parse assumptions and genuine defects are retained in logs.

Long-run advanced observations reach 130 waves. Engine object monitor stays 1511
through waves 60–130; approximately 241KB static-memory increase includes the
auditor's intentionally retained per-wave result rows. Final saves are about18KB;
25 controlled checkpoint transactions separately stay around11.9KB. Observed
peaks are 15 projectiles, 25 combat records and 128 presentation records, with zero
active projectiles at cleared checkpoints. Scars, floating feedback, item events,
pooled audio and material caches remain bounded. These are finite engine/model
observations, not proof of infinite-session memory or Windows FPS.

Actual rendered evidence is indexed separately below. No subjective human
listening or premium-art score is inferred from automated counters.

The full existing regular/extended regression was completed in two segments.
`regression-full.log` records import, core (126), premium mechanics (172,343 /
270 approaches), economy (556) and contracts (425). It stopped on the old
migration test's raw Dictionary equality after JSON round-tripping new numeric
fields. The existing exact numeric comparator now handles int/float representation
without changing values, schema or rejection assertions; migration then passes
159 checks. This was a test representation defect, not a relaxed save rule.

`regression-resume-results.json` records all 71 remaining commands with exit 0
and no engine/assertion errors. This includes every remaining regular suite,
three old extended simulations, eight existing and two new controlled balance
fixtures, four fresh profile-process steps and actual startup. Examples include
all 20 items, Legendary combinations, five maps/three difficulties, tutorial,
rank/perks/achievements/shop/rewards, building double-click/cancel/refunds,
projectiles, horror/AI/Reaper and audio. Detailed logs retain wins and losses:
passing a strategy test does not mean every simulated match was won.

All nine new independent replay suites are now registered in `tools/check.sh`;
their final C runs are documented in `qa-summary.md`. They were tested independently,
not falsely reported as part of the earlier single uninterrupted check command.
Final editor import also passes. Historical boss/rank evidence regenerated by
regression tools was copied into this phase's folder; the old phase files were
restored unchanged.

## Actual graphical and audio evidence

[Rendered review and fixture provenance](evidence/replay/README.md),
[hash/dimension manifest](evidence/replay/render-manifest.json) and
[accepted run index](evidence/replay/render-final-verification.json) preserve
119 actual after PNGs and the six unchanged baseline PNGs. D reviewed the complete
screen families at 1280×720/1920×1080; root also opened representative full-size
menu, earned Arc/Needle10, Reaper, intermission, Challenge result, pity, equipped
cosmetics, defeat analysis and Practice rasters. They are actual Godot output,
not edited mockups. Representative links:

| Required scene | Actual screenshot |
| --- | --- |
| Skull mode button | [Menu](evidence/replay/render-screens/after/01-menu-720.png) |
| Wave HUD / early play | [Wave 1 claimed and occupied](evidence/replay/render-screens/after/endless-actual-wave1-occupied-720.png) |
| Genuine advanced checkpoint | [Wave 20 completed](evidence/replay/render-screens/after/detail-authentic-wave20-final-milestones-720.png) |
| Later pressure / Reduced Effects | [Wave 21](evidence/replay/render-screens/after/detail-endless-wave21-reduced-720.png) |
| Earned Needle10 | [Actual later-wave combat](evidence/replay/render-screens/after/earned-needle-level10-combat-720.png) |
| Earned Arc10 | [Actual later-wave combat](evidence/replay/render-screens/after/earned-arc-level10-combat-720.png) |
| Grim Reaper milestone | [Actual transformation](evidence/replay/render-screens/after/earned-needle-reaper-milestone-720.png) |
| Code generation | [Generated code](evidence/replay/render-screens/after/extra-code-generated-720.png) |
| Challenge results | [Self-reported actual result](evidence/replay/render-screens/after/challenge-actual-result-720.png) |
| Pity receipt versus NEXT | [Legendary guarantee odds](evidence/replay/render-screens/after/pity-legendary-guarantee-receipt-next-720.png) |
| Cosmetics gallery | [Four equipped designs](evidence/replay/render-screens/after/cosmetics-four-equipped-gallery-720.png) |
| Cosmetics in actual gameplay | [Cracked door, canopy, turret branch10 and badge](evidence/replay/render-screens/after/cosmetics-damaged-door-branch10-world-720.png) |
| Why Did I Lose? | [Actual recorded damage/repair/stock](evidence/replay/render-screens/after/defeat-real-door-facts-before-reward-stock-720.png) |
| Practice Room | [Real combat and temporary item use](evidence/replay/render-screens/after/practice-real-combat-720.png) |

Boundary pity, defeat and cosmetics fixtures use prepared inputs explicitly
explained in the render index; they are not natural progression evidence. The
Needle/Arc and advanced profile copies preserve A's genuinely earned runtime
state. Only D's isolated copy's tutorial-completed flag changes so menu return
does not enter first-time onboarding; the canonical originals remain unchanged.

No audio assets were removed or replaced. Actual real-time master-bus capture
`render-realtime-mix.wav` is 18.297324 seconds, peak 0.03552246 full scale,
RMS 0.004455128, zero full-scale samples. Real event diagnostics show 105 valid
streams, zero missing/dropped/backlogged events, peak 6/16 voices and 24 audio
nodes unchanged across five mode transitions. It includes valid Inferno and
Overdrive activations, Reaper attacks, combat/weather and scream routing.
The Continue test verifies preserved actual scream/pending laugh and subsequent
queue drain. The separately retained accelerated earned-run mix drops 1,015
low-priority events under stress; it is not used to claim normal real-time audio
quality. Software rendering/Dummy hardware output cannot verify physical speakers,
perceived loudness, hardware FPS or subjective horror/art/audio quality.

## Defects found, remaining limits and delivery

Confirmed issues found and fixed include JSON-number validation blocking
reopened replay records, canonical RNG overflow errors, stale target buffs on a
fresh Hunter, missing required durable Legendary state, pre-claim First Aid
binding, genuine unclaimed-player defeat cleanup, unrecorded fake defeat facts,
misleading carried-income floats, silent blocked-campaign start, duplicate
Practice setup choices, omitted claimed/eligible reward feedback, and missing
explicit difficulty/archetype metadata on the Challenge result card/summary. Actual
immediate Continue audio truncation is fixed and retested: same-run encounter
transition preserves the active scream, queued laugh and critical serialization,
then the queue drains. Obsolete boss windups alone stop. Known passive
plateaus drove bounded Endless-only tuning; campaign prices were preserved.

Limits: one saved run and between-wave resume only; consumed permanent stock
stays spent after a rewind; destroyed doors/teammate deaths carry; local Challenge
results are self-reported; reproducibility requires the supported rules/input/
engine conditions; prepared progressed budgets and fast repair policies are not
human acquisition/skill evidence. Simplified existing actors/pads remain. No new
multiplayer, online leaderboard, payment, Android, campaign expansion, character
or Phase 6 feature was implemented.

Implementation and verification are complete. The integrated source checkpoint
`3cf3362f342eb410a0306b621bfcfad9aa660e0e` was successfully pushed and matched
GitHub; final explicit Challenge result metadata is committed at
`e2a75f8fa820372478d1895e63aa0aba418d24ba`. The complete source/evidence delivery
receipt below is added only after its actual GitHub push and SHA comparison.
