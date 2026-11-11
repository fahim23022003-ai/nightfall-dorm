# Current autonomous continuation — 11 November 2026

**PARTIAL — functional core and cartoon redesign tested; important target-platform/art validation remains.** Earlier scores and screenshots below are historical. This continuation preserved the project at `57beb7a`; it did not restart it.

Coordinator assessment: **89/100**, a bounded engineering judgment rather than reference fidelity certification.

| Category | Score | Current evidence/improvements | Remaining limits |
| --- | ---: | --- | --- |
| Core mechanics | 29/30 | Actual room, sleep, income, placement confirmation, upgrades, match and restart checks | One map; native Windows unverified |
| Hunter/survivor AI | 17/20 | Real finite states, independent bots and resolved seeded matches; exposed-contact priority fixed | Doorway bot starts; map-specific routing; limited human strategies |
| Economy/upgrades | 14/15 | Atomic separate-resource transactions,3209 availability checks,20k transaction properties,12 pacing runs | Approximate original balance; human enjoyment unverified |
| Combat/building | 14/15 | Six functional buildings; actual travelling shots,22 flight assertions,12 edge checks; impact-time damage | One enemy identity; distance-only targeting |
| Visual/UX | 7/10 | Actual six-room cartoon captures, focused camera, readable card grid, green/red previews; bounded Agent D inspection | Bot/hunter directional coverage, high-DPI, audible mix, human polish |
| Stability/coverage | 8/10 | Import/startup,173 independent actual-input checks, scene/furniture/audit/property/rate regressions | Finite scenarios; no native Windows or exhaustive performance test |

Reference fidelity: **UNVERIFIED**. Previously requested listing/TapTap/GamingOnPhone sources were proxy403; no new accessible evidence established exact Haunted Dorm statistics. Existing original gameplay specification remains the implementation contract.

Agent B owned bounded projectile rules and the race fix; Agent C independently reproduced the race, verified the fix and tested new UI/pacing; Agent D reviewed actual Phase-A and final renders. Agent A was not reactivated for redundant blocked research. Main owned art, camera, UI integration, regressions, captures, docs and backup.

Bugs found/fixed: awake-contact/impact terminal race; clipped Dream amplifier card; hunter bar overflow; door-sill microtiles; hunter sprite background haze. No failing test was deleted to hide a failure. See `REDESIGN_QA_REPORT.md` for initial12/1→final12/0 regression evidence.

Completed representative tests:12matches9W/3L. Independent pacing:12matches9W/3L. Final rendered normal-fund automation:2matches,1W/1L. These repetitions are distinct executions, not additional unique strategy coverage. Fresh final release extended suite also passed27 timestep matches and144 matrix matches (72 active wins/72 passive losses, no unresolved cases), for183 headless match executions within that final suite. Release extended results are in `docs/evidence/redesign/final-tests.log`; earlier audit history below must not be relabeled as a new run.

Files and exact continuation instructions: [PROGRESS_CHECKPOINT.md](PROGRESS_CHECKPOINT.md), [ART_DIRECTION.md](ART_DIRECTION.md), [VISUAL_REDESIGN_REPORT.md](VISUAL_REDESIGN_REPORT.md). Windows/manual instructions in README; no public publishing/deployment was performed. Git checkpoint and verified private push are reported with the final task result.

---

# Autonomous audit and improvement report

Date: 11 November 2026 (Singapore). Engine: Godot 4.6.3 stable. Platform actually executed: Linux headless and Xorg/Mesa software-rendered desktop.

## Status and scope

**PASS — Core gameplay complete and tested.** This means the requested single-player room → bed → economy → defenses → hunter → result loop works in the tested build. It does not certify Windows hardware, commercial polish, or equality with Haunted Dorm.

**Quality score: 91.5 / 100. Reference fidelity: UNVERIFIED.** The score combines independent implementation assessments from Agents A, C and D; it is a judgment supported by executed evidence, not an automatic reference-fidelity measurement. No points establish inaccessible reference details.

The four genuine review agents resumed their existing roles after the usage-limit interruption. The previous stopping point was checkpoint `152c8e7`, with further savings/timer fixes retained in the working tree, final balance logs saved, and graphical input automation still needing correction. Those changes were preserved. The resumed session verified the existing results, repaired the automation's timing assumptions, completed rendered-match evidence, and fixed an additional awake-player elimination bookkeeping bug. No project restart or destructive repository operation was performed.

## Weighted assessment

