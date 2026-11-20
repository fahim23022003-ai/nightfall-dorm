# Phase 14F directional art

This batch adds 108 separately illustrated sprites across 25 ordinary Hunter states and both Grim Reaper forms. Every sheet used the existing same-level oblique or Reaper body as its identity reference. The sprite bank supplies front, left, rear and right. The original obliques are retained on the southwest heading. Left and right are separately illustrated profiles.

Each sheet was reviewed for true rear geometry, profile orientation, complete limbs where visible, stable silhouette and clear gutters. The Crusher L10 source put the two profiles in swapped cells, so the packer maps the actual visible orientations. Ravager L7 uses the clear gutter from its source on the upper row. Ravager keeps the same 208-texel crouched body height as its obliques. The other added bodies use 256 texels. All share the existing 260-texel floor anchor. The ordinary rigs use hand, head and upper-body marks for each view. Marks on occluded limbs guide the projected deformation within visible cloth or body pixels.

- [All 24 ordinary anchor states at gameplay sprite scale](ordinary-anchor-art.png)
- [Stalker levels 1–10 at gameplay sprite scale](stalker-all-levels-art.png)
- [Both Reaper bodies at gameplay sprite scale](reaper-art.png)
- [108 sprite hashes and packing checks](asset-checks.txt)

These image plates compare packed art at runtime scale. The full gameplay captures and animation evidence are in the [Hunter evidence](../hunters/) directory. Fine cloth folds, strand positions and contact placements can vary across authored views. Motion uses 2D deformation.

The exact accepted sources are the PNG sheets in this directory. Reproduce this batch from the repository root and verify imported geometry with:

```sh
python tools/visual_rebirth/prepare_hunter_turnarounds.py
godot --headless --editor --import --path . --quit
NIGHTFALL_VISUAL_REBIRTH=1 godot --headless --path . --script tools/visual_rebirth/verify_hunter_directions.gd -- --require-complete
```

The headless verifier checks all 60 ordinary states and both Reaper forms. It checks imports, cardinal routing, canvas dimensions and the original oblique paths, then samples signed triangle area across the authored rig poses. [Geometry receipt](geometry-check.log) Area continuity is a mesh check. Use the Godot sequences to review movement, silhouettes and appearance through turns.
