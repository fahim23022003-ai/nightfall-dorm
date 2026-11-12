# Phase 5D-4 independent render/audio acceptance

**ACCEPTED within the tested scope.** Final runtime checkpoint `a4dc1d0e5094825abc3b78b13879c50598f4c047`. Native Windows execution and human judgments remain **UNVERIFIED**. No production edits, commits or pushes were made by Agent D; the parent owns the final delivery and Git verification.

## IMPLEMENTED and observed

Actual viewports/input show the stable bottom build region, direct BUILD, separate exclusive-branch confirmation, compact Items/Help/team controls, numerical current/next comparisons, literal resource prices and unchanged player position/ownership while inspecting or spectating. All six new device types have role art, both real branches and Level 10 indicators. Controlled actual combat shows the three archetypes, eligible once-only transformation, Phase II, real attackable undead, telegraphed casts, phantoms, combined scythe/Crimson domain, NPC-target navigation and cleanup.

The final affected frames show persistent burn tongues and HP/s badge, actual Decoy aura/countdown, Shield arc and actual +healed-HP pulse. Reduced Effects changes presentation. Frost now accurately distinguishes capped Hunter movement from attack interval and undead movement. Full Reaper hood/robe/scythe and below-body feedback fit the fixed camera region; Home stays available while the roster is expanded. Integer HP display was corrected without altering the saved/combat values.

## TESTED

| Gate | Checks / failures | Raw log |
| --- | --- | --- |
| Baseline render | 53 / 0 | `baseline/render-initial.log` |
| Early full UX | 301 / 0 | `early-render-accepted.log` |
| Early final branch clarity | 209 / 0 | `early-render-clarity.log` |
| Early paired actual audio | 76 / 0 | `early-audio-accepted.log` |
| Six new buildings/both branches/paid L10 | 555 / 0 | `core-render-buildings-initial.log` |
| Controlled boss phases/casts | 117 / 0 | `core-render-boss-accepted.log` |
| Archetypes/evolution reset fix | 37 / 0 | `core-render-status-accepted.log` |
| Listening Room input | 189 / 0 | `core-listening-initial.log` |
| Final actual weapon PCM | 38 / 0 | `core-final-audio-weapons.log` |
| Final three-evolution PCM | 10 / 0 | `core-final-audio-evolution.log` |
| Final boss/Crimson/menu PCM | 37 / 0 | `core-final-audio-boss.log` |
| Final genuine breach/reaction PCM | 9 / 0 | `final-d-audio-breach.log` |
| Final actual defense FX/Frost/costs | 99 / 0 | `final-d-feedback-accepted.log` |
| Final NPC domain navigation/framing | 19 / 0 | `final-d-arrival-accepted.log` |
| Final own Phase II framing | 9 / 0 | `final-d-own-phase2.log` |
| Genuine earned all-six-L10 inspection | 141 / 0 | `final-d-earned.log` |
| Affected integer HP display | 45 / 0 | `final-d-earned-hp.log` |
| Final all-five-map teammates | 293 / 0 | `final-d-team.log` |
| Final committed-source 600s dense | 764 / 0 | `final-d-dense.log` |

The accepted aggregate is 3001 checks, including image/PCM writes and UI input checks; this is not a claim of that many unique gameplay scenarios. `final-d-manifest.json` records exact per-image, log, source and audio hashes, plus older source groups. It deliberately does not rebind earlier screenshots to a later commit.

**Genuine late-game evidence:** two Agent A canonical checkpoints were resumed through the real UI, with all six new machines and Arc/Bed/Door at Level 10. The isolated GUI copies changed only tutorial completion. Canonical bytes, actual investment ledgers, buildings and remaining resources were unchanged by inspection. These demonstrate the genuinely earned state; the separate 20k/5k Practice branch tests are temporary-budget transaction/visual fixtures, not natural economy proof.

**Actual PCM:** 18 final engine Master recordings total 132.725 seconds and have zero clipped samples. They include Needle, Arc, Flame, Frost, Shock, three genuine kill/evolution sequences, real legal door break/Breach navigation/death/evolution/laugh, eligible transformation, ten-agent assault, Scythe Slash, Rules Judgement, Soul Reaper, Phantom Scream, actual 10% Crimson music transition and menu cleanup. These use real Game/model/input producers, rather than only isolated audio previews. Main Hunter id1 now routes its own hurt sound; undead IDs use their own route. Seven prior music WAV hashes remain identical to baseline. Master recordings—not pre-fader bus stems—are the actual mixed-output evidence.

**Final source endurance:** 600.4 simulated seconds completed in 115.766199 accelerated wall seconds, through eight Game._process(0.05) calls per rendered frame. This is followed and preceded by separate real-time eight-second max Music1/Effects1/Ambient0.5 windows. The fixture has 72 actually purchased Level10 machines/30 weapons, up to ten actual navigable/attackable agents, deliberately large temporary resource/HP budgets and suppressed random percent-max-HP casts so it isolates object/audio lifecycle. Full actual boss attacks and natural balance are tested separately.

Sampled pools remained bounded: minions0–10, projectiles1–17, combat events2–37, presentation events128, visual effects6–21, floating numbers6 and navigation routes2–12. Nodes165 and resources249 stayed constant. Static memory started at 100,675,124 bytes, peaked at 101,302,118, and finished at 101,264,000 (+588,876 bytes from the start, including warm caches). This bounded600s observation is not proof of unlimited-session memory safety.

The real-time start/end windows measured mean61.280/54.484ms and p95 80.026/63.671ms on Linux Mesa software rendering under the artificial density. They are not native Windows GPU performance measurements. Actual maxmix Master RMS was0.031064/0.034584, peak0.186310/0.170532, with zero clipped samples. `final-d-metrics.json` supplies exact PCM durations, event counts and hashes.

## Failures and fixes preserved

Product findings included branch text/close-button overlap; missing main-HUD Wrath countdowns; awakening/spectator/world-frame obstruction; evolution event cursors surviving same-model new-session resets; main-Hunter audio misclassification; missing persistent burn/lure/heal feedback; overstated Frost movement text; clipped literal price text; foot/status crop; and integer HP flooring. The primary developer/audio owner fixed these, and affected actual input/raster/PCM checks were rerun. Parent-owned tests also corrected Legacy focus and mobile callback preservation.

Rejected harness diagnostics remain intact: unsettled UI clicks, duplicate inherited variable parse failure, a legitimate193s death in an inadequately isolated endurance fixture, a65s wall cap that stopped a healthy344.8s run, and an NPC-domain fixture that hit the next threshold before its legitimate1.2s guard expired. None is presented as a successful600s run or an unresolved production failure. The final accepted run completed600.4s.

## UNVERIFIED / INCOMPLETE

Native Windows launch/controls, soundcard/headphone output, subjective music/gunfire/voice quality, scariness and human usability remain UNVERIFIED. Actual PCM signal, event/state correlation and unclipped samples do not substitute for human listening. Dense Linux software timing does not establish Windows performance. No confirmed D finding remains unresolved in the tested scope. Full phase feature acceptance, complete regression results, export integrity and actual GitHub push status are in the parent report; no Phase6 work was started.

Representative unedited frames: `core-render/final-bottom-door-burn-720.png`, `core-render/final-frost-current-next-720.png`, `core-render/final-npc-crimson-arrival-720.png`, `core-render/final-own-reaper-phase2-720.png`, `core-render/earned-normal-six-new-level10-world-720.png`, `core-render/dense-after600simulated-seconds-720.png`.
