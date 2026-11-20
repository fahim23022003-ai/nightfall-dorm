# 720p dense combat on Linux

Godot 4.6.3 GL Compatibility with Mesa llvmpipe rendered 150 measured
frames per run after a 24-frame warm-up in the exact seeded V2 room with
24 buildings. The harness times the model, game presentation and rendered
frame. It also measures scene setup through the harness's first settled
frame and the Godot engine-reported static allocation. These allocations
do not include the whole process or the launcher's download size.

| Encounter and setting | Frame median ms | Frame p95 ms | Setup s | Static MiB | Strikes |
| --- | ---: | ---: | ---: | ---: | ---: |
| [Reaper Low preview](reaper-low-1/benchmark.json) | 106.31 | 175.39 | 2.07 | 141.8 | 1 |
| [Reaper Standard preview](reaper-medium-1/benchmark.json) | 70.51 | 98.82 | 2.36 | 141.8 | 1 |
| [Stalker Low fallback](stalker-low-0/benchmark.json) | 37.32 | 46.52 | 2.09 | 139.9 | 7 |
| [Stalker Low preview](stalker-low-1/benchmark.json) | 40.13 | 58.88 | 1.95 | 141.9 | 7 |
| [Stalker Standard fallback](stalker-medium-0/benchmark.json) | 37.96 | 46.55 | 2.27 | 139.9 | 7 |
| [Stalker Standard preview](stalker-medium-1/benchmark.json) | 45.84 | 71.53 | 2.02 | 141.9 | 7 |

The Stalker arms matched initial, warm-up and final gameplay hashes and
each landed seven strikes while the player fired six shots. The Reaper
runs matched each other and exercised a genuine transformation and scythe
strike. The fixture began the measured Reaper run during a staged gap
between Wrath abilities so the window included physical contact.
Its two graphics timings varied materially. They are a small
software-renderer sample from a cloud CPU shared with capture tasks and
do not support a hardware performance claim.

The opt-in Stalker samples took longer than fallback on this renderer.
Native Windows and Intel UHD performance remain unmeasured.

[Timing harness](../../../../tools/nightmare_maps/measure_living_nightmare.gd)
