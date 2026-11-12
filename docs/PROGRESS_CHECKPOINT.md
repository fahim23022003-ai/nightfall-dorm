# Phase 3B — five maps and expanded building space (12 November 2026, Singapore)

Continued clean `work` at `788442c72edb46051f825daff9734b3f9e9ffa2e`.
Recovery tag `pre-phase3b-788442c`; full Phase3A baseline passed before editing.

Stage assignments: abandoned dorm (12 pads), hospital (10/12), hotel (10),
laboratory (12), mansion (10/16). Distinct room sizes/positions, corridor graphs,
door directions, entrances, themed original decoration/floors/lighting and build
layouts replace the shared map. Maps are data-driven and reusable by future
stages; no later-stage features were added.

Implemented variable-capacity purchase/sale/refund/UI, anchored preview and bounds-
fitted camera. Separate collision-safe player and cached AI navigation supports
all rooms and side doors without teleportation. Bots walk from corridor spawn
to their claimed beds, earn/build/upgrade under existing AI. Wider maps retain
attenuated teammate sound. Campaign/loadout/ranks/saves/perks remain compatible.

Confirmed and fixed player paths crossing beds and too-wide doorway connectors,
plus tutorial covering bed/side door during building. Real retests passed.
No price/DPS/door-stat nerfs without evidence: paid extra-slot strategies have
range/opportunity-cost tradeoffs. Human balance remains unverified.

Final regular wrapper: core15,348 checks, independent integration5,107, UI922;
144 map matches84W/60L/0unresolved, campaign20matches10W/10L, legacy12matches9W/3L;
all Phase1/2/3A save/load/perks/audio/AI/combat/property tests and main startup
passed. Separate independent72-match balance probe retained. Actual Linux render
audit201checks/18screenshots covers5environments, every representative pad,
highest-pad buy/sell/refund, lab side doors and both mansion capacities.
Map-load samples approximately0.33–0.49seconds in cloud, not Windows FPS.

Full report: [PHASE_3B_MAP_REPORT.md](PHASE_3B_MAP_REPORT.md).
Evidence: `docs/evidence/maps/`; reproducible `tools/capture_maps.gd`.
No known remaining failures in tested paths. Native Windows, subjective audio,
human balance and target hardware performance remain UNVERIFIED.
Project/Windows export config unchanged; no Android/APK/Phase4 work.

Final response reports exact committed/pushed SHA after remote verification.
Next: download latest `work` and playtest new stages on Windows Godot4.6.3,
including manual room entry/bed approach, side doors, expanded construction,
sell/rebuild and stage transitions. Stop after Phase3B pending user direction.

---

# Phase 3A — stage progression and loadout flow (12 November 2026, Singapore)

Continued clean `work` at `76c1e393838c4930918fb787eb540dea7d78bfb3`.
Recovery tag `pre-phase3a-76c1e39`; previous content remains in history.

Five configurable persistent campaign stages now replace normal Windows menu
restart flow. Stage Select shows locks/completed/best/reward/difficulty;
preparation reuses existing ranked perks. Next Stage opens next preparation,
Retry keeps the correct stage/difficulty, Stage5 ends with Campaign complete.
Stage modifiers compose with Normal/Long night; all stages retain original map.
Legacy saves migrate additively; selected stage/difficulty, completion records,
derived highest unlock, existing loadout/ranks/XP/settings persist. First-clear XP
is once-only; locked stages/perks, invalid settlements and duplicate grants guarded.

Final regular wrapper exit0: campaign85profile/54independentflow checks;
20campaignmatches10W/10L/0unresolved across5stages/bothdifficulties. Actual child
Godot save/write/read processes passed. All Phase1/2, rank/save348, UI/input,
AI/combat/property tests,12representativematches9W/3L and main startup passed.
Real Linux render audit57checks/19captures: stage select, all perks, next/retry,
records/completion, hard XPcap and actual savefailure/retry. Fixed result summary
and save-retry overlap plus false-success failedstart return path.

Evidence and full scope: [PHASE3A_REPORT.md](PHASE3A_REPORT.md),
`docs/evidence/campaign/`. Native Windows and human balancing remain UNVERIFIED.
Windows project/export config unchanged. No Phase3B/Phase4/Android work.
Final response records exact committed/pushed SHA after remote verification.

Next: playtest latest `work` on Windows Godot4.6.3, especially a natural stage
clear → Next Stage → prepare, replay, defeat/retry and restart persistence.
Stop here pending user direction; do not begin later phases automatically.

---

# Nightfall Dorm 3.0 — Phase 2 horror/immersion (12 November 2026, Singapore)

