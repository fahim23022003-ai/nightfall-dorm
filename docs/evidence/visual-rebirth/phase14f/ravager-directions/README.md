# Ravager intermediate directions

Levels 2, 3, 5, 6, 8 and 9 gained 24 independently illustrated directional assets. All six existing obliques remain available. Each source sheet uses the exact same-level oblique as reference and carries its weight distribution, hair, costume damage and crouch through a front, separate side profiles, and a rear with the face deliberately occluded.

| Level | Character details kept | Source |
| --- | --- | --- |
| L2 | Wrapped reach, torn knee and offset shoulders | [L2 sheet](ravager-l02-source.png) |
| L3 | Higher chest with one hand planted and the other over the knee | [L3 sheet](ravager-l03-source.png) |
| L5 | Four-point contact, long bare fingers, shredded cape | [L5 sheet](ravager-l05-source.png) |
| L6 | Large bare reach and a hole over the forward shoulder | [L6 sheet](ravager-l06-source.png) |
| L8 | Long wrapped sleeve and diagonal shredded cloak | [L8 sheet](ravager-l08-source.png) |
| L9 | Broad crouch, bare sinewy arms and stretched fingers | [L9 sheet](ravager-l09-source.png) |

The production turntable packer keeps the 328 × 264 canvas and (164, 260) floor pivot. Visible body height is 208 source pixels for five levels. Level 8 uses 204 pixels to keep the widest profiles and fingers inside the same canvas. Asset orientation and form were visually checked at sheet scale. Coordinates for 96 pose marks attach deformation to visible painted anatomy and clothing. For occluded rear hands, the mark follows the visible sleeve or shoulder.

Run `python tools/visual_rebirth/prepare_ravager_progression_directions.py` from the project root to repack. After Godot imports, run `NIGHTFALL_VISUAL_REBIRTH=1 godot --headless --path . --script tools/visual_rebirth/verify_hunter_directions.gd` to check direction routing and pose mesh orientation.

For the graphical comparison, run Godot on an active display with the preview environment variable, `--script tools/visual_rebirth/capture_ravager_progression_directions.gd` and `-- /absolute/path/to/output.png`. The plate shows imported art with the production mesh in a standalone canvas. The Hunter clips show motion in combat.

[Pose marks](pose-landmarks.json) · [Game-scale production-renderer plate](ravager-intermediate-godot-720.png) · [Renderer log](render-verification.log) · [Ravager-scoped mesh verifier result](mesh-verification.log)