| Category | Score | Executed evidence and implemented improvements | Remaining missing or unverified features |
| --- | ---: | --- | --- |
| Core gameplay mechanics | 29 / 30 | Movement, room claim, proximity-gated sleeping, two resources, building, combat, terminal screens and restart tested. Fixed map-click interception, wall tunneling, intruder sleep and simultaneous-death precedence. | One fixed map; automatic door closure when sleeping is a documented simplification. Exact reference flow remains unverified. |
| Ghost and survivor AI | 18 / 20 | Five configurable profiles; hunter navigation, attacks, breach, exit, growth and real retargeting. Fixed fifth-bot reservation and repair spending that starved upgrades. Final all-room matrix resolved every run. | Bots initially spawn at assigned doorways; routing is specific to this rectangular map. Human strategy diversity needs broader playtesting. |
| Economy and upgrade systems | 15 / 15 | Atomic purchases, separate gold/electricity, prerequisites, income, repair and maximum-level effects exercised. 20,000 randomized transactions checked conservation and rejection invariants. Every active matrix run reached advanced progression. | Prices and rates are original configurable approximations; long-term balance and exact original values remain unverified. |
| Combat and building systems | 14 / 15 | All six buildings have tested effects. Range, cooldown, upgrades, repairs, living targets and damage verified. Fixed cooldown drift, idle attack banking, player-owned statistics and overkill accounting. | Instantaneous visible attack traces and distance-based targeting; no projectile flight or wall occlusion. These are permitted equivalent attacks, not claims about the reference. |
| Visual and UX quality | 7 / 10 | Actual input, screenshots, readable 1280×800 and 960×600 layouts, fullscreen, specific purchase errors, effect/prerequisite tooltips, MAX labels and in-match menu return. | Original art is simple placeholder geometry. Audio quality, touch, other display scales and Windows rendering remain unverified. |
| Stability and test coverage | 8.5 / 10 | Production-model tests, actual scene/input tests, deterministic matrices, property checks, timestep/rate tests and clean startup/import. New regressions reproduce baseline failures and verify fixes. | No exhaustive proof of stability, target-hardware test, long-session certification or Windows executable validation. |
| **Total** | **91.5 / 100** | Independent reviews: [gameplay](AUDIT_GAMEPLAY_REVIEW.md), [testing](AUDIT_TEST_REPORT.md), [visual](AUDIT_VISUAL_REVIEW.md). | Crossing 90 does not establish Haunted Dorm parity. |

## Problems found and fixed

1. A full-screen UI Control consumed map input, preventing selection of nondefault building tiles. Pass-through controls now ignore mouse events; actual mouse-event and X11-input tests select tile two and build there.
2. Large movement deltas checked only endpoints and could cross walls. Movement now uses bounded substeps, with a tunneling regression.
3. Paused/finished matches and eliminated residents could still accept some transactions. Lifecycle guards now reject them without changing resources; invalid/nonfinite payment values are also rejected.
4. Standing in the reserved vacant room could leave only four bots assigned. Reservation-aware selection now permits all five bots while preserving the player's occupied space.
5. Sleeping could close a door after the hunter was already inside. That action is rejected with preserved, specific feedback; a hunter inside another room exits through its doorway.
6. A teammate killing the hunter on the same tick as the player's death could incorrectly award victory. Player elimination now has defeat precedence.
7. A hunter giving up on a defended door could select that same room again. Retargeting excludes the current target when another valid room exists, with a configurable timeout and near-breach exception.
8. Reactive repairs and cheaper utility spending consumed funds before strategic upgrades. Bots now deliberately save for bed/door progression, establish essential defense/power, and reserve emergency repair spending for critical HP.
9. Baseline balance let passive players win through bots and rarely reached advanced progression. Hunter pressure and target weighting were tuned against the same six-room seed matrix; results below show a stronger active/passive distinction.
10. Resetting cooldowns discarded elapsed-time overshoot, changing outcomes across timesteps. Timers now retain bounded overshoot without banking idle attacks. Final rate counts match across tested timesteps.
11. Result statistics credited bot fire to the player and counted overkill as damage. Counters now distinguish player-owned fire and actual removed HP.
12. The new tooltip implementation briefly introduced an unsupported numeric formatter. A graphical test failed, the formatter was corrected, and tooltip/scene regressions now cover it.
13. An awake player's capture ended the match without updating resident death/elimination totals. The resumed audit fixed both assigned and unassigned capture paths and duplicate-count prevention.
14. Purchase failures were generic and effects/prerequisites were difficult to discover. Messages now give specific shortages/reasons; tooltips expose effects and requirements. MAX states and a menu-return action are visible.

The earlier physical-resize failure from a low-level display fixture was investigated and identified as a harness artifact. Proper Window-size tests pass. It is not counted as a proven product bug. The real-input helper also had timing assumptions that sometimes left the player awake; its outcome checks and navigation were corrected rather than calling an exit-zero input sequence a gameplay pass.

## Executed validation

The pristine baseline's new regression suite reported **43 assertions, 12 failures**, retained in [audit-baseline-regressions.log](evidence/audit-baseline-regressions.log). These failures were investigated rather than deleted. Final counts and exact commands are recorded in [AUDIT_TEST_REPORT.md](AUDIT_TEST_REPORT.md), including resumed verification after the final bookkeeping fix.

