# Nightfall Dorm

An original single-player Godot 4 dormitory survival defense game. Choose a room, sleep to earn gold, upgrade your bed and door, build defenses and electricity production, and defeat the hunter. Five autonomous survivors defend the other rooms. Artwork, characters and locally synthesized sounds are original; exact Haunted Dorm fidelity remains unverified.

**For home testing, download branch [`work`](https://github.com/fahim23022003-ai/nightfall-dorm/tree/work), not `main`.**

## Play in Godot on Windows

1. Sign in to the private [GitHub repository](https://github.com/fahim23022003-ai/nightfall-dorm), select **work**, and choose **Code → Download ZIP**.
2. Extract the complete ZIP. Install/open **Godot 4.6.3 stable, standard build**; no .NET or export templates needed.
3. Choose **Import**, select the extracted `project.godot`, then **Import & Edit**. Wait for asset import.
4. Press **F5 / Run Project**, then **Start Game**.
5. Move with **WASD/arrows**, enter a vacant room and press **E** to claim it. Approach its bed and press **E** to sleep/lock the door.
6. Click an owned floor pad, choose a card, then **Confirm placement**. Start with a Needle turret and build a Dynamo for electricity. Click existing buildings or the bottom bed/door summaries for upgrades.

**R** repairs, **M** toggles map/focus, **wheel** zooms, **G** toggles the guide. **Escape** cancels a preview, closes the inspector, then pauses/resumes. Gold starts only while sleeping; later purchases need electricity/prerequisites. Hunter death wins; your elimination loses. Restart/Main menu are on the result screen.

Full controls, ZIP/Git instructions and a practical test checklist: [Windows home testing](docs/HOME_TESTING_WINDOWS.md).

## Current status

**Playable core tested; overall polish PARTIAL.** Six original cartoon room themes, room-focused camera, explicit placement confirmation, five bot identities, hunter finite-state AI, six functional building types, upgrades, repairs, real travelling projectiles/impact damage, victory/defeat and clean restart are implemented. Latest checkpoint/evidence: [PROGRESS_CHECKPOINT.md](docs/PROGRESS_CHECKPOINT.md).

Godot Linux import/startup, automated scene/input/gameplay tests, transactions and seeded matches pass. Prior actual software-rendered screenshots and two complete rendered matches are in [VISUAL_REDESIGN_REPORT.md](docs/VISUAL_REDESIGN_REPORT.md). Native Windows execution, audible output and display scaling remain unverified. Bot/hunter directional animation, settings persistence, small art cleanup and human balancing remain unfinished. One map/hunter, simplified bot arrival and distance-only targeting are documented in [KNOWN_LIMITATIONS.md](docs/KNOWN_LIMITATIONS.md).

This home checkpoint does not create another executable or publish/deploy anything. Earlier export records in the documentation are historical; use source branch `work` for home editor testing.

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

`tools/check.sh` runs regular import, gameplay, projectile, UI/input, furniture, availability, transaction, combat-rate and 12 representative-match checks. Add `--extended` for 27 timestep and 144 matrix matches at a balance/release milestone. A display permits `godot --path .`; headless tests alone do not verify graphics.

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
