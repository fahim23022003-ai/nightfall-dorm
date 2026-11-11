# Nightfall Dorm

An original single-player Godot 4 dormitory defense game: claim a room, sleep to earn gold, build a defense, and survive the dream hunter. All graphics are original procedural shapes; all sounds are locally synthesized. No third-party game code or artwork is included.

## Run on Windows

1. Install Godot 4.6 stable (standard build, not .NET; tested cloud version 4.6.3).
2. Download/clone this repository and import `project.godot` in Godot.
3. Press F5 or click Run Project. Start Game from the menu.
4. WASD or arrow keys move. Walk through an open door, press **E** inside to claim the room, move near its cyan bed, and press **E** to sleep and lock the door.
5. Click a numbered floor tile; select a building in the right panel. Click an existing building tile and Upgrade selected to improve it. Bed/door upgrades and manual repairs have dedicated buttons. Escape pauses.

You stay in bed for the remainder of the match. Gold starts only when sleeping; dynamos generate electricity. Beds and doors have progression prerequisites; later levels need electricity. Arc turrets require bed level 2. Repair stations cannot restore a destroyed door. Both resources are deducted atomically only on valid purchases.

A hunter arrives after 30 seconds; five bots defend the other rooms. Kill the hunter to win. A breached room exposes its resident; your elimination loses. Sleeping late is dangerous: the hunter pursues an exposed player after an additional 25-second grace period. Restart creates a clean match.

## Cloud development

Use this existing checkout; each cloud task is isolated, so no extra Git worktree is needed. Godot 4.6.3 is installed in the current environment. Home directories may be read-only; give Godot writable XDG directories:

```sh
export XDG_DATA_HOME=/tmp/nightfall-data
export XDG_CONFIG_HOME=/tmp/nightfall-config
export XDG_CACHE_HOME=/tmp/nightfall-cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
cd /workspace/nightfall-dorm
godot --headless --editor --import --quit
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --script tests/simulate_matches.gd
godot --headless --path . --script tests/scene_smoke.gd
```

Run a graphical desktop with `godot --path .` when a display is available. Headless model checks do not establish graphical quality; see the QA and visual reports for actual execution evidence. No package manager or external runtime assets are required.

## Structure

- `project.godot`, `scenes/main.tscn`: application and main scene.
- `scripts/catalog.gd`: original configurable economy, building, and hunter values.
- `scripts/room_state.gd`: atomic purchases, beds, doors, buildings and income.
- `scripts/hunter_state.gd`: explicit finite-state hunter navigation/combat.
- `scripts/bot_ai.gd`: survivor resource and defense strategies.
- `scripts/match_model.gd`: deterministic simulation, room claims, collision, turrets and outcomes.
- `scripts/game.gd`: rendering, camera, input, floating income and sound.
- `scripts/interface.gd`: menu, settings, HUD, purchases and results.
- `tests/`: executable gameplay and scene regression checks.
- `docs/`: design, reference evidence, parity, QA and known limitations.

Original balance values approximate the requested strategic loop; this project does not claim exact Haunted Dorm mechanics or statistics. See `docs/FEATURE_PARITY.md` for the feature review.

## Deliverable status

The playable desktop core passed Godot import/startup, 125 gameplay assertions, 19 scene/input checks, 71 focused audit assertions, 20,000 property-test transactions, and the extended deterministic match suites. Actual Linux graphical interactions and screenshots are documented in `docs/VISUAL_REVIEW.md`. See `docs/QA_REPORT.md` for bugs fixed and exact test scope.

No standalone Windows executable was produced: export templates are not installed. The source project runs through the Godot editor; Windows execution itself remains unverified. No public deployment was made. For a future Windows export install matching official export templates in Godot, add a Windows Desktop preset, and export to a local `builds/` directory.

Run all checks with `bash tools/check.sh`. Cloud setup instructions are retained in `docs/CLOUD_SETUP.md`; the environment draft API failed to confirm persistence, so no published environment configuration is claimed.

## Autonomous audit

The resumed audit is recorded in [AUTONOMOUS_AUDIT_REPORT.md](docs/AUTONOMOUS_AUDIT_REPORT.md): **PASS for the tested playable core**, implementation quality **91.5/100**, exact Haunted Dorm fidelity **UNVERIFIED**. It fixed map clicks, lifecycle transactions, wall tunneling, bot upgrade starvation, hunter retargeting, timestep drift, player statistics and awake-player elimination accounting.

Run `bash tools/check.sh` for regular regression checks or `bash tools/check.sh --extended` to add the 144-run room/seed/strategy matrix and 27 timestep matches. The final matrix produced 72 active victories and 72 passive defeats, with no unresolved runs. A separate rendered automated-player match reached natural victory using ordinary starting resources. See the audit for scope, raw logs, screenshots and limitations.
