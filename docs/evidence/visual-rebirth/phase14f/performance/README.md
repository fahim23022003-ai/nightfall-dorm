# Phase 14F direction-switch performance

The checkpoint is `0fce84063ab94d7bf36efea1165670f57425e8da`. The same prepared 720p fixture starts a Legacy Endless match at seed 67, purchases 16 occupied slots and advances a Level 10 Stalker around a validated walkable loop three times. The harness disables the automatic game process and uses the live Hunter movement primitive and presentation updates at the same 1/24-second staging step. Its repeated path and sampled model hash must match across presets and sources. The actual frame durations are wall-clock measurements.

Each trace warms up at the initial position for 30 rendered frames. The turn window covers the first three frames of each route leg. The separate texture-switch sample counts frames where the drawn Stalker texture changes. The first pass may include a texture’s first appearance, while passes two and three repeat the same route. The capture saves a PNG after timing to avoid including readback or PNG compression in the trace. The `initial-baseline` directory preserves the early checkpoint traces.

The matched pass used the frozen Stalker source at `2542e931af9fd533a749b760d86eb2759788aaa7` and ran final Standard, checkpoint Standard, checkpoint Low, then final Low. Each case passed 216 checks, had 348 timed frames and displayed five textures, with 29 actual texture switches. All routes and model hashes matched. Mesh identity was read after each frame timer ended. Both presets used 30 distinct mesh instances at the checkpoint and one after the change. Godot's render-memory estimate stayed near 148.58 MB.

| Preset | Median before → after | p95 before → after | Turn-window p95 before → after | Texture-switch p95 before → after |
| --- | ---: | ---: | ---: | ---: |
| Standard | 42.08 → 43.59 ms | 55.12 → 55.65 ms | 58.32 → 55.65 ms | 72.46 → 55.65 ms |
| Low | 40.00 → 40.36 ms | 48.02 → 50.74 ms | 47.75 → 55.18 ms | 48.40 → 58.25 ms |

The Standard texture-switch tail improved in this sample. The Low tail increased in the paired sample, and the initial Low checkpoint had an all-frame p95 of 66.84 ms. The software timing shows substantial run-to-run variation. The mesh instance result directly verifies lower geometry churn.

Godot 4.6.3 Compatibility used Mesa OpenGL 4.5 and llvmpipe on Linux with an Xorg dummy display and AMD EPYC 9V74 host. The numbers describe software-rendered timing on this host. Native Windows and Intel UHD timing remain open.

To collect a case on a graphical display, use a fresh profile and run:

```sh
export NIGHTFALL_VISUAL_REBIRTH=1
export XDG_DATA_HOME="$(mktemp -d)"
godot --path . --resolution 1280x720 --position 0,0 --audio-driver Dummy --disable-vsync \
  -s tools/visual_rebirth/measure_directional_frames.gd -- /tmp/nightfall-turn-standard medium
```

Use a fresh profile, `low` and a different absolute output directory for Low. To measure the checkpoint, import a `git archive` of the checkpoint into a separate directory. Point `--path` at that directory and use an absolute script path to ensure both builds run the same harness. The summary script takes the four frame traces in checkpoint Standard, checkpoint Low, final Standard, final Low order, followed by the output JSON path.
