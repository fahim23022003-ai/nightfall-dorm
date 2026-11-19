# Stalker evolution art

Levels 2–10 have individual oblique 2D illustrations generated from the existing Level 1 interpretation and the first three-anchor evolution sheet. The second Level 4 source supplies the selected Awakened pose with the extended leftward arm, lifted cloth and clearly separated hands. Levels 2–3 expose more arm, calf and turned fabric. Level 5 has an outward burial-cloth strip. Levels 6–8 fold the body forward to distinguish the diagonal train, extended hand and lifted hair mantle. Level 9 turns back toward upright, and Level 10 has a narrow, veiled upright body and two elongated outward arms.

Run `python tools/visual_rebirth/prepare_stalker_evolution.py` from the repository root with ImageMagick 7, Pillow and NumPy. The four source sheets produce nine 328×264 sprites with a common (164, 260) pivot and a 256-pixel subject height. The existing Level 1 texture remains separate. The nine adjacent floor-aligned masks differ by 25.6%, 25.7%, 40.3%, 41.3%, 37.9%, 36.9%, 40.1%, 51.8% and 38.8% at alpha ≥128, measured as symmetric difference divided by union. [Art gallery](stalker-evolution-gallery.png)

Each evolved art state has one gameplay oblique source. The gallery shows packed PNGs at 104 px and enlarged. It does not use the Godot scene or establish additional directional art or skeletal animation.
