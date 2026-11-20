# Phase 14E room validation

The fixture starts an isolated Legacy Endless game at seed 67. The existing capture harness pays for full room capacity, all 15 building families at Level 10 and a duplicate Level 1 Needle. Screenshots show Godot’s production renderer and UI. Frame timing freezes gameplay and advances presentation, with 30 warm-up frames and 240 measured frames at 1280×720. Separate captures exercise 1920×1080.

The checkpoint is `deda9449ed107fd1637a309dd7f7fb7636606041`. All three timing cases had 174 passing checks and the same sampled model hash. The 720p inspector comparison uses the same selected Level 10 Needle. The Low input capture sends actual click events to all 16 slots with Reduced Motion, Reduced Flashes and Reduced Effects enabled. The settings evidence invokes the real setting picker’s selected signal.

These are single Linux software-rendered samples, using Godot Compatibility and llvmpipe. Frame pacing and memory values apply to this host and fixture. The preview-off comparison uses the same stills fixture at both resolutions. It records the largest RGB channel delta at each pixel.

Run the following with an available graphical display, absolute output paths and a fresh profile.

```sh
export NIGHTFALL_VISUAL_REBIRTH=1
export XDG_DATA_HOME="$(mktemp -d)"
godot --path . --audio-driver Dummy --disable-vsync -s tools/visual_rebirth/capture_dense_presets.gd -- /tmp/nightfall-standard medium
godot --path . --audio-driver Dummy --disable-vsync -s tools/visual_rebirth/capture_dense_presets.gd -- /tmp/nightfall-low low
godot --path . --audio-driver Dummy --disable-vsync -s tools/visual_rebirth/capture_dense_inspector.gd -- /tmp/nightfall-inspector
godot --path . --audio-driver Dummy --disable-vsync -s tools/visual_rebirth/capture_dense_input.gd -- /tmp/nightfall-low-clicks
godot --path . --audio-driver Dummy --disable-vsync -s tools/visual_rebirth/capture_quality_settings.gd -- /tmp/nightfall-quality-menu
```

For the checkpoint comparison, extract its Git tree with `git archive`, import it with Godot, and use the same capture scripts with the archived project as `--path`. Set `NIGHTFALL_VISUAL_REBIRTH=0` and use `tools/capture_visual_rebirth.gd -- /tmp/nightfall-fallback stills` for the fallback pair. Keep timing runs serial and use a fresh profile for each.
