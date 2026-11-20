# Survivor Rebirth rendering measurements

Each workload sampled 150 frames after warmup at 1280×720 in
Godot 4.6.3, Linux X11 and Mesa llvmpipe GL Compatibility. Samples
measure wall time through the update and native raster frame. The
lobby workload advances the normal offline readiness UI. The combat
workload measures an active Campaign siege in a 24-building room with
the exact Stalker L1 atlas, paid shots and real door strikes.

| Workload | Graphics | Median ms | p95 ms | Median draw calls |
| --- | --- | ---: | ---: | ---: |
| Lobby | Standard | 30.83 | 37.38 | 78 |
| Lobby | Low | 36.22 | 42.19 | 78 |
| Active combat | Standard | 58.35 | 81.01 | 384 |
| Active combat | Low | 51.58 | 70.56 | 379 |

These are single runs for each configuration. The lobby draws the same
bounded elements under both presets. The ordering of the two lobby
timings should be interpreted with the run-to-run variation of a software
renderer. Native Windows and Intel UHD remain unmeasured.
[Active combat still](active-combat-720.png) · [Lobby samples](lobby-medium.json) · [Combat samples](combat-medium.json)

Use the preview flags and an isolated profile in graphical Godot,
then run `tools/nightmare_maps/measure_nightmare_lobby.gd` with an
absolute output directory and `medium` or `low`. For combat use
`tools/nightmare_maps/measure_living_nightmare.gd` with the same
arguments and `stalker` at the end.