Continued clean `work` at `f66c0265440b9ce46f27e13ec039070bd696ffea`.
Recovery: local tag `pre-horror-phase2-f66c026` and preserved Git history.
Phase1 anchored placement and exact50% paid-investment refunds remain intact.

Implemented exact event-driven door damage numbers/shake/red flash/cracks and
destruction; genuine prioritized/animated teammate danger alerts with stable
survivor names; bounded map indicators; three original scream variations with
encounter cooldowns/no overlap; destruction reaction, sale/refund, separate
resource-failure and eerie cues. Existing music/proximity crossfades,37 original
sounds, saved volume preferences, AI/economy/rank rules and save schema preserved.
All46 audio resources import. Notifications ignore input and avoid build controls.

Verification: full regular `tools/check.sh` exited0 (new319 independent events,
5UI failures,17feedback; existing157audio,314/421Phase1,221camera/UI; all other
suites,20ktransactions/175941invariants,6rate scenarios,12matches9W/3L,
separate-process saves and main startup passed). Final alert-escalation polish
and rapid-hit label merging then passed21feedback checks. No unresolved tested failures. Fixed event-relay
reference cycle, terminal audio omission and stale lower-priority notifications and rapid-hit label overlap.

Agent B primary development; specialist audio/visual implementation, independent
Agent C QA and actual Agent D render/mix inspection used at bounded milestones.
Real Linux render fixtures and non-silent/unclipped engine mix are retained in
`docs/evidence/horror/`. Native Windows, subjective listening and target-device
performance remain UNVERIFIED. Windows export/project settings unchanged.
No Android SDK/APK or future phases. Full scope/evidence:
[HORROR_IMMERSION_REPORT.md](HORROR_IMMERSION_REPORT.md).

Next: download latest `work` and playtest on Windows Godot4.6.3: far teammate
encounters, player low-health door, construction/sale/repair, volume controls and
both outcomes. Preserve progression/saves; do not start later features.
Final response records the actual committed/pushed SHA after remote verification.

---

# Phase 1 PC placement correction — anchored preview (12 November 2026, Singapore)

Continued `work` at `4f336c60086c8aee8be1b125fe442d432e2ceaed`.
The user's PC playtest clarified that the main reported bug was the preview
following the mouse to Confirm/Cancel, not just duplicate button activation.
Earlier completion evidence did not cover travel across the map between buttons.

Reproduced before the fix using actual InputEventMouseMotion and button events:
`tests/redesign_ui.gd` exited 1 with 24 failures out of 209 checks. Hovering
over map space or another pad changed placement validity/target, preventing
purchase on the selected pad even after moving to Confirm.

Removed mouse-motion relocation. Selecting a card now anchors the preview to the
selected pad. Move the pointer freely to Confirm/Cancel; click a different floor
pad to explicitly change position. Confirmation remains required and single-use.
Clicking invalid map space still gives a recoverable invalid preview. Existing
double-click protection, cancellation, refunds and Windows keys are preserved.
README and confirmation help describe this behavior.

Regression tests cover all six building types: double-click a card, move across
out-of-room map space and another pad, then Confirm or Cancel. They check the
locked target, enabled confirmation, exact single charge, no-charge cancellation,
and retain existing click-to-relocate/invalid-target/recovery tests.
Focused reproduction after removing mouse-follow passed 209 checks, zero failures.
Final expanded UI suite: 221 checks, zero failures. Full regular wrapper exited 0,
including 314 developer/421 independent Phase 1 checks, 12 matches (9 wins/3
defeats, zero unresolved), save persistence and main startup. No script/parse/error
signatures. The new Cancel fixture initially needed an explicit UI refresh because
it freezes automatic processing; corrected fixture passes without weakening checks.
Native Windows Godot execution remains unverified here; the tests exercise
the real Linux Godot scene/input pipeline, not a simulated UI implementation.

Continue on `work`; no Phase 2 work or balance changes. The final response records
the exact commit and independently verified remote SHA after the authorized push.

---

# Phase 1 quality completion — building purchases and refunds (12 November 2026, Singapore)

Continued existing `work` commit `1a9e0068d079b029c486402e13326afb5463ebf9`;
the last reported reference and verified remote starting point was
`1753c91705c9c58192968961e246d23542909649`. Main was not changed.

**Implementation and automated verification: COMPLETE.**

## Completed behavior

- The second mouse double-click press and release are consumed before UI
  dispatch. Purchase confirmation is single-use: successful placement clears
  pending intent before another callback can purchase or charge again.
- Cancel, Escape/Android Back, inspector close/switch, pause, menu/restart and
  match result clear pending placement. Invalid previews remain recoverable on
  a valid pad; invalid/paused/terminal placement requests cannot buy.
