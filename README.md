# Nightfall Dorm

An original single-player Godot 4 dormitory survival defense game. Choose a room, sleep to earn gold, upgrade your bed and door, build defenses and electricity production, and defeat the hunter. Five autonomous survivors defend the other rooms. Artwork, characters and locally synthesized sounds are original; exact Haunted Dorm fidelity remains unverified.

**For home testing, download branch [`work`](https://github.com/fahim23022003-ai/nightfall-dorm/tree/work), not `main`.**

## Play in Godot on Windows

1. Sign in to the private [GitHub repository](https://github.com/fahim23022003-ai/nightfall-dorm), select **work**, and choose **Code → Download ZIP**.
2. Extract the complete ZIP. Install/open **Godot 4.6.3 stable, standard build**; no .NET or export templates needed.
3. Choose **Import**, select the extracted `project.godot`, then **Import & Edit**. Wait for asset import.
4. Press **F5 / Run Project**, then **Start Game**. Select an unlocked stage with **Prepare**, choose an optional unlocked boost and difficulty, then **Start Match**.
5. Move with **WASD/arrows**, enter a vacant room and press **E** to claim it. Approach its bed and press **E** to sleep/lock the door.
6. Click an owned floor pad, choose a card, then **Confirm placement**. The preview stays on that pad while you move the mouse to Confirm or Cancel; click another pad to change its position. Start with a Needle turret and build a Dynamo for electricity. Click existing buildings or the bottom bed/door summaries for upgrades. A building inspector also offers Sell: it frees the pad and refunds 50% of the gold and electricity spent on that building and its upgrades (fractional amounts are retained). Bed and door upgrades cannot be sold.

**R** repairs, **M** toggles map/focus, **wheel** zooms, **G** toggles the guide. **Escape** cancels a preview, closes the inspector, then pauses/resumes. Gold starts only while sleeping; later purchases need electricity/prerequisites. Hunter death wins; your elimination loses. Restart/Main menu are on the result screen.

Full controls, ZIP/Git instructions and a practical test checklist: [Windows home testing](docs/HOME_TESTING_WINDOWS.md).

## Stage campaign

Five stages unlock through eligible victories. Stage Select shows completion,
best times and first-clear XP rewards. Next Stage opens preparation; defeat
offers Retry Stage or Change Loadout. Existing rank perks, difficulty options
and save progress are retained. Stages now use distinct dorm, hospital, hotel, laboratory and mansion layouts,
with 10–16 building pads per room. [Map implementation and evidence](docs/PHASE_3B_MAP_REPORT.md).
[Phase3A implementation and evidence](docs/PHASE3A_REPORT.md).

## Current status

**Playable core tested; overall polish PARTIAL.** Six original cartoon room themes, room-focused camera, explicit placement confirmation, five bot identities, hunter finite-state AI, six functional building types, upgrades, repairs, real travelling projectiles/impact damage, victory/defeat and clean restart are implemented. Latest checkpoint/evidence: [PROGRESS_CHECKPOINT.md](docs/PROGRESS_CHECKPOINT.md).

Godot Linux import/startup, automated scene/input/gameplay tests, transactions and seeded matches pass. Prior actual software-rendered screenshots and two complete rendered matches are in [VISUAL_REDESIGN_REPORT.md](docs/VISUAL_REDESIGN_REPORT.md). Native Windows execution, audible output and display scaling remain unverified. Bot/hunter directional animation, small art cleanup and human balancing remain unfinished. Phase2 settings/rank/XP/equipped boosts now persist under `user://profile.json`. One map/hunter, simplified bot arrival and distance-only targeting are documented in [KNOWN_LIMITATIONS.md](docs/KNOWN_LIMITATIONS.md).

Earlier Windows export records are historical; use source branch `work` for current home editor testing. The Android milestone creates a private-test APK as described below; nothing was publicly published/deployed.

## Horror and immersion

Real encounters now show named teammate warnings, rising actual door-damage
numbers, stronger impact/break effects and map danger indicators. Three original
scream variations, destruction reactions, sale/refund cues and eerie ambience
extend the existing sound system to46 local WAVs. Alerts are throttled and ignore
mouse input; Music/Effects/Ambient preferences remain saved.
[Implementation and validation](docs/HORROR_IMMERSION_REPORT.md).

## Phase 2: sound, ranks and hunter intelligence

Original menu/calm/danger music and ambience crossfade with actual hunter proximity and door health. Thirty-seven local original WAV assets provide combat, construction, economy, UI and promotion cues; Settings saves separate Music/Effects/Ambient volumes and mute. No external audio downloads are needed.

Bronze→Silver→Gold→Platinum→Diamond→Master ranks unlock six modest optional boosts. **Ranks & rewards** shows XP, thresholds, unlocked/next rewards; Start Game opens loadout, with one equipped boost per match. Results display performance XP and promotion. `profile.json` uses validated temporary writes, a backup and corrupt-file recovery. Hard/Long night is optional; normal/Night watch preserves the opening threat and ramps later levels smoothly. The hunter now accounts for defenses and escapes repairing-door stalemates without teleporting.

See [Phase2 report](docs/PHASE2_REPORT.md), [audio sources](docs/AUDIO_SOURCES.md), [independent QA](docs/PHASE2_QA_REPORT.md) and [experience review](docs/PHASE2_EXPERIENCE_REVIEW.md). New code is tested in cloud Godot; subjective audio quality and native Windows Phase2 execution remain unverified. No new Windows executable was exported.

## Android private-test build

The same project now includes landscape touch controls, a movement stick, tap-to-room/bed navigation, touch building confirmation/upgrade/repair, scrollable rewards/help, safe-area layouts and background pause/audio handling. Windows keeps its previous keyboard/mouse controls and UI.

A real debug-signed **NightfallDorm_Android_Test.apk** was created at `/workspace/NightfallDorm_Android_Test.apk` (also ignored `builds/android/`). Android7+ ARMv7/ARM64 with GLES3 is the configured target. Signature, manifest, native alignment and packaged resources were verified; **native phone/emulator execution and30/60FPS remain UNVERIFIED**. No Play Store publication or new Windows EXE was made.

[Android report](docs/ANDROID_PORT_REPORT.md) · [Windows SDK/export/install instructions](docs/ANDROID_EXPORT.md) · [independent touch QA](docs/ANDROID_QA_REPORT.md). The APK is a local artifact, not a GitHub-hosted release. Windows and Android saves are separate; no sync exists. Keep the same debug signing key for Android updates, and do not uninstall without considering saved-data loss.

## Cloud development

Continue this existing project; do not rebuild or reset it. Read [AGENTS.md](AGENTS.md) and the checkpoint, inspect Git status, then choose a bounded issue. Use one routine developer with specialist audits on demand.

The cloud requires writable XDG directories:

```sh
export XDG_DATA_HOME=/tmp/nightfall-data
export XDG_CONFIG_HOME=/tmp/nightfall-config
export XDG_CACHE_HOME=/tmp/nightfall-cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
godot --headless --editor --import --quit
bash tools/check.sh
```

`tools/check.sh` runs mobile touch/layout checks plus regular import, gameplay, projectile, UI/input, furniture, availability, transaction, combat-rate and 12 representative-match checks. Add `--extended` for 27 timestep and 144 matrix matches at a balance/release milestone. A display permits `godot --path .`; headless tests alone do not verify graphics.

## Source layout

- `project.godot`, `scenes/main.tscn`: valid application/main scene.
- `scripts/catalog.gd`, `room_state.gd`: configurable balance, resources, beds, doors, building purchases/upgrades.
- `scripts/match_model.gd`, `hunter_state.gd`, `bot_ai.gd`: deterministic rules, projectiles, hunter states and autonomous survivor strategies.
- `scripts/game.gd`, `interface.gd`, `dorm_presentation.gd`: input, camera, menu/HUD, effects and original cartoon rendering.
- `assets/`: local PNGs/fonts and source atlases; no paid/runtime downloads. Font license included.
- `tests/`, `tools/`: executable checks, art preparation and graphical capture tools.
- `docs/`: checkpoint, home instructions, design, QA logs, screenshots and reference limitations.

`.godot/`, `artifacts/` and `builds/` are generated outputs and intentionally ignored. Required scenes/scripts/assets and their resource originals are tracked; Godot regenerates its import cache. Python/Pillow are optional offline art tooling, not game runtime dependencies.

See [art direction](docs/ART_DIRECTION.md), [independent redesign QA](docs/REDESIGN_QA_REPORT.md), [feature parity](docs/FEATURE_PARITY.md), [autonomous audit history](docs/AUTONOMOUS_AUDIT_REPORT.md) and [cloud setup](docs/CLOUD_SETUP.md) for detailed evidence and scope.
