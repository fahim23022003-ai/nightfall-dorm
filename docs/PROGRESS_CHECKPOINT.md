# Progress checkpoint

Saved: 11 November 2026, Singapore time. This task preserves the completed implementation and audit; it does not begin a new development phase.


## Latest gameplay/visual follow-up (supersedes older export/UX limitations)

Started from verified GitHub `ea9438e`. Implemented availability-aware actions and specific hover reasons, selected-building catalog names and upgrade costs, coherent button states, and a cleared hunter/door caption overlap. No model/AI/economy/combat rules changed. Only one bounded visual specialist review was used.

Fresh regular regressions passed: 125 gameplay, 19 scene, 71 audit assertions, 20,000 transactions / 175,941 property checks, six rate scenarios and 12 completed simulations (9 wins/3 losses). Final focused availability checks passed 3,209; scene checks passed 19 again. Two actual rendered complete matches produced natural victory and defeat using ordinary funds (14 fresh complete match runs total). Logs and 12 labeled screenshots are linked from GAMEPLAY_FIDELITY_AUDIT.md and VISUAL_AUDIT_REPORT.md. Older 144/27-run results below remain historical, not new reruns.

A real Windows x64 executable now exists at `builds/windows/NightfallDorm.exe`, packaged as `/workspace/NightfallDorm-Windows-x64.zip`. Full official template SHA-512, PE architecture, embedded pack, SHA-256, export exit and empty-directory Linux pack startup were checked. Native Windows execution/audio remain UNVERIFIED. The source/preset/evidence are tracked; the generated binary ZIP is a local downloadable artifact. Exact Haunted Dorm mechanics and authentic visual comparison remain UNVERIFIED (fresh source requests still proxy-403).

**Next task:** manually test the provided Windows build rather than creating another export from scratch. Prioritize actual target-device failures and newly accessible reference evidence before another mechanics or art rewrite. This follow-up is READY FOR MANUAL PLAYTEST, not a Windows runtime certification.

The follow-up commit is pushed to the authorized `work` branch and its remote SHA checked before the completion message. Use `git log -1 --format=%H` and `git ls-remote origin refs/heads/work` for its exact latest revision; the older backup record below describes the prior checkpoint.

## Completion status

**PASS — the desktop core gameplay is implemented and tested on Linux.** It is not a finished commercial release or a verified Haunted Dorm replica. The independent audit score is 91.5/100 for implementation quality; reference fidelity remains UNVERIFIED.

The repository was clean at the start of this checkpoint. All Godot scenes, scripts and configuration were already saved and committed; no game-source changes were needed. No specialist subagents were activated for this routine checkpoint.

Completed features:

- Functional main menu, handbook, settings, pause, match results, restart and in-match menu return.
- Six dorm rooms, corridors, player movement/collision, room claiming, proximity-gated sleeping and a configurable 30-second preparation phase.
- Occupied-bed gold income, bed/door upgrades and prerequisites, separate electricity, atomic purchases and real repair mechanics.
- Six functional building types with placement and upgrades: basic/advanced turrets, generator, repair station, economy amplifier and enhancement relay.
- Hunter targeting, corridor navigation, door combat, breach, elimination, growth, retargeting and death; five autonomous residents with configurable strategies and deliberate upgrade saving.
- Visible attack/damage/income feedback, original procedural artwork, synthesized effects, player-owned statistics and both natural victory/defeat outcomes.

## Important fixes already secured

The completed audit corrected map-click interception, wall tunneling, paused/terminal/dead-resident purchases, fifth-bot allocation, sleeping with an intruder, hunter doorway routing and repeated-target selection, bot repair/upgrade starvation, cooldown timestep drift and idle attack banking, simultaneous-death precedence, overkill/player statistics, awake-player elimination accounting, tooltip formatting, and misleading purchase feedback.

The graphical helper was also corrected to verify rendered outcomes instead of treating an executed input sequence as a gameplay pass. A resize-harness artifact was investigated and documented rather than counted as a proven product defect.

## Fresh checkpoint verification

Executed from `/workspace/nightfall-dorm`:

```sh
bash tools/check.sh --extended
```

**Exit status: 0.** Full raw output: [progress-checkpoint-tests.log](evidence/progress-checkpoint-tests.log).

| Check | Actual result |
| --- | --- |
| Godot import and main-scene startup | PASS; no error signatures |
| Gameplay assertions | 125 passed, 0 failed |
| Scene/UI checks | 19 passed, 0 failed |
| Focused audit assertions | 71 passed, 0 failed |
| Transaction properties | 20,000 transactions; 175,941 checks, 0 failed |
| Combat rates | 6 scenarios passed across three timesteps |
| Representative matches | 12 completed: 9 victories, 3 defeats |
| Timestep matches | 27 completed, 0 unresolved; consistent outcomes across tested step sizes |
| Room/seed/strategy matrix | 144 completed: 72 active victories, 72 passive defeats; 0 unresolved |

The fresh suite executed 183 complete headless match runs. Repeated verification is not additional unique scenario coverage. Graphics were not rerun in this checkpoint because no game code changed: prior real-input/OCR checks, 960×600 and 1280×800 frames, fullscreen and a default-resource rendered match ending in victory are retained in [AUTONOMOUS_AUDIT_REPORT.md](AUTONOMOUS_AUDIT_REPORT.md) and [AUDIT_VISUAL_REVIEW.md](AUDIT_VISUAL_REVIEW.md). Windows and audible sound are not established by these results.

