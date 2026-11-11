# Final home-testing checkpoint — 11 November 2026

**Current task complete: source secured, clean-source validation passed, home instructions prepared.** Overall game status remains **PARTIAL — playable core verified, Windows/audio and final polish unverified**. This was a checkpoint/documentation session, not another development phase. No new executable was exported; nothing was publicly released or deployed.

## Source and Git state

- Private repository: `https://github.com/fahim23022003-ai/nightfall-dorm`.
- Correct branch for home testing: **`work`**, not `main`.
- Starting HEAD: `2e6a38aa6a8a2945008f247efe2d802b533cc917`; initial working tree clean. Remote `refs/heads/work` matched that SHA.
- Preserved feature implementation: `f497ca105debe69934fe9fc6c0ed3c8a125d9b44` (cartoon rooms, camera, confirmed placement and impact-time projectiles).
- This final checkpoint commits only instructions/evidence; gameplay was unchanged because validation found no critical failure. The final response identifies the pushed checkpoint SHA. Verify anytime with `git rev-parse HEAD` and `git ls-remote origin refs/heads/work`; a local commit alone is not proof of backup.

## Fresh validation actually executed

Godot **4.6.3.stable.official.7d41c59c4**, Linux headless. A new temporary directory was populated using `git archive HEAD`, then its own `tools/check.sh` ran with writable XDG directories. This tested tracked source without this workspace's `.godot` import cache, ignored builds or untracked files. Import/startup and the whole regular suite exited **0**, with no `SCRIPT ERROR`, `Parse Error` or `ERROR:` signatures. Fresh output: [essential-tests.log](evidence/home-testing/essential-tests.log).

| Check | Actual result |
| --- | --- |
| Project import and configured main scene startup | PASS |
| Gameplay | 126 assertions, 0 failures |
| Projectile flight / independent edge regressions | 22 / 12 assertions, 0 failures |
| Independent actual-input scene UI | 173 assertions, 0 failures |
| Main scene/menu + contextual interface | 23 + 53 checks, 0 failures |
| Furniture/collision and purchase availability | 30 + 3,209 checks, 0 failures |
| Focused gameplay audit | 72 assertions, 0 failures |
| Transaction properties | 20,000 transactions / 175,941 checks, 0 failures |
| Combat rates | 6 scenarios passed |
| Complete seeded matches | 12 completed: 9 victories, 3 defeats; 0 unresolved |

This checkpoint did not repeat the prior extended 183-match or graphical sessions; those results remain explicitly historical below. Prior screenshots/rendered matches are retained in `docs/screenshots/redesign/` and `VISUAL_REDESIGN_REPORT.md`.

## Package completeness

`project.godot` exists and configures `res://scenes/main.tscn`; that scene attaches `res://scripts/game.gd`. All existing scenes, scripts, assets and tests are tracked (1 scene file,16 script/UID files,314 asset/import files,31 test/UID/readme files). Literal production resource references exist and are tracked; no required reference is excluded by `.gitignore`. Fresh-archive import/scene tests also exercise dynamically loaded textures. `.godot/`, `artifacts/`, `builds/` and temporary files are intentionally ignored generated output, not missing game source. See [source-package.log](evidence/home-testing/source-package.log).

## Exact home-testing steps and remaining work

1. Open [HOME_TESTING_WINDOWS.md](HOME_TESTING_WINDOWS.md). Sign in to GitHub, select **work**, download/extract its ZIP (or clone `--branch work`), import `project.godot` into **Godot4.6.3 standard**, wait for import and press **F5**.
2. Test room movement/E claim/E sleep, gold, preview/cancel/confirm, six building functions, electricity, bed/door/machine upgrades, repairs, hunter/projectile combat, bots, both outcomes and restart. Full controls and suggested checks are in the home guide and README.
3. Record actual Windows GPU/display scaling, input feel and audible sound. These remain unverified; prior Linux screenshots do not certify them or human enjoyment.
4. Known scope/polish limits: incomplete bot/hunter directions, small art fragments, session-local settings, one map/hunter, doorway bot starts and distance-only turret targeting. No unresolved critical error was found in the tested paths; tests are finite. Exact Haunted Dorm parity remains unverified because reference access was blocked.
5. Resume development only after home-test evidence or another explicit task. Preserve this branch; use one developer and specialists only for bounded useful reviews. Do not restart the project.

