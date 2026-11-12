# Nightfall Dorm

An original single-player Godot 4 dormitory survival defense game. Choose a room, sleep to earn gold, upgrade your bed and door, build defenses and electricity production, and defeat the hunter. Five autonomous survivors defend the other rooms. Artwork, characters and locally synthesized sounds are original; exact Haunted Dorm fidelity remains unverified.

**For home testing, download branch [`work`](https://github.com/fahim23022003-ai/nightfall-dorm/tree/work), not `main`.**

## Play in Godot on Windows

1. Sign in to the private [GitHub repository](https://github.com/fahim23022003-ai/nightfall-dorm), select **work**, and choose **Code → Download ZIP**.
2. Extract the complete ZIP. Install/open **Godot 4.6.3 stable, standard build**; no .NET or export templates needed.
3. Choose **Import**, select the extracted `project.godot`, then **Import & Edit**. Wait for asset import.
4. Press **F5 / Run Project**. Watch or skip the opening; a fresh save completes the guided practice first. Then choose **Start Game** and select an unlocked stage with **Prepare**, choose an optional unlocked boost and difficulty, then **Start Match**.
5. Move with **WASD/arrows**, enter a vacant room and press **E** to claim it. Approach its bed and press **E** to sleep/lock the door.
6. Click an owned floor pad, choose a card, then **Confirm placement**. The preview stays on that pad while you move the mouse to Confirm or Cancel; click another pad to change its position. Start with a Needle turret and build a Dynamo for electricity. Click existing buildings or the bottom bed/door summaries for upgrades. A building inspector also offers Sell: it frees the pad and refunds 50% of the gold and electricity spent on that building and its upgrades (fractional amounts are retained). Bed and door upgrades cannot be sold.

**R** repairs, **M** toggles map/focus, **wheel** zooms, **G** toggles the guide. **Escape** cancels a preview, closes the inspector, then pauses/resumes. Gold starts only while sleeping; later purchases need electricity/prerequisites. Hunter death wins; your elimination loses. Restart/Main menu are on the result screen.

Full controls, ZIP/Git instructions and a practical test checklist: [Windows home testing](docs/HOME_TESTING_WINDOWS.md).

## Endless and replayability (Phase 5D-2)

Choose **Endless Siege** from the main menu for persistent in-run defenses,
rotating Hunters and Reaper milestones. Cleared waves pause the economy: prepare,
choose one aid, continue, suspend at a saved checkpoint or safely end the run.
Resume restores the last cleared-wave checkpoint; spent permanent items stay
spent. Starting a campaign requires explicitly ending/forfeiting a suspended run.

**Challenge · Practice · Cosmetics** opens normalized shareable Challenge Codes,
a dedicated real-combat training room with temporary resources, and four earned
visual appearances. Code results are local/self-reported; share the code and
copyable result summary with a friend. Practice never consumes saved inventory
or awards progression, and supplements the original first-time tutorial.

Campaign Victory spins now guarantee Epic+ by eight dry draws and Legendary by
40, with actual conditional odds and saved progress shown. A compact optional
defeat page reports real events and available-item tips. See the
[Endless and replayability report](docs/PHASE_5D2_ENDLESS_REPLAYABILITY_REPORT.md)
for natural Needle/Arc10 saves, scaling, reward caps, screenshots, reproducibility
and Windows verification limits.

## Hunter strategy and premium UI (Phase 5D-1)

New matches show a stable Hunter archetype in preparation: the heavy Crusher,
isolation-seeking Stalker or fast, fragile Ravager. Room plaques explain real
tradeoffs in door durability, bed income and Dynamo output. Optional contracts
add a one-time RM Cash bonus per stage/difficulty/objective; standard rewards
continue. The first-time tutorial stays unchanged.

At Needle/Arc Level4, choose one specialization to buy Level5, then upgrade to10.
Precision trades range/rate for strong hits; Suppression retains coverage and a
bounded slow. Arc Focus trades rate for damage; Storm trades hit strength for
range and fast projectiles. Fees/discounts use actual paid ledgers and50% sales.

Action emblems, locally licensed Gothic headings, dimensional button states,
illustrated Common supplies and distinct difficulty cards extend the existing
haunted interface. See the [premium UI and strategy report](docs/PHASE_5D1_PREMIUM_UI_STRATEGY_REPORT.md)
for controls, costs, tests, before/after images, diagnostic balance and Windows
verification limits.

## Gothic industrial presentation (Phase 5C-3)

Menus and HUD now share layered weathered metal and glass materials, with a
haunted facade, clearer action hierarchy and separate Gold/Electricity readouts.
All five maps retain their layouts while gaining authored floor detail and local
props. Actual Hunter motion drives facing and anticipation; real combat leaves
bounded match-local scars. Threat pacing and camera-aware positional audio use
actual events. Reduced Effects remains available in Settings.

See the [visual overhaul report](docs/PHASE_5C3_VISUAL_OVERHAUL_REPORT.md) for
paired before/after screenshots, automated and rendered checks, software-renderer
measurements and remaining art limitations. Native Windows play and subjective
visual/audio quality remain unverified.

## Haunted worlds and prestige defenses (Phase 5C-2)

The five existing maps now have animated exterior scenery, noncombat ambient
creatures, controlled storms and separate ambience. Genuine breaches/deaths add
Hunter/Reaper laughter, survivor scream/collapse/aftermath and actual team counts.
Reduced Effects simplifies ornament while keeping combat readable.

Needle and Arc turrets can reach Level 10; utilities remain at four. Prestige
upgrades require higher bed/door levels and substantial Gold/Electricity.
Coupons and sales use actual paid investments. See the
[haunted world report](docs/PHASE_5C2_HAUNTED_WORLD_REPORT.md) for tuning,
earned-resource reachability, test evidence and Windows limitations.

## Opening, practice and RM Cash shop (Phase 5C-1)

Every fresh desktop launch opens with a 15-second animated chase and a short
welcome/story card. Click or press Space, Enter or Escape to skip. New players
complete a guided practice using real controls; returning saves with recorded
progress continue to the menu. Replay Tutorial is available there.

Legitimate results now award persistent **RM Cash**, a separate in-game currency.
The Common shop sells Repair Kit (18 RM), Gold Supply Crate (16), Emergency
Battery (16) and Hunter Radar (12), using the existing inventory. Saved purchases
and rewards prevent duplicate grants; practice awards no permanent resources.
See the [onboarding and shop report](docs/PHASE_5C1_ONBOARDING_SHOP_REPORT.md).

## Rank perks, achievements and stage choices (Phase 5B-3)

Seven permanent perks retain the six existing options and add Mythic's Reaper
Slayer. Master unlocks a second permanent perk slot; consumables retain two
separate slots. Twelve persistent achievements offer visible, one-time XP/item
claims. First stage clears offer a saved choice of door durability, starting
Gold or a temporary turret bonus for the intended next stage. Unresolved offers
are preserved, and replaying stages cannot stack additional offers.
See the [progression rewards report](docs/PHASE_5B3_REWARDS_REPORT.md).

## Legendary items (Phase 5B-2B)

The inventory now contains 20 functional items. Time Freeze stops Hunter actions
while economy continues; Reaper Seal counters a real boss special; automatic
Guardian Heart intercepts one lethal door hit; Cursed Fortune grants 500 Gold
with 20 seconds of stronger Hunter pressure. Equip up to two item types; only
one successful Legendary activation is allowed per match, including Heart.
Legendary odds are 4% for Victory and 1% for qualifying Consolation spins
(1% / 0.25% for each Legendary). Exact odds, quantities and saved rewards remain
visible. Original icons, cues and brief effects respect Reduced Effects.
See the [Legendary report](docs/PHASE_5B2B_LEGENDARY_REPORT.md) for rules,
verification and native Windows limitations. Earlier phase sections below
record their original distributions; the current table is in that report.

## Advanced Rare and Epic items (Phase 5B-2A)

The same inventory now supports16functional items. Eight new choices add door mitigation, automatic rescue, bounded turret burn, bonus bed income, a one-purchase40%building coupon, a navigable decoy, selected-teammate repair and temporary targeting smoke. Coupon refunds use actual discounted gold/electricity paid. Settings includes saved Reduced Effects, and floating item numbers are spaced above particles. Spin odds now include Epic: Victory40/40/20%Common/Rare/Epic, Consolation80/16/4%; quantities remain up to4/1. See [advanced item report](docs/PHASE_5B2A_ITEM_REPORT.md).

## Consumable items and Lucky Spin (Phase 5B-1)

Eligible results now save a reward before its Lucky Spin animation: Victory up to4of one type, qualifying Consolation1. View exact odds in the spin, skip/reload safely, inspect persistent inventory and choose two consumable types separately from your permanent perk. Keys1/2 or hotbar clicks activate items; only a successful saved activation spends stock. Eight functional items cover repair, Gold, Electricity, radar, shield, overdrive, frost and traps. Meaningful defeat requirements and economy limits are documented in the [item report](docs/PHASE_5B1_ITEM_REPORT.md). Windows manual verification remains pending.

## Mythic progression (Phase 5A)

Bronze → Silver → Gold → Platinum → Diamond → Master → **Mythic** extends the existing profile. Mythic requires8,000XP, stage5 cleared, three Long Night/Hell victories and three Reaper defeats. Existing XP, six perks, loadouts, settings and campaign records survive migration. Ranks shows saved records and promotion requirements; results explain stage/Reaper/difficulty XP and animate promotions. New difficulty/Reaper records begin with this update because older saves did not store those totals. Loss XP is limited to1per30occupied seconds (cap30), with no difficulty bonus. See [rank report](docs/PHASE_5A_RANK_REPORT.md) for exact rules, migration tests and Windows checks.

## Grim Reaper boss (Phase 4B)

Later stages now include a once-only, vulnerable Reaper transformation with no HP refill: Normal stages3–5 after90 active seconds, Long Night/Hell stages2–5 after80, at≤55% HP (or210 active seconds regardless of HP). Stage preparation shows the rule. The hooded/scythe boss has telegraphed Scythe Strike, Soul Siege and Shadow Surge, original animation and a crossfading boss score. Repair through Surge's2.5-second turret silence; existing shots and neighboring defenses still work. Introductory stages, saves and the building/refund economy remain intact. See [boss report and Windows checklist](docs/PHASE_4B_BOSS_REPORT.md).

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

## Difficulty and hunter pressure

Normal keeps the forgiving original tuning. Long Night now uses stronger siege
decisions and faster escalation. Hell adds more frequent telegraphed heavy strikes
and stronger sustained pressure. The first 45 active seconds protect setup;
repairs return to full strength after the hunter leaves. Difficulty stays separate
from stages and saved perks. [Balance evidence](docs/PHASE_4A_BALANCE_REPORT.md).

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
