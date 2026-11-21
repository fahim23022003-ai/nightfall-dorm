# Phase 20 Player-First verification

The Windows preview defaults to Low at 960×540 and uses a separate test profile.
The prior Performance Preview remains available. Native Windows execution and
Intel UHD performance remain untested.

The preview has its own profile. Both the Phase 20 and Performance launchers
start at 960×540. The Windows ZIP passed archive CRC, executable checksum,
embedded resource, map-mode and Story lobby checks.
[Package receipt and SHA-256](windows-package.json)

## Godot evidence

- [Needle combat video](needle-combat.mp4) and [shot trace](needle-trace.json). This
  10-second silent capture has 240 Godot frames at normal simulation speed.
  Projectile 1 was visible in flight for nine frames and removed 9 HP. The
  impact record changed Hunter HP from 4738 to 4729 and the displayed number was 9.
- [Dynamo and Cancel](tutorial-dynamo.png) and [tutorial complete](tutorial-complete.png).
  Both Low and Standard walkthroughs passed 46 checks with actual input.
- [Armor, siege income and repair](door-survival.png), [pausing Help](help.png)
  and [danger map](danger-map.png).
- [Story victory](victory.png), [match timeline](timeline.png) and [Story
  defeat](defeat.png). The controlled victory fixture uses a real purchased
  Needle and sets the Hunter to 1 HP before its final projectile. The defeat
  journey completed twice and credited 7 RM Cash per loss, then verified a
  Shop purchase and carried the equipped item into the next lobby.

## Linux software-rendered timing

Godot 4.6.3 Compatibility on Mesa llvmpipe. Each matched run used the same
seed, room, camera, quality, paid machines and deterministic 24 Hz model
step. Timings are real elapsed frame draw and game processing on this host.
Adaptive trimming was disabled in the fixed-quality samples. The mixed layout
fired five shots for 140 actual Hunter HP loss in each run.

| Seven-machine fixture | Median, before → after | p95, before → after | Draws, before → after |
| --- | ---: | ---: | ---: |
| Low 960×540 | 29.39 → 28.92 ms | 41.34 → 38.91 ms | 306 → 306 |
| Standard 1280×720 | 58.41 → 58.44 ms | 75.53 → 68.16 ms | 557 → 556 |

The separately measured owner-playable Performance release at Low 960×540
recorded 30.34 ms median, 39.99 ms p95 and 48.77 ms p99 in the same
seven-machine workload. The cached muzzle and impact drawing changes preserve
model projectile events. Render cost dominates this software-rendered test.
Dense-case timings vary. The seven-machine mixed results show a modest gain
in p95 and do not establish a frame rate on a Windows laptop.

The pure-Needle fixture measured 0, 1, 5, 10 and 17 paid machines. A placement
scan found 17 legal footprints of the tested size in that room, so the 24,
40 and 60 requests produced no separate denser layout. Some turrets in the
larger layouts were out of range. The receipt records shot count, damage,
draws, memory and p99 separately. [Raw performance data](performance.json)

| Low Needle workload | Frame p95, before → after | Frame p99, before → after | Launch-frame p95, before → after |
| --- | ---: | ---: | ---: |
| Empty room | 30.24 → 33.37 ms | 33.92 → 43.24 ms | — |
| 1 Needle | 31.66 → 26.51 ms | 38.23 → 29.30 ms | 29.19 → 25.95 ms |
| 5 Needles | 34.73 → 33.23 ms | 38.44 → 34.99 ms | 37.39 → 32.26 ms |
| 10 Needles | 43.81 → 39.16 ms | 47.35 → 42.14 ms | 43.60 → 36.77 ms |
| 17 Needles | 50.07 → 44.25 ms | 53.72 → 53.42 ms | 46.07 → 42.66 ms |

Each launch-frame result includes six samples. In the earlier repeat, some
small and dense fixtures had worse p95, and the fixed-quality empty-room
run also regressed. Under the 17-machine load the game update median was
2.59 → 2.45 ms with 325 draw calls in both arms. The candidate recorded
147.3 MiB static allocation and 102.3 MiB reported render memory there.

## Matched rule validation

| Defense policy | Fallback wins | Continuous-only prototype | Phase 20 with both repair actions |
| --- | ---: | ---: | ---: |
| Balanced defense | 20/30 | 11/30 | 20/30 |
| Needle-first defense | 20/30 | 11/30 | 24/30 |
| Passive | 3/30 | 3/30 | 3/30 |

Every arm ran to a legitimate terminal outcome in all 90 tests across the
ten V2 map families and three difficulties. The previous scripted repair
policy repeatedly spent on instant heals at low door HP. Replacing its choice
with the 60-second cooldown alone reduced its counterplay, so the final Door
inspector keeps paid instant repair when the continuous channel is inactive.
These are simulation outcomes. The final matrix exercises the instant repair
path and the earlier arm and UI checks exercise the continuous one.
[Simulation and input receipts](verification.json)

Targeted checks covered Armor, its physical and magical interaction, exact
Bed Gold, payment, timed healing, cooldown and broken doors, Help freeze,
adaptive protection and free camera. Regression suites passed for projectile
logic, weapon feedback, Hunter contact, Story lobby and progression, Full
Room Grid saves, procedural persistence, Close Quarters, Endless and standard
gameplay. The Windows pack was inspected and run as an embedded pack under
Linux Godot. This confirms resources and Story startup.

## Selected ideas and limits

- Shipped lightweight features include the danger map, defeat analysis, upgrade
  comparisons, teammate SOS, risk forecasts, recent-hit history, timed
  evolution warning, smart alerts, adaptive effects, match timeline and damage
  guide. History is match-local and records contacts rather than every movement.
- Hunter personalities use archetype-specific seeded revisit weights only.
  The emergency Ward reuses the existing paid ability. Room identity uses saved
  presets. Chapter trophies use earned completion. The victory beat uses the
  existing death animation and honors reduced motion.
- The protected construction path remains. Structural demolition, gameplay
  synergies and random gameplay incidents are withheld pending collision,
  balance and performance verification. Native Windows and larger dense rooms
  remain open performance gates.

[Playtest controls and save scope](../../PLAYER_FIRST.md)