---

# Current checkpoint — cartoon room-camera redesign (11 November 2026)

**Start here.** This continues the existing project on branch `work`, preserving base `57beb7a` and earlier pushed `ac317686f66855e216a03e1cd586506c91b5c995`. The older checkpoint below is retained as history; its fixed overview, instant attacks and old art descriptions are superseded.

**Status: PARTIAL.** Core single-player gameplay and the new camera/placement/projectile paths pass automated checks. Native Windows play, audible audio, final animation polish and independently verified Haunted Dorm fidelity remain outstanding.

## Completed and fixed in this milestone

- Three original cartoon atlases, six room themes, five beds/doors, four-direction player walk, five bot identities/sleep poses, shadow hunter states, turret/support upgrade visuals and matching icon.
- Smooth room-focused camera, strategic M overview, wheel zoom, actual own-door attack attention and optional tutorial.
- Three-by-two illustrated contextual cards, valid/invalid ghost placement, explicit confirmation, free cancellation and separate machine/bed/door inspectors.
- Real simulation-owned travelling projectiles, impact-time damage/statistics, bounded flight/event queues and invalid/expired/terminal cancellation. No decorative fake combat.
- Event-driven build/upgrade/repair/door/impact/income feedback; previous economy and autonomous AI preserved.
- Found/fixed awake-contact victory race, clipped card title, HUD bar overflow, door-sill microtile artifact and sprite backdrop haze. The initial failing regression is recorded, not removed.

## Verification and evidence

`bash tools/check.sh` passed: model126, projectile22, independent projectile edges12, independent actual-input UI173, scene23, contextual UI53, furniture30, availability3209, audit72; 20,000 transactions/175,941 property checks; six rate scenarios; 12 complete representative matches (9 wins/3 defeats), zero unresolved. Final release `bash tools/check.sh --extended` exited0: all checks above passed again, plus27 timestep matches (0 unresolved) and144 matrix matches (72 active victories/72 passive defeats,0 failures). Raw output: `docs/evidence/redesign/final-tests.log`. Final suite executed183 complete headless match runs; the separate pacing12 and rendered2 are documented separately.

Independent pacing: 12 completed matches, 9 active wins/3 passive defeats. Active median purchase interval3.6–7.7s; forced no-affordable-purchase stretch at most4.9s. Long policy-selected saving is not conflated with inability to act or proof of enjoyment.

Actual Xorg/Mesa captures include menu, six room themes, cards, green/red previews, levels, attack warning, flight/impact and both results. Prepared funds/levels/attack setup are explicitly named fixtures. Two normal-fund rendered automated matches completed: active victory, passive defeat. See `VISUAL_REDESIGN_REPORT.md`, `ART_DIRECTION.md`, `REDESIGN_QA_REPORT.md` and `docs/evidence/redesign/`. Headless success does not certify graphics; graphics do not certify human fun or Windows performance.

Windows export rebuilt successfully: `/workspace/NightfallDorm-CartoonRedesign-Windows-x64.zip` (local ignored artifact). Linux loaded its embedded pack from an empty directory and exited0; native Windows remains unverified. Export/pack-smoke logs are committed under `docs/evidence/redesign/`.

## Exact next steps

