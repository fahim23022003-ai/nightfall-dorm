# Phase 5A — Mythic rank and permanent progression

Continued the existing clean `work` branch at
`be88734e89cf563e267991d1ee7c70759776ac44`.
Recovery tag: `pre-phase5a-be88734`. Existing Phase 1–4B systems remain the base.
Agent B owns production changes, C independently tests progression/migration,
and D inspects actual rendered progression screens. No Phase 5B work is included.

Implementation and validation completed; native Windows checks remain manual.

## Implemented rules

The existing six ranks retain their XP thresholds and six perks. The hierarchy
is Bronze0, Silver250, Gold700, Platinum1400, Diamond2400, Master3800, Mythic8000.
Mythic additionally requires stage5 cleared, three combined Long Night/Hell wins,
and three Reaper defeats. These rules live in RankCatalog. A player with enough
XP stays Master until all gates are met. Mythic grants prestige and its original
purple/gold badge and promotion cue; no new gameplay perk or reward-choice system.

Victory XP retains120base, capped survival3per10occupiedseconds(max90),
damage1per50damage(max100), defense1per50door damage(max30, intact surviving
door). Actual dead-Hunter victories add10×stage number and40for a transformed
Reaper, then difficulty adds floor25%LongNight or50%Hell. Existing first-stage-
clear XP40/50/60/70/80 is added once through existing campaign settlement. The
lifetime XP ceiling remains transparent in the breakdown.

Losses have no difficulty bonus: min(30, floor(occupied_seconds/30),
floor(20% of survival+damage+defense)). Thus20-second losses give0XP and losses
cannot exceed2XP/minute of occupation. This limits deliberate Hell loss farming.
Genuine finalized early defeats can be recorded even when they earn0XP; aborted
starts do not count. Victories require a dead Hunter and living player.

The profile tracks completed matches, wins/losses, each difficulty's wins,
Reaper defeats and highest rank; existing campaign records supply highest cleared
stage and best stage times/damage/XP. Match IDs and existing settlement guards
prevent duplicate XP, stats or promotions, including after reload. A failed save
leaves a pending in-memory generation that can be saved again without settling
the match twice; the result screen shows the existing save-retry control.

The rank screen displays seven original badges, current/highest rank, lifetime
XP, next-rank progress and gates, difficulty records, stage records and existing
loadout controls. The large badge pulses. Results show difficulty, XP components,
old/new rank and an animated XP increase; Mythic uses a distinct badge pulse and
original synthesized sound. Existing Next Stage/loadout, Retry and menu actions
are retained. All displayed statistics are saved values.

## Save compatibility

The outer save remains version1; an optional progression.version1 section adds
validated counters/highest rank. Old XP, equipped perk, settings, active match,
last award and campaign records survive loading. Missing historical mode/Reaper
counts start at zero because old saves did not store them; prior campaign clears
remain intact. The UI identifies when these new records began. No old XP is
reset and no old perk needs to be earned again.

Validated JSON counters are cast back to integers. Damaged optional counters
are discarded with a warning while base progression survives. A future optional
schema loads known data read-only to preserve unknown fields. Existing temporary
write/validation/backup/quarantine safeguards remain. Highest-rank data cannot
bypass XP or Mythic accomplishment gates.

## Test evidence and pacing

Independent fixed-case QA:200checks passed; existing ranked progression350checks
passed. Tests cover exact thresholds/each Mythic gate, integer calculations,
mode comparisons, exact breakdown sums, legitimate results, repeats/reloads,
failed-write retry, old-save migration, damaged/future fields, settings/perks,
campaign records and persistent Mythic status. Confirmed arithmetic and JSON
integer-type issues were fixed and retested; no assertions were disabled.

Deterministic pacing benchmarks at120active seconds and ordinary performance:
196XP ordinary victory implies41wins to8000; stage5ReaperNormal286 implies28;
Hell429 implies19. These are arithmetic illustrations assuming those successful
outcomes, not observed human win rates, playtime forecasts or requirements to
repeat a particular stage. Gate achievements still apply; no combat difficulty,
income, prices or turret/boss statistics were changed for progression pacing.

Final validation:200 independent progression checks plus7 exposed-defeat edge
checks,350 existing rank checks and63 updated legacy progression UI checks pass.
Regular suites completed in resumed batches after updating old UI text assertions
and fabricated victory fixtures to set the Hunter dead. Exact original award
expectations and duplicate-save assertions were retained; semantic assertions
were expanded for seven ranks, promotion animation and perk tooltips.

Gameplay evidence:6,699boss checks,42boss-audio checks,60matched boss simulations,
90difficulty simulations(Normal29/1,LongNight18/12,Hell3/27),15,348map-core,
5,107integration,922map-UI checks,144mapmatches79W/65L,20campaignmatches9W/11L,
85campaign-profile/54flow checks. Purchase/refund314+421, horror319+21+5,
183audio checks with56decoded streams/four music starts, controls/layout,
projectiles, scenes, collision and3,209availability checks pass. Legacy12matches
9W/3L,20ktransactions/175,941invariants and sixrate scenarios pass. Additional
48rank/perk matches22W/26L pass. Main startup passes. Separate-process profile
roundtrip is verified with the existing exact866XP expectation and settings.

Actual Godot/Mesa render:40checks passed,13screenshots inspected. Gates at
Master, all seven badges, real prepared Mythic settlement, visible XP/badge
animation, difficulty/breakdown, menu/loadout and actual Retry were inspected at
1280×720/960×540. Coordinator additionally viewed Master requirements, Mythic
ranking and promotion frames. A6.41-second actual engine mix has zero clips;
Mythic cue played once,56streams loaded with no missing assets. This is engine
mix evidence, not human audition. The capture uses isolated prepared profiles,
not naturally played victories. See docs/evidence/ranks/README.md.

Confirmed visual issues fixed and recaptured: results lacked difficulty; menu
requirements exceeded retained label width; promotion animations initially ran
behind the existing result fade. Animations now begin after that fade and leave
buttons available. Final empty-stage wording is 'uncleared', accurately describing
completion records. The no-room exposed-player defeat edge now records one
legitimate defeat with zeroXP and survives retry/reload without duplication.

No known failures remain in tested paths. Original combat model, room economy,
map data and Windows project/export settings are unchanged.

## Unverified and scope

Native Windows import/launch/input/audio/FPS and subjective badge/audio appeal
remain unverified in the Linux cloud. Manual Windows checklist: import the work
ZIP in Godot4.6.3; load an existing save; check its XP, perks/settings and stages;
inspect Ranks at Master/Mythic gates; play a genuine win and defeat; check exact
breakdown and one settlement; retry/change loadout/Next Stage; close/reopen and
verify records and audio settings. Test purchase double clicks, cancellation,
50%separate-currency sales, Reaper victory and all five maps during normal play.
No Phase5B, new perks, reward choices, maps, bosses or Android work was started.
Final response records the committed SHA and actual verified private work push.