## Git and backup record

- Existing repository: `https://github.com/fahim23022003-ai/nightfall-dorm.git`.
- Existing local branch: `work`; keep this branch rather than resetting or recreating the project.
- `051e6815d3288614cd74b4bb7d1787b11a223f0a`: initial playable source.
- `152c8e7`: first audit fixes and regression checkpoint.
- `35eb8854d3defde4c7d14c2be09468778f365ad5`: final gameplay/timing/AI/state fixes.
- `6bec4f42b04edbfa15f1658f23e8a9443fd306df`: complete audit, graphical tools and evidence.
- GitHub read access was checked successfully; the remote advertised no refs before this checkpoint.
- **GitHub backup verified:** `git push --set-upstream origin work` succeeded. A subsequent `git ls-remote origin refs/heads/work` returned `0e90d22f80c8566468126e7d0c42e30f461ba2ef`, exactly matching the local checkpoint commit containing this roadmap, workflow instructions and fresh test log. The branch now tracks `origin/work`. No force push was used.
- This backup-status entry is a documentation-only follow-up to that verified content checkpoint. Its final commit is also pushed and its remote SHA checked before task completion; use `git log -1 --format=%H` and `git ls-remote origin refs/heads/work` to identify and recheck the latest saved revision. A local commit by itself is never considered a GitHub backup.

## Remaining issues and ordered roadmap

There is no known unresolved critical core-system defect in the tested paths. Remaining work must be driven by new evidence, not another automatic whole-project rewrite.

1. **Core systems / target validation:** highest-priority unfinished task is validating one complete match on Windows, the primary target. Use the now-created local Windows playtest build (or reproduce it with the tracked preset and official templates), and verify menu, movement, sleeping, multiple build tiles, economy, combat, both outcomes and restart. An executable export now exists; its native runtime remains unverified. Obtain accessible reference evidence before asserting or changing exact Haunted Dorm mechanics; previous source requests were blocked by proxy 403.
2. **Ghost and survivor AI:** test more human strategies and adversarial room/late-entry situations. Preserve the passing navigation, saving and terminal regressions. Generalize map-specific routing only when a concrete map requirement or failure justifies it.
3. **Economy and upgrades:** collect human difficulty and progression observations. The balanced automated policy wins all sampled rooms, which is not proof of broad human balance. Change prices/rates incrementally and rerun the comparable extended matrix at balance milestones.
4. **Combat and defense:** verify target-platform attack feedback, repair behavior and input responsiveness under sustained combat; add a regression for each discovered defect. Instantaneous visible attack traces are currently functional; projectile travel or wall occlusion are not mandatory missing systems.
5. **Visual quality and balance polish:** improve original art/animation/atmosphere while preserving readability; validate audible sound, Windows display scaling and more aspect ratios. Settings persistence and affordability presentation are smaller follow-ups. Touch/controller/mobile support remains future work.

Known scope limits: one map and hunter archetype, geometric routing, bots spawning at assigned doorways, placeholder visuals, session-local settings, no target-hardware/audio certification and finite automated coverage. See [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md).

## Optimized agent workflow

Use one main agent for routine work. Keep four specialist roles available **on demand**:

| Role | Activate when useful | Ownership |
| --- | --- | --- |
| A — Gameplay Auditor | Major milestone or newly accessible verified reference evidence | Reference/parity review |
| B — Developer | Main routine implementation role; delegate only for a bounded substantive task | One owner for production files |
| C — QA Tester | Major mechanics/AI/economy changes, difficult failures or release candidates | Independent tests and evidence |
| D — Visual Auditor | Important UI/input/rendering changes and available graphics | Actual rendered review and screenshots |

Do not run all four continuously. Give reviewers bounded independent questions, avoid overlapping writes, stop them after delivery, reuse completed research/results, and rerun only relevant checks unless broader regression is justified. Persistent instructions are in [AGENTS.md](../AGENTS.md).

## Exact next-session steps

1. Read this checkpoint, the audit summary and known limitations. Inspect `git status --short`, `git log -5 --oneline` and `git branch -vv`; preserve local work.
2. Check `git ls-remote origin refs/heads/work` against the intended saved commit. Fetch before considering any update; do not reset, force-push or restart the project.
3. Select one roadmap issue with concrete acceptance evidence. The default next milestone is Windows validation/export, not a new gameplay phase or another unrestricted four-agent audit.
4. For local cloud regressions use `bash tools/check.sh`; use `--extended` for balance milestones or release checkpoints. The wrapper configures writable XDG paths. Graphical procedures are in [GRAPHICAL_TESTING.md](GRAPHICAL_TESTING.md).
5. On Windows import `project.godot`, press F5, move with WASD/arrows, press E inside a room, approach its cyan bed and press E again. Click distinct floor tiles, build a turret and Dynamo, watch both resources, upgrade/repair under attack, and verify result/restart/menu behavior. Record actual outcomes rather than assuming the Linux results transfer.
6. Commit validated increments. Push only with authorization, then verify the remote SHA. Do not publicly deploy or publish the game.
