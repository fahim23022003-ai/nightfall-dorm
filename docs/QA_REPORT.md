# QA report — Nightfall Dorm

Executed in Codex Cloud with **Godot 4.6.3 stable**, Linux, on 11 November 2026. This report distinguishes model assertions, real scene integration, simulation outcomes, and graphical review. The automated tests use the production GDScript classes.

## Executed checks

| Requirement | Executed evidence | Outcome |
|---|---|---|
| 01 Project imports | `godot --headless --editor --import --quit`; inspect output for errors as well as process status | PASS, clean final import |
| 02 Main scene starts | Main scene instantiated in `tests/scene_smoke.gd`; main-menu/help/settings/start/result screens exercised through actual Button signals | PASS |
| 03 Room selection | Production movement follows corridor through doorway; E-equivalent `interact()` claims room, walks to bed and sleeps; illegal position and double claim rejected | PASS |
| 04 Bed occupancy income | Unoccupied and eliminated rooms earn zero; sleeping room earns Catalog rate × elapsed time | PASS |
| 05 Bed upgrades | Cost deducted once, higher actual income, missing door prerequisite rejects without deduction | PASS |
| 06 Door upgrades | Maximum HP increases and existing damage is preserved | PASS |
| 07 Invalid purchases | Insufficient gold/electricity, invalid types/tiles, missing prerequisites and missing buildings rejected atomically | PASS |
| 08 Tile placement | Empty in-room tile accepted; out-of-range and occupied tiles rejected; six building types constructed; all 36 tile rectangles stay inside rooms and clear of beds | PASS |
| 09 Turret combat | Out-of-range and dead targets ignored; actual HP damage, cooldown, damage enhancement, upgraded damage and faster attack verified | PASS |
| 10 Hunter navigation | Selects occupied room, changes position toward room; simulations reach doors and terminal outcomes; post-breach EXIT routes through doorway to corridor before retargeting | PASS |
| 11 Door attacks | Actual door HP falls while resident remains alive; attack cooldown prevents immediate repeated strike | PASS |
| 12 Door repairs | Manual and facility healing affect actual HP, clamp to max, cannot resurrect destroyed door | PASS |
| 13 Autonomous bots | Five distinct claimed sleeping rooms; all five spend resources; delayed-player room-trap regression | PASS |
| 14 Electricity | Generator rate, independent purchase requirement and upgrade spending; economy amplifier affects actual income | PASS |
| 15 Victory | Controlled lethal hunter damage triggers victory; natural simulations independently reach victory | PASS |
| 16 Defeat | Actual breach reaches resident and triggers defeat; natural passive simulation independently reaches defeat | PASS |
| 17 Restart | Model reset clears ownership, buildings, result and hunter state; actual Restart Button clears match | PASS |
| 18 Errors/softlocks | Error-scanned final runs, bounded full-match simulations (1,200 simulated second ceiling), menu transitions and pause; an awake player pursued across room entrances reaches defeat within 120 simulated seconds | PASS for tested paths; not an exhaustive proof |

Final gameplay assertion output:

```text
ASSERTIONS=125 FAILURES=0
```

Final scene integration output:

```text
SCENE_CHECKS=11 FAILURES=0
```

The scene test checks handbook content, sound-volume slider callback, active Start Game, pause/time freeze, actual upgrade button behavior, terminal screen transition, Restart and Main menu. It stops sound and waits for audio release during test teardown. Exit is wired to Godot's quit method; its process termination is not exercised inside the same suite. Fullscreen/mouse pointer hit testing and audible sound quality are not established by these headless checks.

## Deterministic full matches

`tests/simulate_matches.gd` runs seeds **7, 8, 99**, each with passive, balanced, guard and economist player automation. It uses ordinary starting funds and production `BotAI` purchase decisions; no additional gold, damage or hunter HP is injected. Each match advances fixed 0.1-second steps and must terminate before 1,200 simulated seconds.

```text
SIMULATIONS=12 WINS=11 LOSSES=1 UNRESOLVED=0
```

Observed baseline outcomes (seconds):

| Seed / player room | Passive | Balanced | Guard | Economist |
|---|---:|---:|---:|---:|
| 7 / room 2 | Victory 81.7 | Victory 81.7 | Victory 81.7 | Victory 81.7 |
| 8 / room 3 | Defeat 46.1 | Victory 67.7 | Victory 67.7 | Victory 67.7 |
| 99 / room 4 | Victory 78.5 | Victory 78.5 | Victory 78.5 | Victory 78.5 |

Room labels above are one-based. Raw logs are authoritative if subsequent balance changes alter exact timing. Passive seed 8 loses one resident; the same starting room survives when its economy and defenses are purchased. Distant passive players can win through bot defenses. This exposes easy location-dependent balance and matches ending before later upgrades/AI profiles diverge substantially. These are tuning limitations, not evidence of exact Haunted Dorm pacing.

## Bugs found and fixed

1. **Player trapped by bot claiming their room.** Seed 11 with player standing inside vacant room 1 while delaying selection reproduced a bot taking and closing that room. Developer excluded the player's current room from bot claims. Regression now passes.
2. **Sound slider rounded to zero before connecting its callback.** Godot HSlider's default integer step rounded initial 0.25 volume to zero, so selecting zero did not update actual volume. Developer set `step = 0.01`; scene regression now passes.
3. **Hunter leaving a breached room could cut through walls.** Developer added an EXIT state that routes via its door and shared corridor; the regression verifies doorway passage before retargeting. Exposed awake-player pursuit also routes through doorways and is tested for a bounded natural defeat.
4. **Beds overlapped build tiles.** Developer shifted the grid; all 36 room/tile rectangles are now checked for bed non-overlap and containment.
5. **Cloud user directories unwritable.** Default Godot data paths generated errors in this managed environment. Coordinator configured writable XDG directories outside the checkout; final commands use them.

An early import occurred before `game.gd` was authored and reported the missing script; it was rerun after implementation. Initial simulations accidentally covered two identical player-room choices (seeds 7 and 31); replacing 31 with 8 exposed the natural-defeat case. Neither intermediate result is presented as final readiness evidence.

## Evidence and reproducibility

From the checkout run:

```sh
bash tools/check.sh
```

Individual commands and scope are documented in `tests/README.md`. Final logs are retained under `artifacts/`: `import.log`, `tests.log`, `scene_smoke.log`, `simulate_matches.log`, `startup.log` (the wrapper refreshes these for each run). The wrapper must fail on Godot nonzero exit or error signatures. Test counts represent assertions, not 125 separate gameplay scenarios.

The full final wrapper returned exit status **0**. A repeat of the 125 gameplay assertions after the last doorway-routing correction also returned **0**. Captured console output is stored in `docs/evidence/qa-final.log`.

Graphical audit and screenshots are independent evidence owned by the visual auditor; see `docs/VISUAL_REVIEW.md` if present. Headless success is **not** proof of graphical presentation. Windows execution/export, physical audio playback, touch input and exhaustive long-session stability remain outside these tests. Exact reference parity remains unverified where reference sources could not be accessed.

Coordinator independently reran the full `bash tools/check.sh` after hunter routing changes: exit 0, 125 assertions, 11 scene checks, and all 12 simulations completed. See [coordinator-final.log](evidence/coordinator-final.log). After the final single-line sidebar text adjustment, scene smoke was rerun: 11 checks, zero failures; see [ui-final.log](evidence/ui-final.log).