1. Preserve this checkout. Read this header; inspect `git status --short`, `git log -3 --oneline`, and compare `git ls-remote origin refs/heads/work` with local HEAD. Never reset or rebuild from scratch.
2. Highest priority: run the latest Windows cartoon demo on actual Windows hardware; verify movement into a room, E claim/sleep, confirm/cancel placement, machine/bed/door upgrades, repairs, M/wheel/G, combat, victory/defeat, restart, fullscreen/display scaling and sound.
3. Complete bot directional locomotion and hunter angle coverage; current bot gait is cutout animation. Check room labels, door warnings and build cards at different display sizes. Settings persistence is still absent.
4. Gather human balance/readability observations. Preserve current prices/profiles until evidence justifies a change. Distance-only turret targeting, one map/hunter and bots starting at assigned doorways remain scope limits.
5. Revisit Haunted Dorm comparison only when verified official/reference evidence becomes accessible; earlier proxy403 means exact parity remains UNVERIFIED. Do not invent reference numbers.
6. Use one main developer; bounded Agent C for major mechanics, D for actual rendering, A for newly accessible reference evidence. Do not activate four redundant whole-project reviews.
7. After relevant fixes run focused tests, then `bash tools/check.sh`; use `--extended` at balance/release milestones. Update this checkpoint, commit, push the authorized private branch and verify remote SHA. No public deployment.

## Git record for this milestone

Verified feature/content commit: `f497ca105debe69934fe9fc6c0ed3c8a125d9b44`, pushed to private `origin/work`; `git ls-remote` exactly matched it. See `docs/evidence/redesign/BACKUP_AND_BUILD.md` for actual push output and demo hashes. A documentation-only follow-up records this result; identify the latest tip using `git log -1 --format=%H`. A final verified remote SHA is recorded in the task response and backup evidence. Build ZIPs/EXEs remain local ignored artifacts; source, tests and capture tools are committed. A successful source push is not a GitHub release or hosted binary backup.

---

# Progress checkpoint

Saved: 11 November 2026, Singapore time. This task preserves the completed implementation and audit; it does not begin a new development phase.



## Latest critical visual overhaul

The user's rejection of the programmer-art presentation prompted a substantive rebuild. Pre-overhaul checkpoint `19201bb503ecce78fa09780c1448eb77c864872b`; tested source/art checkpoint `e7a7ab12c6e53290e5ae9501fef9d83bfb9b0b86`. That source checkpoint was pushed to private `work`. Final report/evidence are committed/pushed afterward, and the remote SHA is verified in the completion response.

Original illustrated assets now replace primitive actors, beds, doors and letter machines. Rooms have textured timber/tile, raised walls, furnishings, windows and warm glow/contact shadows. The permanent sidebar is replaced by a top resource/hunter HUD, compact room-upgrade dock, contextual illustrated bottom trays, pause menu and outcome reveal. Sprite-state movement/attack/recoil/death animation is active. Furniture collision was added without changing economy, AI or combat values.

Latest final tests: 125 gameplay, 31 scene/input, 46 overhaul interaction, 30 furniture/reachability, 3,209 availability, 71 audit, 20,000 transaction / 175,941 property checks and six combat-rate scenarios PASS. Twelve representative headless matches completed (9 wins/3 losses); the final graphical capture session additionally completed natural active victory and passive defeat and saved 17 actual viewport images. See VISUAL_OVERHAUL_REPORT.md, VISUAL_OVERHAUL_REVIEW.md and screenshots/visual_overhaul/README.md.

Updated Windows build: `/workspace/NightfallDorm-VisualOverhaul-Windows-x64.zip`. It contains the new art/UI/icon and embedded game data; native Windows execution remains UNVERIFIED. Older ZIPs/screenshots describe earlier builds.

**Status: substantive visual overhaul delivered, commercial finishing PARTIAL.** Next review the new screenshots/build, then prioritize directional animation, character variation, wall/decoration refinement and actual laptop readability/audio. Preserve the model and passing contextual-input/collision tests. Do not restart the project, resurrect the debug sidebar, or call historical functional quality scores final-art approval.

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
