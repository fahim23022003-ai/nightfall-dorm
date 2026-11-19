# Stalker Level 1 modeled turnaround

This authored Blender study uses the supplied Stalker artwork to guide the thin leaning figure, hair that covers one eye, dark torn gown and long reaching hands. The rear and flanks are original interpretations. The four renders share one dimensional mesh, camera scale, elevation and lighting.

The editable Blender file is under `source/`. It contains shaped anatomy, independent hair curves, woven dress surfaces, and four orthographic cameras. This study has a single posed anatomy. Its image sockets support a separate 2.5D animation pipeline. Character skin weights, articulated 3D hair and cloth animation, and evolved forms are pending.

The four rendered views and their metadata are in `source/turnaround/`. Godot skips the source directory during asset import. The sculpt remains a review candidate while the facial treatment, hair, and fabric joins are refined.

## Rebuild

Fetch the pinned [MakeHuman neutral base mesh](https://raw.githubusercontent.com/makehumancommunity/makehuman/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/data/3dobjs/base.obj) and pass its local path to Blender 4.3 or newer. The script checks its SHA-256 before use.

```sh
blender --background --factory-startup --python-exit-code 1 \
  -P tools/visual_rebirth/stalker_sculpt/author_stalker.py -- \
  /path/to/base.obj /path/to/output --samples 64
```

The model is normalized to one common ground point and rendered as four 512×512 orthographic RGBA PNGs. The JSON uses top-left normalized UV coordinates for sockets and half-open pixel bounds at alpha ≥20%. Camera names describe position relative to the actor. For example, the camera at world −X observes a right-facing profile in the resulting image.

## Source

The neutral anatomy and cornea topology derive from the CC0 1.0 Universal MakeHuman base OBJ by Data Collection AB, Joel Palmius, and Jonas Hauquier. The rebuild script does not import MakeHuman program logic. Pose, styling, clothing, hair, materials, and lighting were authored for Nightfall Dorm. [Pinned MakeHuman license](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/LICENSE.md)