- Desktop/mobile building inspectors offer Sell with a separate gold/electricity
  quote. Each building records actual successfully paid original and upgrade
  gold/electricity investment. Sale refunds exactly 50% of each accumulated
  investment, retaining fractions. Failed upgrades add no investment; unpaid
  fixtures gain no fabricated refund. Beds and doors cannot be sold.
- Sale removes the building before crediting resources. Duplicate, invalid,
  paused, terminal and eliminated-resident sales cannot grant resources.
  Pads can be reused immediately. Repeated purchase/sale cycles cannot profit.
- No changes to balance prices, AI, audio, rank rules or profile save format.
  Existing keyboard/mouse controls remain available.

## Development and independent verification

Main agent served as Agent B, with genuine Agent C independently testing bounded
Phase 1 paths. No Agents A/D were needed. Agent C found the hidden pending state
on match result; review also replaced inferred refunds with paid investment
records and fixed inspector-switch/close cleanup.

`bash tools/check.sh` includes both committed Phase 1 suites:
314 developer checks and 421 independent checks. They exercise all six building
types and all four levels, separate resource accounting, rejected upgrades,
duplicate purchases/sales, repeated buy/sell cycles, tile reuse, actual desktop
mouse events, real touch plus mouse emulation, Cancel/Escape/Back, invalid-preview
recovery and result/pause/inspector cleanup.

The regular suite also verifies model126, mobile52/layout196, audio139,
rank/save348, Phase2UI52/hunter39, projectiles22/edges12, camera/UI173,
scene24, contextualUI53, furniture30, availability3209, audit72,
20,000 transactions/175,941 invariants, six combat-rate scenarios,
12 deterministic matches (9 wins/3 defeats/0 unresolved), separate-process
profile persistence and main startup. Test counts are distinct measures, not a
combined count of gameplay scenarios. Logs are generated under ignored
`artifacts/`; final regular validation exited 0, both Phase 1 suites had zero failures,
and MAIN_STARTUP=PASS MODE=menu. No script/parse/error signatures were found.

No known remaining Phase 1 bug in these tested paths. Native Windows/Android,
audible output and rendered appearance remain unverified in this task.
The extended balance matrix was not rerun: no balance/rule-rate changes.
No Phase 2 or future features were started.

## Commit and private backup

The user explicitly authorized commit/push to the existing `work` branch.
After the final test pass, commit without changing branches, push `HEAD:work`
without force, and verify `git ls-remote origin refs/heads/work` equals local
full HEAD. The final response records the exact verified pushed commit; this
pre-commit checkpoint text alone is not evidence of a successful push.

---

# Latest checkpoint — Android shared-source port (11 November2026, Singapore)

**Continue here; do not rebuild or remove the Windows game.** Started from private `work` at `0de14345e6f4f66f027fd1038a82a6278947eca3`, with recoverable tag `pre-android-2026-11-11`. The old Phase2 checkpoint below is history. Windows preset0 is byte-identical, and core economy/AI/door/turret/rank rule files are unchanged.

**Status: PARTIAL — mobile implementation and real signed debug APK ready for private phone testing; native Android execution/performance unverified.**

## Completed

- Android-specific touch input, visible movement stick and Interact/Bed controls; tap-room corridor navigation and claim, tap-bed approach/sleep, real floor preview/confirm/cancel, building/bed/door upgrade/repair and on-screen map/help/pause.
- Larger mobile menus/inspectors/result/pause, scrollable reward/help lists with drag cancellation, visible blocked-card reasons, aspect-preserving safe-area layouts for16:9/19.5:9/20:9. Windows keeps its keyboard/mouse interface.
- Mobile background/focus handling saves, clears movement, freezes simulation and pauses audio. Resume restores streams without restarting music and waits for explicit Resume. Settings/ranks/equipped rewards retain existing user:// persistence; Windows/Android saves are separate, no sync.
- Mobile20Hz HUD updates,10 effect voices versus16 desktop, requested60FPS or battery-saver30FPS; no device achievement claim.
- Android SDK/template setup, original launcher icons, GLES3/Compatibility override and required texture import flag. Android Test preset retains the Windows preset. No keys/passwords or generated APKs enter Git.
- Real `/workspace/NightfallDorm_Android_Test.apk` created (also ignored builds/android), packageorg.nightfalldorm.game, AndroidAPI24–target36, ARMv7/ARM64, landscape, debug signed, offline permissions. Static signature/resource/ABI/16KB alignment/manifest verification passed. Exact SHA/bytes: `docs/evidence/android/APK_MANIFEST.json`. No Windows EXE or store deployment was made.