- Project import and main-scene startup: passed with error-scanned logs.
- Production gameplay suite: **125 assertions passed**.
- Scene/UI suite: **19 checks passed**, including actual mouse events selecting a nondefault tile and purchasing on it.
- Focused audit regressions: **71 assertions passed**, including assigned/unassigned awake capture, exactly-once elimination and terminal action rejection.
- Property suite: **20,000 transactions, 175,941 checks, zero failures**, including 18,007 atomic rejections. Check counts are not separate gameplay scenarios.
- Combat-rate probes: **six scenarios passed**; 30-second turret/hunter counts are equal across 0.02, 0.05 and 0.1-second steps.
- Final headless complete-match runs: **183**, comprising the 144-run balance matrix, 27 timestep probes and 12 smoke simulations. All completed within their bounds; no unresolved match was observed. Repeated verification is not counted as a new unique gameplay scenario.
- Additional rendered automated-player match: **one natural victory**, seed 71, approximately **149.43 simulated seconds**, hunter level three. It used the normal starting 25 gold and production BotAI spending; no resources or damage were injected. It is automated-player evidence, not manual-play evidence.

| Comparable matrix | Passive outcomes | Balanced outcomes | Active median duration | Progression |
| --- | --- | --- | --- | --- |
| Baseline `051e681` | 48 wins / 24 losses | 72 wins / 0 losses | 81.7 seconds | Maximum observed bed/door index 1; advanced progression underused |
| Final gameplay rules | 0 wins / 72 losses | 72 wins / 0 losses | 141.0 seconds | Advanced buildings in all 72 active runs; maximum bed/door index 4; electricity spent 14,109 across active runs |

Both matrices use six starting rooms, seeds 1–12, passive and balanced spending: 144 complete runs each. The earlier candidate's room-three failure is retained as intermediate evidence; it was fixed by savings-based AI and retargeting. The final outcome split demonstrates agency for these automated strategies, not universal human difficulty balance.

## Graphical evidence actually obtained

- Real X11 keyboard/mouse navigation through menu, room entry, claim and sleep; tile selection, turret and generator purchase using earned gold; electricity production, pause, hover tooltip and menu return. See the independent visual report for exact final helper checks.
- Rendered fixtures checked insufficient-funds messages, all six building symbols, maximum levels, result contrast, minimum-size layout and fullscreen. Fixtures are labeled and are not claimed as naturally reached states.
- [80-second rendered match](evidence/audit-match-080.png): six player buildings, electricity, upgrades and an attacking hunter.
- [Natural rendered victory](evidence/audit-match-terminal.png): actual terminal result and player-owned statistics.
- Logs: [rendered match](evidence/audit-rendered-match.log), [final matrix](evidence/audit-final-matrix.log), [timestep runs](evidence/audit-final-timesteps.log), [combat rates](evidence/audit-final-rates.log).

Linux software rendering does not prove Windows graphics/performance or audible sound quality. Headless success is not presented as graphical proof.

## Reference comparison and remaining limitations

The supplied TapTap and GamingOnPhone pages and the attempted official-listing search returned proxy CONNECT 403. No inaccessible page, screenshot or video was treated as observed reference evidence. No gameplay difference from the original can be verified from unavailable source content. The verified differences in this audit are between the previous build and the requested functional contract, and between baseline and final measured behavior. Exact original prices, timing, hunter rules and numerical parity remain **UNVERIFIED**. [FEATURE_PARITY.md](FEATURE_PARITY.md) separates implemented systems from that uncertainty.

No mandatory core system is known missing in the tested build. Remaining scope is polish and broader validation: one map/hunter, simple original visuals, session-local settings, doorway bot spawning, no touch/controller interface, no verified Windows hardware run, no standalone Windows export, and no long-term human balance study. No paid assets, copyrighted reference assets, public publishing or external deployment were used. See [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md).

## Reproduce and continue

```sh
cd /workspace/nightfall-dorm
bash tools/check.sh
bash tools/check.sh --extended
```

The coordinator executed the complete `bash tools/check.sh --extended` on the final production commit with exit status **0**. Its consolidated raw output is [audit-coordinator-extended.log](evidence/audit-coordinator-extended.log). The extended command additionally runs the 27 timestep matches and 144-run matrix. Graphical tooling and its optional dependencies are documented in [GRAPHICAL_TESTING.md](GRAPHICAL_TESTING.md). Only use the existing checkout; each cloud task is already isolated.

On Windows, import `project.godot` in the standard Godot 4 editor and press F5. Start Game, move with WASD/arrows, press E inside a room to claim, approach the cyan bed and press E to sleep. Click different numbered floor tiles and buy defenses plus a Dynamo; inspect gold, power and door HP. Test repairs/upgrades under attack, defeat, victory, Restart and Return to main menu. Windows execution is an instruction for future testing, not an executed result here.

## Git checkpoints and stopping condition

- `051e6815d3288614cd74b4bb7d1787b11a223f0a`: baseline playable project.
- `152c8e7`: first audit checkpoint: lifecycle/input/navigation fixes and expanded regression coverage.
- `35eb8854d3defde4c7d14c2be09468778f365ad5`: final production checkpoint: deliberate survivor savings, stable combat timing, accurate damage statistics and terminal bookkeeping, plus regression coverage. Report/evidence and graphical tooling are committed separately.

The audit stops after verified high-priority issues were corrected, relevant regressions passed, and remaining changes would chiefly require broader reference access, target-device tests or human balance evidence. It does not stop merely because a timer elapsed. No push, deployment or public publication is authorized or performed.
