# Phantom Witch intermediate directions

Six ordinary evolution states gained independent full-body directional raster art. These states retain their existing oblique sprites and use the production Witch mesh. The four new panels in each source sheet are in front, left, rear and right order. The front panels include some gaze and shoulder asymmetry to retain the character's gesture. Genuine rear costume construction and hair occlusion are visible in the bottom-left panels.

| Level | Carried over from the existing level art | Source |
| --- | --- | --- |
| L2 | Low collar, loose windblown curls and torn mourning lace | [L2 source](witch-l02-source.png) |
| L3 | Tall scalloped collar, upturned curls and visible shins | [L3 source](witch-l03-source.png) |
| L5 | Long asymmetric shoulder cape and slanted hair fan | [L5 source](witch-l05-source.png) |
| L6 | Curled wisps and a narrow winding ribbon sleeve | [L6 source](witch-l06-source.png) |
| L8 | Broad hair loop and two long, separate fabric streamers | [L8 source](witch-l08-source.png) |
| L9 | High burst of wisps, layered cape shoulders and pointed hem | [L9 source](witch-l09-source.png) |

Each source used the exact matching in-game `level_XX_oblique.png` as the visual reference for an ImageGen turnaround. The accepted art uses separate painted profiles and rear views. The evident facing and costume details were reviewed at sheet size before packing. Small stylized variations in folds, reach and hair follow the switch between directional poses.

Repack with `python tools/visual_rebirth/prepare_witch_progression_directions.py` from the project root. The helper records the floor anchor for each panel and uses the shared turntable packer. All destinations use the evolved Witch canvas of 328 × 264 with the existing floor pivot and 104-pixel game height.

Import through Godot and run `NIGHTFALL_VISUAL_REBIRTH=1 godot --headless --path . --script tools/visual_rebirth/verify_witch_progression_directions.gd`. In the graphical version, supply an absolute output path after `--` to save the 1280 × 720 plate drawn by the production Witch canvas renderer. The standalone plate illustrates imported art at game scale. The separate Hunter captures illustrate actual game encounters.

Godot validated all 30 textures for the six levels, including the six preserved obliques. The verifier checked heading selection, 328 × 264 texture dimensions, duplicate rasters and mirrored profile equality. [Game-scale Godot plate](witch-intermediate-godot-720.png) · [Headless results](import-verification.log) · [Graphical results](render-verification.log)