## Actual verification

Unmodified baseline regular suite passed first. Final regular suite also passed:52 mobile touch/lifecycle and196 layout checks; model126, audio139, rank/save348, Phase2UI52, hunter39, projectile22, edges12, camera/UI173, scene24, contextual UI53, furniture30, availability3209, audit72;20k transactions/175941 property checks;6 rate scenarios;12 matches9W/3L; separate-process persistence and actual-main startup. No final script-error signatures. Old extended matrix results remain historical, not new Android runs.

Independent Agent C exercised real ScreenTouch/ScreenDrag, joystick/multitouch, movement/claim/sleep, single-charge purchases, cancel/Back, upgrade/repair, swipe scrolling from buttons, paused/resumed audio and saved frame caps. Independent D reproduced and verified fixes for close-card overlap and bed-radius interception of a pad edge; reviewed real layouts. SDK specialist B built/verified actual APK probes; main integrated and generated the final named APK.

Nineteen actual Linux/Mesa mobile-preview captures include all aspect ratios, synthetic asymmetric safe area, menu/loadout/build/confirm/pause/settings/scrolled rewards/resumed pause and no-XP result. They are prepared fixtures, not Android hardware or natural-match proof. Logs show3/3 music starts and10 mobile voices after resume. Headless host profiling completed12 more normal/hard balanced matches, mean89.68μs model step, peak6 projectiles; this is not device FPS. PNG capture/software preview rates were10–17FPS under capture overhead, not a phone performance result.

Evidence: `docs/ANDROID_PORT_REPORT.md`, `ANDROID_QA_REPORT.md`, `ANDROID_EXPERIENCE_REVIEW.md`, `ANDROID_EXPORT.md`, and `docs/evidence/android/`. Feature/content commit `b80e75e1ccc75bb451dae0158a262b32804a7ad5` and the pre-port recovery tag were pushed and remote SHAs verified. See `docs/evidence/android/BACKUP.md`; final response reports the verified documentation follow-up tip. APK remains a local downloadable artifact; source/tools/evidence are backed up privately.

Final packaged-project check: extracted Godot assets from the actual delivered APK and ran Linux Godot against those exported resources/bytecode. Main startup,52 touch/lifecycle checks and196 layout checks passed without workspace resource dependencies. This is not native Android ABI/OS execution. See `packed-project-*.log`.

## Exact next steps

1. Inspect Git status/log and remote `refs/heads/work`; preserve completed code. Recoverable pre-port commit/tag above retain the previous Windows version. Do not reset or force-push.
2. Download the final named APK, verify its SHA and install on a private ARM Android7+ GLES3 phone. The SDK/manifest/signature pass is **not** an Android launch pass. There was no emulator/KVM/phone here; adb also could not create its default read-only home config.
3. Test movement→room→bed→economy→build/upgrade/repair→hunter→both results/restart, rank/rewards/settings, long-menu swipe and accidental double-charge prevention. Test lock/background/resume and audio continuity; match should remain paused until Resume.
4. Record model/Android version, safe-area/cutout behavior, actual FPS/memory/thermal results and physical target comfort. Adjust performance only from real measurements;30/60 are cap requests so far.
5. Pull the same work branch into Windows Godot4.6.3 and F5 to retest native desktop behavior. Automated Windows-path checks pass, but this port has not been executed natively on Windows in cloud.
6. For local Android exports follow ANDROID_EXPORT.md. Keep SDK/JDK paths and signing keys outside Git, retain the same key/package for updates, and do not uninstall casually (private saves are removed). No cross-platform save sync exists.
7. Stop this milestone here pending device feedback. Preserve rules/art/audio/progression. Future changes should use one developer with bounded independent QA/UI reviews, not another whole-project rebuild.

---

# Latest checkpoint — Phase 2 functional delivery (11 November 2026, Singapore)

**Read this first. Do not restart or redesign the game.** Continued `work` from `ad0e95e2d6c9b435074939f73e7e60fc579a680a`; all loved baseline gameplay/art/economy features were preserved. The pause/continue interruption left completed Phase2 files and test logs in the working tree; those were reviewed and finished, not regenerated. Older headers below are historical.

## Implemented and validated

