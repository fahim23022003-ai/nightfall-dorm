# Game design

## Loop and scope

Nightfall Dorm is a single-player fixed-map 2D dormitory tower-defense game. Six rooms flank a shared corridor. During the configurable 30-second preparation period a player walks into a vacant room, claims it, and sleeps. Sleeping locks the door and produces gold. Five autonomous residents occupy other rooms and independently invest their own income in defenses. The hunter arrives, chooses occupied rooms, travels through the corridor, attacks closed doors, breaches destroyed doors, and eliminates exposed residents. Kill it for victory; the player's death is defeat. If the player dies in the same simulation step that a teammate kills the hunter, defeat takes precedence.

The fixed overview camera intentionally exposes all rooms and the corridor. The root window explicitly scales a 1280×800 canvas and keeps its aspect ratio, with a 960×600 minimum window. Room identity, bed, door, six numbered build tiles, hunter state, door health, gold and electricity remain visible. Dark blue architecture, cyan residents/defenses, amber economy and coral hunter create a coherent original palette. Original synthesized sounds indicate upgrades, attacks and turret fire.

## Rules and configurable balance

`Catalog` is the shared balance source. Beds have five levels and generate 2/4/8/15/26 gold per second before dream amplifier bonuses. Doors have five durability levels: 150/300/600/1100/1800 HP. Beds and doors limit how far they can outpace each other's progression, and advanced levels spend electricity separately from gold. Manual repair heals 70 intact-door HP for 12 gold. Exact current costs and configurable hunter growth values are in Catalog, not claimed as reference-game numbers.

Six functional building types fill six valid tiles per room: Needle turret, Arc turret (advanced defense), Dynamo (electricity), Repair station (door healing), Dream amplifier (percentage bed income), Target relay (turret damage). Buildings upgrade to level four; turret level increases both damage and attack frequency. The Arc turret needs bed level two. Damage, ranges, rates, prices and colors are catalog data. Buildings cannot overlap or occupy tiles outside the resident's own sleeping room. Rejected purchases do not deduct resources.

The hunter uses DORMANT → SEEK → MOVE → ATTACK → BREACH → EXIT and DEAD states. It selects living occupied rooms by distance and heavily weighted door strength, making neglected defenses attractive, travels via the shared corridor, respects intact closed doors, and retargets after 24 seconds when a door still needs more than two hits, excluding the previous blocked room when another target exists. Its level grows every 45 seconds after arrival. Turrets deal actual ranged damage with visible attack traces and stop when the hunter dies. A player who avoids sleeping is pursued through room doorways and the shared corridor after a further grace period, preventing indefinite safe inactivity.

Bots have guard, engineer, economist, gunner and balanced profiles configured in Catalog.AI_PROFILES (priorities, investment goals and decision interval). They reserve funds for progression after establishing a turret and generator, reach bed/door level three, then establish repair infrastructure and follow their configured profile goals. Emergency repairs trigger below 25% door HP, preventing routine repairs from consuming every coin needed for an upgrade. They place six distinct buildings and upgrade them as income permits. They claim available rooms and visibly approach their beds before sleeping; their strategy and purchases are real simulation state. They cannot claim a room containing the awake player.

## Architecture

RefCounted model objects separate simulation from rendering: MatchModel coordinates RoomState, HunterState, BotAI and Catalog. UI actions invoke the same public purchase/upgrade APIs exercised by tests. Signals provide interaction feedback. Game renders original local procedural art and uses Godot's canvas stretch with a fixed overview Camera2D. GameInterface builds native controls and renders a functional main menu, help, settings, in-match HUD and result screens. Fixed substeps keep frame delays bounded. No fragile scene-tree absolute paths or network assets are required.

## Outcomes and extensibility

Both outcomes include time, hunter level, player-only shots, player-only damage and earned gold, with restart/menu actions. Restart resets all model match state and retains volume preferences. Balance intentionally supports short matches; harder long-run pacing, animated survivor room entry, touch controls and Windows export validation remain future work. See QA and limitation documents for verified acceptance and remaining constraints.

## Autonomous audit improvements

Current original balance starts the hunter at 5000 HP and 22 damage, adding 10 damage each level. This replaces an initial 900-HP configuration that let passive players win too frequently before electricity progression mattered. Retargeting now excludes the previously blocked room when another occupied target exists. No exact commercial-game pacing is claimed; final broad-matrix measurements belong to QA. Rejected purchases explain the exact missing resource or prerequisite. Building hover text exposes damage, range, attack interval or production effects. Paused/finished matches reject transactions; eliminated residents cannot upgrade or repair. Player movement uses bounded substeps to prevent wall tunneling on frame stalls.

Continuous turret, hunter and bot action cooldowns preserve fractional elapsed time rather than resetting the entire interval after each action. Idle cooldown debt is bounded to the current simulation step, preventing a burst of saved attacks when a target returns. Damage statistics count health actually removed, including a clamped final hit.
