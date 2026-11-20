# Procedural map QA

The separate geometry suite passed **34,770 checks** across **80 maps**, with 16 seeds per theme. It checked exact seeded geometry after JSON save and restore, disjoint room surfaces, all five shapes, all four door orientations and the four cardinal Halls. The largest floor rotated among at least five different room numbers per theme. This measure tracks available floor area. The match simulations below test combat outcomes. [Geometry log](geometry.log)

The integration suite passed **495 checks** across **15 generated maps**. The Hunter reached every door and Hall in the sample. Every map offered at least one distinct seeded alternative route. Residents could approach every bed through its door, and the closed-room tests blocked paths inside. Paid machine footprints fit irregular floors, and rejected placements left the wallet intact. A staged wounded Hunter traveled to the West Haunted Hall, recovered 18% of the HP maximum at channel start, and resumed combat. It was disrupted by ordinary damage on a second attempt, which exhausted the attempt budget. The current profile API loaded generated geometry and the recovery budget from disk with opt-in disabled. The earned legacy checkpoint kept its fixed map. Damage at the existing Reaper thresholds triggered one transformation, phase two and one Crimson Execution. [Integration log](runtime.log)

## Earned Campaign simulations

Each seeded map, difficulty and selected room ran under all three automated policies. Players used ordinary income, purchases and repairs. All five NPC teammates claimed and occupied rooms. Across **45 runs**, the passive policy lost all 15. The balanced policy won five Standard, three Hard and two Hell cases. The Needle-first strategy won four Standard, two Hard and three Hell cases. Each policy faced the same five cases per difficulty. In one Hell layout, the Needle-first policy won where the balanced policy lost. All cases settled with legal movement, valid wallets and recovery within budget. The matches included 22 successful Hall visits. [Passive and balanced results](procedural-matches-final.json) · [Needle-first results](procedural-matches-needles.json)

## 1280×720 performance

Each run used the same 16 paid buildings in a generated U-shaped Cursed Mansion room and the same gameplay state. Godot advanced presentation updates over 120 rendered frames after 24 warmup frames per scene. Values are median / p95 wall-clock frame times in milliseconds.

| Scene | Standard, final repeat | Low, final repeat |
| --- | ---: | ---: |
| Irregular room with planning grid | 47.47 / 75.64 | 33.16 / 39.83 |
| Full map overview | 41.77 / 52.34 | 32.22 / 39.55 |

The compatibility renderer ran under Linux Xorg with Mesa llvmpipe. The benchmark held gameplay state fixed. Native Windows, Intel UHD and active-combat frame times remain unmeasured. The first final run gave Standard 55.50 / 87.47 ms on the grid and 40.35 / 54.14 ms in overview. Low measured 38.71 / 48.66 ms on the grid and 33.68 / 43.51 ms in overview. The host's CPU throttling counters advanced during the repeated Standard sample. The earlier QA pass gave 40.91 / 50.56 and 39.77 / 50.20 ms on Standard, and 39.18 / 56.90 and 36.53 / 44.61 ms on Low. All samples used matching game-state and geometry hashes. These timings show host variation across runs. [Final repeat](performance/final-repeat/) · [Other final sample](performance/final-first/) · [Earlier Standard](performance/medium.json) · [Earlier Low](performance/low.json)

Legacy regression runs covered map geometry and integration, full-room grid geometry, transactions and save migration, scene smoke and core. [Engine logs](regressions/)

## Reproduce

```sh
export NIGHTFALL_PROCEDURAL_MAPS=1
export NIGHTFALL_FULL_ROOM_GRID=1
godot --headless --script tests/nightmare_maps_geometry.gd
godot --headless --script tests/nightmare_maps_runtime.gd
godot --headless --script tools/nightmare_maps/check_nightmare_matches.gd -- /tmp/nightmare-matches.json
godot --headless --script tools/nightmare_maps/check_nightmare_matches.gd -- /tmp/nightmare-needle.json needle
```

Run display timings serially with `NIGHTFALL_VISUAL_REBIRTH=1`. Use a fresh profile for each run and select `medium` for Standard or `low` for Low.

```sh
XDG_DATA_HOME="$(mktemp -d)" NIGHTFALL_VISUAL_REBIRTH=1 godot --resolution 1280x720 \
  --audio-driver Dummy --disable-vsync --script tools/nightmare_maps/measure_nightmare_maps.gd \
  -- /tmp/nightmare-standard medium
```