- **Audio:**37 original local PCM assets, separate menu/calm/danger music, proximity/room/generator ambience, distinct combat/build/economy/UI/rank cues, saved Music/Effects/Ambient/mute controls, smooth non-restarting loops, bounded voices/cooldowns and reliable critical-cue priority/retry. Actual mixed-engine WAV is non-silent/unclipped; no listening verdict is claimed.
- **Progression:**Bronze→Master ranks and six original badges, menu XP/next goal, progression/reward collection, configurable one-slot loadout, six small functional boosts, immutable match snapshot, transparent performance XP/promotion summary and local persistent settings/progress.
- **Save safety:**validated temporary generation, valid backup, corrupt input preservation/recovery, future-schema read-only protection, strict nested types/IDs/loadout chronology, duplicate settlement prevention, write-failure warning/retry and lifetime-XP cap handling. Separate-process write/read proves persistence beyond one process.
- **Hunter:**normal opening preserved for45 active seconds, later stats smoothly ramp over8s per level; capped movement/rate changes, opt-in hard mode, bounded defense-aware scoring, siege-stalemate escape, near-breach commitment and non-teleporting recovery. Door protection and corridor geometry retained.

## Genuine verification

Godot4.6.3 stable, Linux. `tools/check.sh --extended` passed all suites and **231 complete headless matches**:12 representative,27 timestep,144 ordinary matrix,48 new rank/difficulty matrix. New matrix:24 active wins/24 passive defeats, zero unresolved. A final regular rerun after integration/cleanup also passed; repetitions are not additional unique scenarios.

New audio139, ranked348, actual-input Phase2UI52, hunter39 assertions pass. Existing model126, projectile22, edge12, camera/UI173, scene24, contextual UI53, furniture30, availability3209, audit72,20k transactions/175941 checks and6 rate scenarios pass. The later focused UI rerun verifies the final configurable-slot display. Separate-process profile write/read passes. Fresh import and graceful main startup pass. Logs: `docs/evidence/phase2/regular-final.log`, `extended-final.log`, `ui-final-focused.log`.

Actual graphical checks:seven new menu/settings/rewards/loadout/threat/promotion screenshots; prepared rank/promotion/hunter fixtures are explicitly labeled. Corrected Last light text was visually checked after a width-only fix proved insufficient. Two additional normal-fund rendered automated matches completed: active victory~128.2s earned161XP; passive defeat~41.7s earned4XP. Both awards reloaded from disk successfully. The natural matches did not gift resources or force a terminal result. Output: `natural-render.log`; screenshots08–10.

Bugs fixed include malformed save snapshots/replay IDs, max-XP save rejection, critical sound drops, repairing-door hunter stalemate, wrong quit-handler property ownership and reward-description overlap. Initial failing evidence remains labeled in the evidence folder. Normal quit and tests drain audio to release playback resources; forced abrupt engine termination is not equivalent to a normal quit test.

## Status and remaining work

**Functional Phase2 systems implemented and tested. Windows Phase2 playback, subjective audio polish and long-term human balance remain UNVERIFIED.** The user reported baseline Windows gameplay success; cloud has not run this new revision natively on Windows or listened through speakers. Local offline ranks are not an online leaderboard/anti-cheat service. Existing bot/hunter directional limits, one map/hunter, distance-only targeting, small art fragments and other-aspect-ratio/accessibility work remain.

No new Windows executable export, paid service, public release or deployment was performed. Previous ZIP/EXE artifacts predate Phase2; test latest source in Godot.

## Exact next steps

1. Inspect Git status/log and compare local HEAD with `git ls-remote origin refs/heads/work`. Feature commit `22de43d156710f6a0b07bd02010c3181e5715e62` was pushed and GitHub SHA verified. A clean Git-only archive then imported and started successfully. See `docs/evidence/phase2/BACKUP.md`; final task response identifies the verified documentation follow-up tip. Do not reset, force-push or rebuild from scratch.
2. At home pull/download private **work**, import `project.godot` into Godot4.6.3 standard, F5, **Start Game → loadout → Start Night**. Test Night watch first with no perk; optionally equip Pocket change. Ranks & rewards shows every unlock/threshold.
3. Listen to menu/calm/danger/proximity/combat/breach/outcome cues; adjust independent volumes/mute. Verify rank/XP/equipped/settings after closing/reopening. Windows normally saves `%APPDATA%\Godot\app_userdata\Nightfall Dorm\profile.json`; back it up before deliberate recovery tests.
4. Try normal/hard and report actual human difficulty/rank pacing. Avoid further balance retuning without evidence; current bonuses are modest and do not guarantee victory in passive simulations.
5. Read `PHASE2_REPORT.md`, `AUDIO_SOURCES.md`, `PHASE2_QA_REPORT.md`, `PHASE2_EXPERIENCE_REVIEW.md` and updated `HOME_TESTING_WINDOWS.md`. Preserve tested code. Use one routine developer and bounded specialists when new evidence justifies them.

---

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
