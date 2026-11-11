# Independent gameplay audit

Agent A reviewed production gameplay scripts, catalog values, the existing deterministic assertions, fixed-seed match outputs and reference access during the autonomous audit beginning 11 November 2026 at 09:48 Singapore time (01:48 UTC). This is an implementation audit against the user's contract, not a verified Haunted Dorm equivalence score.

## Reference evidence

Fresh requests to the two supplied reference pages and Google Play search each returned `curl: (56) CONNECT tunnel failed, response 403`. No source content was available. The review gives no credit for unverified exact original-game mechanics, numerical fidelity, or typical original match duration. Original configured approximations remain appropriate until those sources can be read.

## Verified systems

The code contains real room movement and selection, proximity-gated sleeping, gold only from living occupied beds, configurable bed/door levels and costs, separate electricity, six functional buildings with upgrades, actual turret range/cooldown/damage, intact-door protection, breach/elimination, five autonomous resource-spending residents, a hunter finite-state machine with corridor routes and return through breached doors, growth, and terminal results/restart. Bots now visibly approach their beds from assigned doorways; initial room assignment still spawns them at those doorways.

QA reported 125 deterministic assertions, 11 scene checks and 12 completed natural simulations passing before this audit. These establish tested behavior, not exact reference fidelity or broad balance quality. Final expanded audit results and raw command outputs belong in QA_REPORT.md and its linked evidence.

## Baseline findings and priorities (resolution below)

1. **High: player contribution and progression are weak in the baseline balance.** The pristine-HEAD expanded matrix (6 player rooms × 12 seeds × passive/active strategies = 144 matches) produced passive 48 wins / 24 losses and balanced 72 wins / 0 losses. Passive rooms 3 and 6 always lost; the other four always won. Median duration was 81.7 seconds; maximum observed bed and door indices were only 1, and maximum hunter level was 2. This leaves advanced resource progression little time to matter. This is an observed balance problem, not a claimed difference from inaccessible reference statistics. QA independently executed that matrix before changing balance. Developer was asked to tune and rerun a comparable matrix rather than simply increase numbers without evidence.
2. **Medium: strategy profiles are behaviorally distinct but initially not data-driven.** Guard focuses later door upgrades; gunner/engineer/economist have distinct purchase order, yet those orders originally lived as arrays in BotAI rather than configurable catalog profile data. Request sent to production owner to centralize profiles.
3. **Low: result shot/damage counters aggregate all residents.** MatchModel.shots and damage_dealt include bots. The UI must describe them as team/match totals or track player-owned fire separately. Player gold income is separately tracked. This does not invalidate combat but ambiguous totals overstate player contribution.
4. **Known simplification: no explicit separate close-door action.** Sleeping closes the door automatically. This preserves the bed-defense loop but should be stated in the handbook rather than imply a separate door interaction.
5. **Known simplification: geometric range combat.** Turrets use distance, cooldown and living-target checks, with instantaneous visible attack traces. They do not implement projectile flight or wall occlusion. The user permits equivalent visible attacks; no unsupported reference claim is made.

## Fixes and measured improvement

The production owner moved AI profiles into `Catalog.AI_PROFILES`, added deliberate savings for bed/door progression and repairs only near critical HP, strengthened the hunter and active target exclusion, and separated player-owned shot/damage counters from match totals. Other reviewers added regressions for dead/paused/terminal purchases, large-frame movement tunneling, fifth-bot room assignment, intruder locking, simultaneous death precedence and maximum-level effects.

I inspected `docs/evidence/audit-final-matrix.log` after these changes: **144 completed matches, zero unresolved; passive 0 wins / 72 losses, balanced 72 wins / 0 losses across all six player rooms.** Active median duration was **141.0 seconds**; all 72 active matches reached advanced progression, all built an Arc turret and relay, 71 upgraded a building, and observed bed/door indices reached 4 (level five). This specifically addresses baseline carry and progression findings. It does not prove balanced difficulty for every human strategy or exact original-game pacing.

The earlier candidate still lost every room-3 active run; that intermediate result is preserved in `audit-checkpoint-matrix.log` and `audit-nearest-room-profiles.log`, not represented as current behavior. Saving behavior and active retarget exclusion resolved it in the newer matrix. Final timestep/cooldown evidence was also inspected: `audit-final-rates.log` reports identical 30-second turret/hunter attack counts at 0.02/0.05/0.1-second steps (6 scenarios, zero failures); `audit-final-timesteps.log` completes 27 full matches with zero unresolved and consistent outcomes. `audit-final-checks.log` reports 125 model assertions, 19 scene checks, 64 focused regressions and 175,941 property checks across 20,000 transactions, all with zero failures. The twelve ordinary simulations finish with 9 wins and 3 losses. `QA_REPORT.md` remains the authoritative execution report.

No production code was edited by this reviewer. Findings were sent to the production owner and coordinator. The functionality rubric below is based on reviewed fixes and executed matrix results, confirmed by the final regression evidence below.

## Functionality rubric

| Area | Points | Evidence | Remaining limitations / improvements |
| --- | ---: | --- | --- |
| Core loop | 29 / 30 | Menu→movement→claim→sleep→build→combat→result→restart executes in model/scene tests; both natural outcomes across six-room matrix | One small fixed map; broader human usability and session testing remain |
| AI | 18 / 20 | Five configured spending profiles, visible bed approach, FSM navigation/door attacks/breach/exit/growth, active retarget exclusion; no unresolved matrix runs | Bots initially spawn at assigned doorway; hardcoded rectangular routing is suitable only for this map, and automated difficulty does not establish human challenge |
| Economy | 15 / 15 | Gold/power separation, atomic prices, prerequisites, six real building effects, maximum levels, and advanced natural progression all exercised | Balance remains original approximation; future difficulty tuning needs human playtest evidence |
| Combat | 14 / 15 | Real HP damage and repairs, closed-door barrier, turret range/cooldowns/upgrades, elimination and hunter death; manual/player-owned statistics corrected | Instantaneous attack traces and geometric range are deliberately simple; wall occlusion/projectile travel are absent but not required by the allowed equivalent-attack design |
| Functional subtotal | 76 / 80 | Verified requested systems and final regression evidence | No exact reference fidelity points included |

## Acceptance recommendation

**PASS for the requested playable core on the inspected and tested cloud build.** No mandatory core system is known missing from the inspected build. This does not mean production polish, Windows-export certification, or reference equivalence is complete. **Haunted Dorm fidelity remains UNVERIFIED**, independently of the functionality score, because all requested reference sources remain inaccessible.

The coordinator owns the full project rubric and final acceptance decision. Headless execution cannot establish readable graphics, audible sound or Windows hardware behavior; graphical audit and export limitations must remain separate evidence.
